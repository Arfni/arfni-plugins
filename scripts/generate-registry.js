#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');
const { glob } = require('glob');

// Configuration
const PLUGINS_DIR = path.join(__dirname, '../plugins');
const REGISTRY_FILE = path.join(__dirname, '../registry/index.json');
const REPOSITORY_URL = 'https://github.com/Arfni/arfni-plugins';

// Category definitions
const CATEGORIES = {
  framework: {
    name: 'Framework Plugins',
    description: 'Build and containerize applications'
  },
  database: {
    name: 'Database Plugins',
    description: 'Persistent data storage solutions'
  },
  cache: {
    name: 'Cache Plugins',
    description: 'High-speed in-memory data stores'
  },
  message_queue: {
    name: 'Message Queue Plugins',
    description: 'Asynchronous messaging between services'
  },
  proxy: {
    name: 'Proxy Plugins',
    description: 'Reverse proxies and load balancers'
  },
  cicd: {
    name: 'CI/CD Plugins',
    description: 'Integrate deployment pipelines'
  },
  orchestration: {
    name: 'Orchestration Plugins',
    description: 'Deploy to different platforms'
  },
  infrastructure: {
    name: 'Infrastructure Plugins',
    description: 'Infrastructure as code and configuration management'
  }
};

// Validation mode
const VALIDATE_ONLY = process.argv.includes('--validate-only');

/**
 * Validate plugin.yaml structure
 */
function validatePluginManifest(manifest, filePath) {
  const errors = [];

  // Required fields
  const requiredFields = ['apiVersion', 'name', 'version', 'category', 'description', 'author'];
  for (const field of requiredFields) {
    if (!manifest[field]) {
      errors.push(`Missing required field: ${field}`);
    }
  }

  // Validate apiVersion
  if (manifest.apiVersion && !manifest.apiVersion.match(/^v\d+\.\d+$/)) {
    errors.push(`Invalid apiVersion format: ${manifest.apiVersion} (expected format: v0.1)`);
  }

  // Validate category
  if (manifest.category && !CATEGORIES[manifest.category]) {
    errors.push(`Invalid category: ${manifest.category}. Must be one of: ${Object.keys(CATEGORIES).join(', ')}`);
  }

  // Validate version format (semantic versioning)
  if (manifest.version && !manifest.version.match(/^\d+\.\d+\.\d+$/)) {
    errors.push(`Invalid version format: ${manifest.version} (expected format: 1.0.0)`);
  }

  // Validate provides structure
  if (manifest.provides) {
    if (!manifest.provides.frameworks && !manifest.provides.service_kinds) {
      errors.push('provides must contain either frameworks or service_kinds');
    }
  }

  if (errors.length > 0) {
    console.error(`\n❌ Validation failed for ${filePath}:`);
    errors.forEach(err => console.error(`   - ${err}`));
    return false;
  }

  console.log(`✅ ${manifest.name} - Valid`);
  return true;
}

/**
 * Scan and parse all plugin.yaml files
 */
