"""Generate the dependency-free Xcode project deterministically."""
from pathlib import Path
import hashlib, json
root = Path(__file__).resolve().parents[2]
objects = {}
def ident(key): return hashlib.sha256(key.encode()).hexdigest()[:24].upper()
def add(key, body):
    i = ident(key); objects[i] = body; return i
def quote(s): return json.dumps(str(s))
def array(items): return '(' + ', '.join(items) + (',' if items else '') + ')'
sources = sorted(p.relative_to(root/'macos').as_posix() for folder in ['App','DesignSystem','Services','Features','ViewModels'] for p in (root/'macos'/folder).glob('*.swift'))
refs=[]; builds=[]
for source in sources:
    ref=add(source, f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {quote(source)}; sourceTree = "<group>";')
    refs.append(ref); builds.append(add('build:'+source, f'isa = PBXBuildFile; fileRef = {ref};'))
resources=[]
for name in ['Fonts','Branding']:
    ref=add(name,f'isa = PBXFileReference; lastKnownFileType = folder; path = Resources/{name}; sourceTree = "<group>";')
    refs.append(ref); resources.append(add('build:'+name,f'isa = PBXBuildFile; fileRef = {ref};'))
ref=add('Assets', 'isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Resources/Assets.xcassets; sourceTree = "<group>";')
refs.append(ref); resources.append(add('build:Assets',f'isa = PBXBuildFile; fileRef = {ref};'))
app=add('app','isa = PBXFileReference; explicitFileType = wrapper.application; path = "Endpoint Mapper.app"; sourceTree = BUILT_PRODUCTS_DIR;')
testprod=add('testprod','isa = PBXFileReference; explicitFileType = wrapper.cfbundle; path = EndpointMapperTests.xctest; sourceTree = BUILT_PRODUCTS_DIR;')
testref=add('testref','isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Tests/FoundationTests.swift; sourceTree = "<group>";')
refs.append(testref)
testbuild=add('testbuild',f'isa = PBXBuildFile; fileRef = {testref};')
products=add('products',f'isa = PBXGroup; name = Products; children = {array([app,testprod])}; sourceTree = "<group>";')
group=add('group',f'isa = PBXGroup; children = {array(refs+[products])}; sourceTree = "<group>";')
def phase(key,kind,files): return add(key,f'isa = {kind}; buildActionMask = 2147483647; files = {array(files)}; runOnlyForDeploymentPostprocessing = 0;')
src=phase('sources','PBXSourcesBuildPhase',builds)
res=phase('resources','PBXResourcesBuildPhase',resources)
fw=phase('frameworks','PBXFrameworksBuildPhase',[])
script='set -eu\nDEST="$TARGET_BUILD_DIR/$CONTENTS_FOLDER_PATH"\nmkdir -p "$DEST/Helpers" "$DEST/Resources/engine"\ncp "$SRCROOT/../.build/runtime/node" "$DEST/Helpers/node"\ncp "$SRCROOT/../.build/runtime/Node-LICENSE.txt" "$DEST/Resources/Node-LICENSE.txt"\nbash "$SRCROOT/../packaging/scripts/embed-engine.sh" "$DEST/Resources/engine"\ncodesign --force --sign - "$DEST/Helpers/node"\n'
helper=add('helper',f'isa = PBXShellScriptBuildPhase; buildActionMask = 2147483647; files = (); inputPaths = (); outputPaths = (); name = "Embed local engine"; alwaysOutOfDate = 1; shellPath = /bin/sh; shellScript = {quote(script)}; runOnlyForDeploymentPostprocessing = 0;')
def configs(key,settings):
    ids=[]
    for name in ['Debug','Release']:
        values=dict(settings)
        values['SWIFT_OPTIMIZATION_LEVEL']='-Onone' if name=='Debug' else '-O'
        ids.append(add(key+name, 'isa = XCBuildConfiguration; name = '+name+'; buildSettings = {'+' '.join(k+' = '+quote(v)+';' for k,v in values.items())+'};'))
    return add(key+'list',f'isa = XCConfigurationList; buildConfigurations = {array(ids)}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
common={'ARCHS':'$(NATIVE_ARCH_ACTUAL)','MACOSX_DEPLOYMENT_TARGET':'14.0','SDKROOT':'macosx','SWIFT_VERSION':'5.0','CLANG_ENABLE_MODULES':'YES','CODE_SIGN_IDENTITY':'-','CODE_SIGN_STYLE':'Manual','ENABLE_USER_SCRIPT_SANDBOXING':'NO'}
projectconfig=configs('projectconfig',common)
appconfig=configs('appconfig',{'PRODUCT_NAME':'Endpoint Mapper','PRODUCT_MODULE_NAME':'EndpointMapper','PRODUCT_BUNDLE_IDENTIFIER':'local.endpointmapper.app','GENERATE_INFOPLIST_FILE':'YES','INFOPLIST_KEY_CFBundleDisplayName':'Endpoint Mapper','INFOPLIST_KEY_LSApplicationCategoryType':'public.app-category.developer-tools','CURRENT_PROJECT_VERSION':'3','MARKETING_VERSION':'0.2.0','ASSETCATALOG_COMPILER_APPICON_NAME':'AppIcon','ENABLE_TESTABILITY':'YES','LD_RUNPATH_SEARCH_PATHS':'$(inherited) @executable_path/../Frameworks'})
target=add('target',f'isa = PBXNativeTarget; name = EndpointMapper; productName = "Endpoint Mapper"; productType = "com.apple.product-type.application"; productReference = {app}; buildConfigurationList = {appconfig}; buildPhases = {array([src,fw,res,helper])}; buildRules = (); dependencies = ();')
proxy=add('proxy',f'isa = PBXContainerItemProxy; containerPortal = {ident("project")}; proxyType = 1; remoteGlobalIDString = {target}; remoteInfo = EndpointMapper;')
dep=add('dep',f'isa = PBXTargetDependency; target = {target}; targetProxy = {proxy};')
testconfig=configs('testconfig',{'PRODUCT_NAME':'EndpointMapperTests','PRODUCT_BUNDLE_IDENTIFIER':'local.endpointmapper.tests','GENERATE_INFOPLIST_FILE':'YES','TEST_HOST':'$(BUILT_PRODUCTS_DIR)/Endpoint Mapper.app/Contents/MacOS/Endpoint Mapper','BUNDLE_LOADER':'$(TEST_HOST)','LD_RUNPATH_SEARCH_PATHS':'$(inherited) @loader_path/../Frameworks @executable_path/../Frameworks'})
sessionref=add('sessionref','isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Tests/SessionTests.swift; sourceTree = "<group>";')
sessionbuild=add('sessionbuild',f'isa = PBXBuildFile; fileRef = {sessionref};')
objects[group]=objects[group].replace(products,sessionref+', '+products)
ts=phase('testsources','PBXSourcesBuildPhase',[testbuild,sessionbuild]); tf=phase('testframeworks','PBXFrameworksBuildPhase',[])
targettest=add('targettest',f'isa = PBXNativeTarget; name = EndpointMapperTests; productName = EndpointMapperTests; productType = "com.apple.product-type.bundle.unit-test"; productReference = {testprod}; buildConfigurationList = {testconfig}; buildPhases = {array([ts,tf])}; buildRules = (); dependencies = {array([dep])};')
uiref=add('uiref','isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Tests/NavigationUITests.swift; sourceTree = "<group>";')
uibuild=add('uibuild',f'isa = PBXBuildFile; fileRef = {uiref};')
uiprod=add('uiprod','isa = PBXFileReference; explicitFileType = wrapper.cfbundle; path = EndpointMapperUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR;')
objects[group]=objects[group].replace(products, uiref+', '+products)
objects[products]=objects[products].replace(testprod,testprod+', '+uiprod)
uiconfig=configs('uiconfig',{'PRODUCT_NAME':'EndpointMapperUITests','PRODUCT_BUNDLE_IDENTIFIER':'local.endpointmapper.uitests','GENERATE_INFOPLIST_FILE':'YES','TEST_TARGET_NAME':'EndpointMapper','LD_RUNPATH_SEARCH_PATHS':'$(inherited) @loader_path/../Frameworks @executable_path/../Frameworks'})
uis=phase('uisources','PBXSourcesBuildPhase',[uibuild]); uif=phase('uiframeworks','PBXFrameworksBuildPhase',[])
uitarget=add('uitarget',f'isa = PBXNativeTarget; name = EndpointMapperUITests; productName = EndpointMapperUITests; productType = "com.apple.product-type.bundle.ui-testing"; productReference = {uiprod}; buildConfigurationList = {uiconfig}; buildPhases = {array([uis,uif])}; buildRules = (); dependencies = {array([dep])};')
project=add('project',f'isa = PBXProject; attributes = {{ LastUpgradeCheck = 2620; }}; buildConfigurationList = {projectconfig}; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; knownRegions = (en, Base); mainGroup = {group}; productRefGroup = {products}; projectDirPath = ""; projectRoot = ""; targets = {array([target,targettest,uitarget])};')
path=root/'macos/EndpointMapper.xcodeproj'; path.mkdir(exist_ok=True)
(path/'project.pbxproj').write_text('// !$*UTF8*$!\n{ archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n'+'\n'.join(i+' = { '+body+' };' for i,body in objects.items())+'\n}; rootObject = '+project+'; }\n')
scheme=path/'xcshareddata/xcschemes'; scheme.mkdir(parents=True,exist_ok=True)
def buildref(i,name): return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{i}" BuildableName="{name}" BlueprintName="{("EndpointMapper" if i==target else ("EndpointMapperTests" if i==targettest else "EndpointMapperUITests"))}" ReferencedContainer="container:EndpointMapper.xcodeproj"/>'
(scheme/'EndpointMapper.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2620" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{buildref(target,'Endpoint Mapper.app')}</BuildActionEntry></BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO">{buildref(targettest,'EndpointMapperTests.xctest')}</TestableReference><TestableReference skipped="NO">{buildref(uitarget,'EndpointMapperUITests.xctest')}</TestableReference></Testables></TestAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{buildref(target,'Endpoint Mapper.app')}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{buildref(target,'Endpoint Mapper.app')}</BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>''')
