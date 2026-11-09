#!/usr/bin/env python3
"""Generate a self-contained Xcode project for Physora.

The project uses Xcode 16+ synchronized folders for Swift sources and
resources, so new files are picked up automatically. The checked-in
`project.yml` remains the canonical XcodeGen spec for CI; this script is a
platform-independent fallback that creates an equivalent `.xcodeproj`
without requiring macOS or XcodeGen.
"""
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "Physora.xcodeproj"

IDS = {
    "project": "A10000000000000000000001",
    "main_group": "A10000000000000000000002",
    "products_group": "A10000000000000000000003",
    "support_group": "A10000000000000000000004",
    "app_sync": "A10000000000000000000005",
    "test_sync": "A10000000000000000000006",
    "app_target": "A10000000000000000000007",
    "test_target": "A10000000000000000000008",
    "app_product": "A10000000000000000000009",
    "test_product": "A1000000000000000000000A",
    "info_ref": "A1000000000000000000000B",
    "app_sources": "A1000000000000000000000C",
    "app_frameworks": "A1000000000000000000000D",
    "app_resources": "A1000000000000000000000E",
    "test_sources": "A1000000000000000000000F",
    "test_frameworks": "A10000000000000000000010",
    "test_resources": "A10000000000000000000011",
    "test_dependency": "A10000000000000000000012",
    "test_proxy": "A10000000000000000000013",
    "project_configs": "A10000000000000000000014",
    "app_configs": "A10000000000000000000015",
    "test_configs": "A10000000000000000000016",
    "project_debug": "A10000000000000000000017",
    "project_release": "A10000000000000000000018",
    "app_debug": "A10000000000000000000019",
    "app_release": "A1000000000000000000001A",
    "test_debug": "A1000000000000000000001B",
    "test_release": "A1000000000000000000001C",
}


