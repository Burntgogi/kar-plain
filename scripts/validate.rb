#!/usr/bin/env ruby

require "json"
require "pathname"
require "yaml"

ROOT = Pathname.new(__dir__).join("..").realpath
PLUGINS_ROOT = ROOT.join("plugins")
LOCAL_SKILLS_ROOTS = [ROOT.join(".claude/skills"), ROOT.join(".agents/skills")].freeze
READMES = %w[README.md README.en.md].freeze
STANDARD_FIELDS = %w[name description license compatibility metadata allowed-tools].freeze
CLAUDE_FIELDS = %w[argument-hint disable-model-invocation].freeze
NONPORTABLE_BODY_PATTERNS = {
  "AskUserQuestion" => /\bAskUserQuestion\b/,
  "Claude shell prefix" => /`! (?:argocd|aws|gh|git|kubectl)\b/,
  "Claude ToolSearch" => /\bToolSearch\b/,
  "generated Claude MCP name" => /mcp__claude_ai_/,
  "Claude-only session link" => /Claude-Session/
}.freeze

errors = []

def load_json(path, errors)
  JSON.parse(path.read)
rescue JSON::ParserError => e
  errors << "#{path.relative_path_from(ROOT)}: invalid JSON (#{e.message})"
  {}
end

def load_yaml(path, errors)
  YAML.safe_load(path.read, permitted_classes: [], aliases: false) || {}
rescue Psych::Exception => e
  errors << "#{path.relative_path_from(ROOT)}: invalid YAML (#{e.message})"
  {}
end

def frontmatter(path, errors)
  parts = path.read.split(/^---\s*$\n/, 3)
  unless parts.length == 3 && parts.first.empty?
    errors << "#{path.relative_path_from(ROOT)}: missing YAML frontmatter"
    return {}
  end

  YAML.safe_load(parts[1], permitted_classes: [], aliases: false) || {}
rescue Psych::Exception => e
  errors << "#{path.relative_path_from(ROOT)}: invalid frontmatter (#{e.message})"
  {}
end

marketplace = load_json(ROOT.join(".claude-plugin/marketplace.json"), errors)
marketplace_entries = marketplace["plugins"] || []

plugin_dirs = PLUGINS_ROOT.children.select(&:directory?).sort
plugin_manifests = {}

plugin_dirs.each do |plugin_dir|
  manifest_path = plugin_dir.join(".claude-plugin/plugin.json")
  unless manifest_path.file?
    errors << "#{plugin_dir.relative_path_from(ROOT)}: missing .claude-plugin/plugin.json"
    next
  end

  manifest = load_json(manifest_path, errors)
  plugin_name = plugin_dir.basename.to_s
  errors << "#{plugin_name}: manifest name must match the plugin directory" unless manifest["name"] == plugin_name
  plugin_manifests[plugin_name] = manifest

  entry = marketplace_entries.find { |candidate| candidate["name"] == plugin_name }
  if entry.nil?
    errors << "#{plugin_name}: missing from the marketplace manifest"
  elsif entry["source"] != "./plugins/#{plugin_name}"
    errors << "#{plugin_name}: marketplace source must be ./plugins/#{plugin_name}"
  end
end

marketplace_entries.each do |entry|
  name = entry["name"].to_s
  errors << "marketplace plugin #{name}: no matching directory under plugins/" unless plugin_manifests.key?(name)
end

agents_path = ROOT.join("AGENTS.md")
unless agents_path.symlink? && agents_path.readlink.to_s == "CLAUDE.md"
  errors << "AGENTS.md must be a symbolic link to CLAUDE.md"
end

readmes = READMES.to_h { |name| [name, ROOT.join(name).read] }
skill_dirs_by_name = {}

plugin_dirs.each do |plugin_dir|
  plugin_name = plugin_dir.basename.to_s
  skills_root = plugin_dir.join("skills")
  unless skills_root.directory?
    errors << "#{plugin_name}: missing skills directory"
    next
  end

  skills_root.children.select(&:directory?).sort.each do |skill_dir|
    skill_path = skill_dir.join("SKILL.md")
    unless skill_path.file?
      errors << "#{skill_dir.relative_path_from(ROOT)}: missing SKILL.md"
      next
    end

    metadata = frontmatter(skill_path, errors)
    name = metadata["name"].to_s
    description = metadata["description"].to_s
    skill_dirs_by_name[name] = skill_dir unless name.empty?

    errors << "#{name}: directory name must match frontmatter name" unless name == skill_dir.basename.to_s
    errors << "#{name}: name must be kebab-case and at most 64 characters" unless name.match?(/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/) && name.length <= 64
    errors << "#{name}: description must be 1..1024 characters" unless description.length.between?(1, 1024)
    errors << "#{name}: description cannot contain angle brackets" if description.match?(/[<>]/)

    unknown = metadata.keys.map(&:to_s) - STANDARD_FIELDS - CLAUDE_FIELDS
    errors << "#{name}: unsupported frontmatter fields: #{unknown.join(", ")}" unless unknown.empty?

    openai_path = skill_dir.join("agents/openai.yaml")
    unless openai_path.file?
      errors << "#{name}: missing agents/openai.yaml"
      next
    end

    openai = load_yaml(openai_path, errors)
    interface = openai["interface"] || {}
    short_description = interface["short_description"].to_s
    default_prompt = interface["default_prompt"].to_s
    errors << "#{name}: interface.display_name is required" if interface["display_name"].to_s.empty?
    errors << "#{name}: short_description must be 25..64 characters" unless short_description.length.between?(25, 64)
    errors << "#{name}: default_prompt must mention $#{name}" unless default_prompt.include?("$#{name}")

    claude_user_only = metadata["disable-model-invocation"] == true
    codex_user_only = openai.dig("policy", "allow_implicit_invocation") == false
    unless claude_user_only == codex_user_only
      errors << "#{name}: Claude and Codex invocation policies are out of sync"
    end

    body = skill_path.read
    NONPORTABLE_BODY_PATTERNS.each do |label, pattern|
      errors << "#{name}: contains nonportable #{label}" if body.match?(pattern)
    end

    link = "plugins/#{plugin_name}/skills/#{name}/SKILL.md"
    readmes.each do |readme_name, text|
      errors << "#{name}: missing from #{readme_name}" unless text.include?(link)
    end
  end
end

LOCAL_SKILLS_ROOTS.each do |local_root|
  unless local_root.directory? && !local_root.symlink?
    errors << "#{local_root.relative_path_from(ROOT)}: must be a directory of per-skill symlinks"
    next
  end

  local_entries = local_root.children.sort
  local_names = local_entries.map { |entry| entry.basename.to_s }

  (skill_dirs_by_name.keys - local_names).each do |missing|
    errors << "#{local_root.relative_path_from(ROOT)}/#{missing}: missing local link to #{skill_dirs_by_name[missing].relative_path_from(ROOT)}"
  end

  local_entries.each do |entry|
    name = entry.basename.to_s
    canonical = skill_dirs_by_name[name]
    if canonical.nil?
      errors << "#{entry.relative_path_from(ROOT)}: stale local link with no canonical skill"
      next
    end

    unless entry.symlink?
      errors << "#{entry.relative_path_from(ROOT)}: must be a symlink to #{canonical.relative_path_from(ROOT)}"
      next
    end

    begin
      unless entry.realpath == canonical.realpath
        errors << "#{entry.relative_path_from(ROOT)}: must point to #{canonical.relative_path_from(ROOT)}"
      end
    rescue Errno::ENOENT
      errors << "#{entry.relative_path_from(ROOT)}: broken local skill link"
    end
  end
end

if errors.empty?
  versions = plugin_manifests.map { |name, manifest| "#{name} #{manifest["version"]}" }.join(", ")
  puts "Validation passed for #{skill_dirs_by_name.length} skills across #{plugin_manifests.length} plugins (#{versions})."
  exit 0
end

warn "Validation failed:"
errors.each { |error| warn "- #{error}" }
exit 1