async function scanPlugins() {
  console.log('🔍 Scanning for plugin.yaml files...\n');

  // Find all plugin.yaml files
  const pluginFiles = await glob('**/plugin.yaml', {
    cwd: PLUGINS_DIR,
    absolute: true,
    ignore: ['**/node_modules/**', '**/dist/**']
  });

  console.log(`Found ${pluginFiles.length} plugin(s)\n`);

  const plugins = [];
  let validCount = 0;
  let invalidCount = 0;

  for (const filePath of pluginFiles) {
    try {
      // Read and parse YAML
      const content = fs.readFileSync(filePath, 'utf8');
      const manifest = yaml.load(content);

      // Validate
      const isValid = validatePluginManifest(manifest, filePath);

      if (!isValid) {
        invalidCount++;
        if (VALIDATE_ONLY) continue;
      } else {
        validCount++;
      }

      // Calculate relative path from plugins directory
      const relativePath = path.relative(path.join(__dirname, '..'), path.dirname(filePath));
      const pluginPath = relativePath.replace(/\\/g, '/'); // Normalize to forward slashes

      // Extract category and name from path
      const pathParts = pluginPath.split('/');
      const categoryFromPath = pathParts[1]; // plugins/frameworks/django -> frameworks
      const nameFromPath = pathParts[2]; // plugins/frameworks/django -> django

      // Build registry entry
      const registryEntry = {
        // Core identification
        id: manifest.name,
        name: manifest.displayName || manifest.name.charAt(0).toUpperCase() + manifest.name.slice(1),
        category: manifest.category,
        version: manifest.version,

        // Display information
        description: manifest.description,
        author: manifest.author,
        homepage: manifest.homepage || `${REPOSITORY_URL}/tree/main/${pluginPath}`,
        license: manifest.license || 'MIT',

        // Repository information
        path: pluginPath,
        repository: {
          owner: 'Arfni',
          repo: 'arfni-plugins',
          branch: 'main'
        },

        // Plugin capabilities
        provides: manifest.provides || {
          frameworks: [],
          service_kinds: []
        },

        // Requirements
        requires: manifest.requires || {},

        // Discovery and metadata
        tags: manifest.tags || [],

        // Assets
        icon: manifest.icon || 'icon.png',

        // Statistics and status
        downloads: 0,
        stars: 0,
        verified: true,
        status: 'stable',
        last_updated: new Date().toISOString()
      };

      // Add optional documentation
      if (manifest.documentation) {
        registryEntry.documentation = manifest.documentation;
      }

      plugins.push(registryEntry);

    } catch (error) {
      console.error(`❌ Error processing ${filePath}:`, error.message);
      invalidCount++;
    }
  }

  console.log(`\n📊 Validation Summary:`);
  console.log(`   ✅ Valid: ${validCount}`);
  console.log(`   ❌ Invalid: ${invalidCount}`);

  if (VALIDATE_ONLY) {
    if (invalidCount > 0) {
      process.exit(1);
    }
    console.log('\n✅ All plugins are valid!');
    process.exit(0);
  }

  return plugins;
}

/**
 * Generate category statistics
 */
function generateCategoryStats(plugins) {
  const categories = {};

  // Initialize all categories with count 0
  for (const [key, value] of Object.entries(CATEGORIES)) {
    categories[key] = {
      ...value,
      count: 0
    };
  }

  // Count plugins per category
  for (const plugin of plugins) {
    if (categories[plugin.category]) {
      categories[plugin.category].count++;
    }
  }

  return categories;
}

/**
 * Generate registry index.json
 */
async function generateRegistry() {
  console.log('🚀 Generating plugin registry...\n');

  // Scan plugins
  const plugins = await scanPlugins();

  // Generate category stats
  const categories = generateCategoryStats(plugins);

  // Build registry structure
  const registry = {
    schema_version: '1.0.0',
    version: '1.0.0',
    last_updated: new Date().toISOString(),
    repository: REPOSITORY_URL,

    categories,

    plugins: plugins.sort((a, b) => a.name.localeCompare(b.name)),

    stats: {
      total_plugins: plugins.length,
      total_downloads: plugins.reduce((sum, p) => sum + p.downloads, 0),
      categories_count: Object.keys(CATEGORIES).length,
      last_sync: new Date().toISOString()
    }
  };

  // Ensure registry directory exists
  const registryDir = path.dirname(REGISTRY_FILE);
  if (!fs.existsSync(registryDir)) {
    fs.mkdirSync(registryDir, { recursive: true });
  }

  // Write registry file
  fs.writeFileSync(REGISTRY_FILE, JSON.stringify(registry, null, 2), 'utf8');

  console.log(`\n✅ Registry generated successfully!`);
  console.log(`   📄 File: ${REGISTRY_FILE}`);
  console.log(`   📦 Total plugins: ${plugins.length}`);
  console.log(`   📂 Categories: ${Object.keys(CATEGORIES).length}`);
  console.log(`\n📋 Plugins by category:`);

  for (const [key, value] of Object.entries(categories)) {
    if (value.count > 0) {
      console.log(`   - ${value.name}: ${value.count}`);
    }
  }

  return registry;
}

// Main execution
if (require.main === module) {
  generateRegistry()
    .then(() => {
      console.log('\n✨ Done!');
      process.exit(0);
    })
    .catch(error => {
      console.error('\n❌ Error generating registry:', error);
      process.exit(1);
    });
}

module.exports = { generateRegistry, scanPlugins, validatePluginManifest };