def project_file() -> str:
    return f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 70;
	objects = {{

/* Begin PBXContainerItemProxy section */
		{IDS['test_proxy']} /* PBXContainerItemProxy */ = {{
			isa = PBXContainerItemProxy;
			containerPortal = {IDS['project']} /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = {IDS['app_target']};
			remoteInfo = Physora;
		}};
/* End PBXContainerItemProxy section */

/* Begin PBXFileReference section */
		{IDS['app_product']} /* Physora.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Physora.app; sourceTree = BUILT_PRODUCTS_DIR; }};
		{IDS['test_product']} /* PhysoraTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = PhysoraTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};
		{IDS['info_ref']} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; }};
/* End PBXFileReference section */

/* Begin PBXFileSystemSynchronizedRootGroup section */
		{IDS['app_sync']} /* Physora */ = {{isa = PBXFileSystemSynchronizedRootGroup; explicitFileTypes = {{}}; explicitFolders = (); path = Physora; sourceTree = "<group>"; }};
		{IDS['test_sync']} /* PhysoraTests */ = {{isa = PBXFileSystemSynchronizedRootGroup; explicitFileTypes = {{}}; explicitFolders = (); path = "Tests/PhysoraTests"; sourceTree = "<group>"; }};
/* End PBXFileSystemSynchronizedRootGroup section */

/* Begin PBXFrameworksBuildPhase section */
		{IDS['app_frameworks']} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{IDS['test_frameworks']} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		{IDS['main_group']} = {{
			isa = PBXGroup;
			children = (
				{IDS['app_sync']} /* Physora */,
				{IDS['test_sync']} /* PhysoraTests */,
				{IDS['support_group']} /* Support */,
				{IDS['products_group']} /* Products */,
			);
			sourceTree = "<group>";
		}};
		{IDS['products_group']} /* Products */ = {{
			isa = PBXGroup;
			children = (
				{IDS['app_product']} /* Physora.app */,
				{IDS['test_product']} /* PhysoraTests.xctest */,
			);
			name = Products;
			sourceTree = "<group>";
		}};
		{IDS['support_group']} /* Support */ = {{
			isa = PBXGroup;
			children = (
				{IDS['info_ref']} /* Info.plist */,
			);
			path = Support;
			sourceTree = "<group>";
		}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		{IDS['app_target']} /* Physora */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {IDS['app_configs']} /* Build configuration list for PBXNativeTarget "Physora" */;
			buildPhases = (
				{IDS['app_sources']} /* Sources */,
				{IDS['app_frameworks']} /* Frameworks */,
				{IDS['app_resources']} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			fileSystemSynchronizedGroups = (
				{IDS['app_sync']} /* Physora */,
			);
			name = Physora;
			packageProductDependencies = (
			);
			productName = Physora;
			productReference = {IDS['app_product']} /* Physora.app */;
			productType = "com.apple.product-type.application";
		}};
		{IDS['test_target']} /* PhysoraTests */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {IDS['test_configs']} /* Build configuration list for PBXNativeTarget "PhysoraTests" */;
			buildPhases = (
				{IDS['test_sources']} /* Sources */,
				{IDS['test_frameworks']} /* Frameworks */,
				{IDS['test_resources']} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
				{IDS['test_dependency']} /* PBXTargetDependency */,
			);
			fileSystemSynchronizedGroups = (
				{IDS['test_sync']} /* PhysoraTests */,
			);
			name = PhysoraTests;
			packageProductDependencies = (
			);
			productName = PhysoraTests;
			productReference = {IDS['test_product']} /* PhysoraTests.xctest */;
			productType = "com.apple.product-type.bundle.unit-test";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		{IDS['project']} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 2640;
				LastUpgradeCheck = 2640;
				TargetAttributes = {{
					{IDS['app_target']} = {{
						CreatedOnToolsVersion = 26.4;
					}};
					{IDS['test_target']} = {{
						CreatedOnToolsVersion = 26.4;
						TestTargetID = {IDS['app_target']};
					}};
				}};
			}};
			buildConfigurationList = {IDS['project_configs']} /* Build configuration list for PBXProject "Physora" */;
			compatibilityVersion = "Xcode 9.3";
			developmentRegion = ru;
			hasScannedForEncodings = 0;
			knownRegions = (
				ru,
				Base,
			);
			mainGroup = {IDS['main_group']};
			productRefGroup = {IDS['products_group']} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{IDS['app_target']} /* Physora */,
				{IDS['test_target']} /* PhysoraTests */,
			);
		}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		{IDS['app_resources']} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{IDS['test_resources']} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		{IDS['app_sources']} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{IDS['test_sources']} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXSourcesBuildPhase section */

/* Begin PBXTargetDependency section */
		{IDS['test_dependency']} /* PBXTargetDependency */ = {{
			isa = PBXTargetDependency;
			target = {IDS['app_target']} /* Physora */;
			targetProxy = {IDS['test_proxy']} /* PBXContainerItemProxy */;
		}};
/* End PBXTargetDependency section */

