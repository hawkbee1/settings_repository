/// dart_code_3D settings: theme mode and engine rules, persisted with
/// shared_preferences.
///
/// It also re-exports the rule definitions, so the app reads them without
/// depending on the engine.
library;

export 'package:code_analysis_engine/code_analysis_engine.dart'
    show
        AnalysisRules,
        BoolParameter,
        EnumParameter,
        EnumSetParameter,
        GlobListParameter,
        RuleCatalog,
        RuleGroup,
        RuleIds,
        RuleOption,
        RuleParameter,
        StringParameter;

export 'src/settings_repository.dart';