/* Begin XCBuildConfiguration section */
		{IDS['project_debug']} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_TESTABILITY = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 26.0;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
				SWIFT_STRICT_CONCURRENCY = complete;
				SWIFT_VERSION = 6.0;
			}};
			name = Debug;
		}};
		{IDS['project_release']} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 26.0;
				MTL_ENABLE_DEBUG_INFO = NO;
				MTL_FAST_MATH = YES;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
				SWIFT_STRICT_CONCURRENCY = complete;
				SWIFT_VERSION = 6.0;
				VALIDATE_PRODUCT = YES;
			}};
			name = Release;
		}};
		{IDS['app_debug']} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				ENABLE_PREVIEWS = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = Support/Info.plist;
				IPHONEOS_DEPLOYMENT_TARGET = 26.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.pepelru.physora;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_STRICT_CONCURRENCY = complete;
				SWIFT_VERSION = 6.0;
				TARGETED_DEVICE_FAMILY = 1;
			}};
			name = Debug;
		}};
		{IDS['app_release']} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				ENABLE_PREVIEWS = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = Support/Info.plist;
				IPHONEOS_DEPLOYMENT_TARGET = 26.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.pepelru.physora;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_STRICT_CONCURRENCY = complete;
				SWIFT_VERSION = 6.0;
				TARGETED_DEVICE_FAMILY = 1;
			}};
			name = Release;
		}};
		{IDS['test_debug']} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				BUNDLE_LOADER = "$(TEST_HOST)";
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				GENERATE_INFOPLIST_FILE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 26.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
					"@loader_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.pepelru.physora.tests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_STRICT_CONCURRENCY = complete;
				SWIFT_VERSION = 6.0;
				TARGETED_DEVICE_FAMILY = 1;
				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/Physora.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Physora";
				TEST_TARGET_NAME = Physora;
			}};
			name = Debug;
		}};
		{IDS['test_release']} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				BUNDLE_LOADER = "$(TEST_HOST)";
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				GENERATE_INFOPLIST_FILE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 26.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
					"@loader_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.pepelru.physora.tests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_STRICT_CONCURRENCY = complete;
				SWIFT_VERSION = 6.0;
				TARGETED_DEVICE_FAMILY = 1;
				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/Physora.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Physora";
				TEST_TARGET_NAME = Physora;
			}};
			name = Release;
		}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		{IDS['project_configs']} /* Build configuration list for PBXProject "Physora" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{IDS['project_debug']} /* Debug */,
				{IDS['project_release']} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{IDS['app_configs']} /* Build configuration list for PBXNativeTarget "Physora" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{IDS['app_debug']} /* Debug */,
				{IDS['app_release']} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{IDS['test_configs']} /* Build configuration list for PBXNativeTarget "PhysoraTests" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{IDS['test_debug']} /* Debug */,
				{IDS['test_release']} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */
	}};
	rootObject = {IDS['project']} /* Project object */;
}}
"""


def scheme() -> str:
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "2640"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES"
      buildArchitectures = "Automatic">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{IDS['app_target']}"
               BuildableName = "Physora.app"
               BlueprintName = "Physora"
               ReferencedContainer = "container:Physora.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "NO"
            buildForProfiling = "NO"
            buildForArchiving = "NO"
            buildForAnalyzing = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{IDS['test_target']}"
               BuildableName = "PhysoraTests.xctest"
               BlueprintName = "PhysoraTests"
               ReferencedContainer = "container:Physora.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES"
      shouldAutocreateTestPlan = "YES">
      <Testables>
         <TestableReference
            skipped = "NO"
            parallelizable = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{IDS['test_target']}"
               BuildableName = "PhysoraTests.xctest"
               BlueprintName = "PhysoraTests"
               ReferencedContainer = "container:Physora.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{IDS['app_target']}"
            BuildableName = "Physora.app"
            BlueprintName = "Physora"
            ReferencedContainer = "container:Physora.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{IDS['app_target']}"
            BuildableName = "Physora.app"
            BlueprintName = "Physora"
            ReferencedContainer = "container:Physora.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""


def workspace() -> str:
    return """<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "self:">
   </FileRef>
</Workspace>
"""


def main() -> None:
    PROJECT.mkdir(parents=True, exist_ok=True)
    (PROJECT / "project.pbxproj").write_text(project_file(), encoding="utf-8", newline="\n")
    workspace_dir = PROJECT / "project.xcworkspace"
    workspace_dir.mkdir(parents=True, exist_ok=True)
    (workspace_dir / "contents.xcworkspacedata").write_text(workspace(), encoding="utf-8", newline="\n")
    schemes_dir = PROJECT / "xcshareddata" / "xcschemes"
    schemes_dir.mkdir(parents=True, exist_ok=True)
    (schemes_dir / "Physora.xcscheme").write_text(scheme(), encoding="utf-8", newline="\n")
    print(f"Generated {PROJECT}")


if __name__ == "__main__":
    main()
