// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Health Insight';

  @override
  String get navHome => 'Home';

  @override
  String get navHistory => 'History';

  @override
  String get navSettings => 'Settings';

  @override
  String get homeTitle => 'Health Insight';

  @override
  String get homeDisclaimer => 'For health reference only, not a diagnosis';

  @override
  String get homePrimaryAction => 'Take Photo';

  @override
  String get homePrimaryDesc => 'Capture a clear image in good light';

  @override
  String get homeSecondaryAction => 'Choose from Gallery';

  @override
  String get homeSecondaryDesc => 'Select a recent photo to analyze';

  @override
  String get homeHeroSubtitle => 'Log health insights with a quick photo';

  @override
  String get homeStepsTitle => 'Steps';

  @override
  String get homeStep1 => '1 Choose image';

  @override
  String get homeStep2 => '2 Start analysis';

  @override
  String get homeStep3 => '3 Save to history';

  @override
  String get homeTipsTitle => 'Photo tips';

  @override
  String get homeTip1 => 'Good lighting and clear image';

  @override
  String get homeTip2 => 'Include only the target area';

  @override
  String get homeTip3 => 'Avoid faces or private information';

  @override
  String get homeRecentTitle => 'Latest record';

  @override
  String get homeRecentEmptyTitle => 'No records yet';

  @override
  String get homeRecentEmptyMessage =>
      'Complete one analysis and it will appear here.';

  @override
  String get homeRecentAction => 'Start analysis';

  @override
  String get homeRecentCardTitle => 'Latest analysis';

  @override
  String get homeRecentView => 'View';

  @override
  String get historyTitle => 'History';

  @override
  String get historyDeleted => 'Record deleted';

  @override
  String get historyDeletedUndo => 'Record deleted. You can undo.';

  @override
  String get historyUndoAction => 'Undo';

  @override
  String get historyDeleteTitle => 'Delete record';

  @override
  String get historyDeleteMessage => 'Delete this record?';

  @override
  String get historyDeleteAction => 'Delete';

  @override
  String get historyEmptyTitle => 'No history yet';

  @override
  String get historyEmptyMessage =>
      'After your first analysis, it will be saved here.';

  @override
  String get historyEmptyAction => 'Start analysis';

  @override
  String historyItemMeta(Object type, Object score) {
    return 'Bristol Type $type · Score $score/100';
  }

  @override
  String get previewTitle => 'Preview';

  @override
  String get previewNoImageTitle => 'No image selected';

  @override
  String get previewNoImageMessage => 'Please select an image before analysis.';

  @override
  String get previewBackHome => 'Back to Home';

  @override
  String get previewValidating => 'Checking image quality...';

  @override
  String get previewWeakPass => 'Image content uncertain, for reference only.';

  @override
  String get previewPass => 'Image looks good. You can start analysis.';

  @override
  String get previewRechoose => 'Choose again';

  @override
  String get previewStartAnalyze => 'Start analysis';

  @override
  String get previewHint =>
      'We will generate insights and suggestions from this image.';

  @override
  String get previewCanceled => 'Cancelled';

  @override
  String get previewPickFailed => 'Failed to get image, please try again';

  @override
  String get previewNotTargetTitle => 'Target not detected';

  @override
  String get previewNotTargetMessage =>
      'This image doesn\'t look like stool. Please retake or select a clearer image (only the target area).';

  @override
  String get previewBlurryMessage =>
      'Image is not clear. Please retake or choose a clearer one.';

  @override
  String get previewUnknownMessage =>
      'Image cannot be recognized. Please try another.';

  @override
  String get previewRetake => 'Retake';

  @override
  String get previewSelectAgain => 'Select again';

  @override
  String get previewCancel => 'Cancel';

  @override
  String get placeholderImage => 'Placeholder';

  @override
  String get permissionCameraTitle => 'Camera permission needed';

  @override
  String get permissionGalleryTitle => 'Gallery permission needed';

  @override
  String get permissionCameraMessage =>
      'Please enable camera permission in system settings.';

  @override
  String get permissionGalleryMessage =>
      'Please enable photo permission in system settings.';

  @override
  String get permissionGoSettings => 'Open Settings';

  @override
  String get resultTitle => 'Result';

  @override
  String get resultErrorTitle => 'Analysis incomplete';

  @override
  String get resultErrorMessage => 'An error occurred. Please try again.';

  @override
  String get resultRetry => 'Retry analysis';

  @override
  String get resultSummaryTitle => 'Summary';

  @override
  String get resultRiskTitle => 'Risk level';

  @override
  String get resultRiskNote =>
      'For health records only, not a medical diagnosis';

  @override
  String get resultKeyTraitsTitle => 'Key traits';

  @override
  String get resultBristolTitle => 'Bristol Type';

  @override
  String resultBristolValue(Object type) {
    return 'Type $type';
  }

  @override
  String get resultColorCaption => 'Color may be diet-related';

  @override
  String get resultTextureCaption => 'Texture may reflect digestion';

  @override
  String get resultQualityTitle => 'Image quality';

  @override
  String resultQualityScore(Object score) {
    return 'Score $score/100';
  }

  @override
  String get resultQualityGood => 'Good quality';

  @override
  String get resultQualityMore => 'See more';

  @override
  String get resultQualityLess => 'Collapse';

  @override
  String get resultActionsTitle => 'Next steps';

  @override
  String get resultActionsEmpty => 'No suggestions';

  @override
  String get resultMetricBristol => 'Bristol';

  @override
  String get resultMetricColor => 'Color';

  @override
  String get resultMetricTexture => 'Texture';

  @override
  String get resultMetricScore => 'Score';

  @override
  String get resultWarningTitle => 'Needs attention';

  @override
  String get resultWarningHint => 'Please seek care if you feel unwell.';

  @override
  String get resultSeekCareTitle => 'When to seek care';

  @override
  String get resultSeekCareEmpty => 'No items';

  @override
  String get resultDisclaimersDefault =>
      'This result is for health logging and self-observation, not a professional diagnosis.';

  @override
  String get resultExtraTitle => 'Additional info';

  @override
  String get resultOdorLabel => 'Odor';

  @override
  String get resultPainLabel => 'Pain/Strain';

  @override
  String get resultDietLabel => 'Diet keywords';

  @override
  String get resultDietHint => 'e.g. spicy, takeout, dairy';

  @override
  String get resultSubmitUpdate => 'Submit and update';

  @override
  String get resultUpdated => 'Updated';

  @override
  String get resultReanalyze => 'Re-analyze';

  @override
  String get resultSave => 'Save record';

  @override
  String get resultSaved => 'Saved';

  @override
  String get resultSaveFailed => 'Save failed, try again';

  @override
  String get resultAdviceUpdated => 'Suggestions updated';

  @override
  String get resultAdviceUpdateFailed => 'Failed to update suggestions';

  @override
  String get resultSummaryExpand => 'Expand';

  @override
  String get resultSummaryCollapse => 'Collapse';

  @override
  String resultAnalysisTimeLabel(Object time) {
    return 'Analysis time: $time';
  }

  @override
  String get resultHealthReference => 'For health reference only';

  @override
  String get riskLowDesc => 'Stable overall. Keep observing and logging.';

  @override
  String get riskMediumDesc =>
      'Some signals need attention. Observe with diet/symptoms.';

  @override
  String get riskHighDesc =>
      'Stronger warning. Seek care if discomfort occurs.';

  @override
  String get bristolHintDry => 'Dry/hard';

  @override
  String get bristolHintIdeal => 'Ideal';

  @override
  String get bristolHintLoose => 'Loose';

  @override
  String get riskLowLabel => 'Low';

  @override
  String get riskMediumLabel => 'Medium';

  @override
  String get riskHighLabel => 'High';

  @override
  String get colorBrown => 'Brown';

  @override
  String get colorYellow => 'Yellow';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorBlack => 'Black';

  @override
  String get colorRed => 'Red';

  @override
  String get colorPale => 'Pale';

  @override
  String get colorMixed => 'Mixed';

  @override
  String get colorUnknown => 'Unknown';

  @override
  String get textureWatery => 'Watery';

  @override
  String get textureMushy => 'Mushy';

  @override
  String get textureNormal => 'Normal';

  @override
  String get textureHard => 'Hard';

  @override
  String get textureOily => 'Oily';

  @override
  String get textureFoamy => 'Foamy';

  @override
  String get textureUnknown => 'Unknown';

  @override
  String get odorNone => 'None';

  @override
  String get odorLight => 'Light';

  @override
  String get odorStrong => 'Strong';

  @override
  String get odorSour => 'Sour';

  @override
  String get odorRotten => 'Rotten';

  @override
  String get odorOther => 'Other';

  @override
  String get detailTitle => 'Record details';

  @override
  String get detailRiskSummaryTitle => 'Risk overview';

  @override
  String get detailResultTitle => 'Result';

  @override
  String get detailSuspiciousSignalsTitle => 'Suspicious signals';

  @override
  String get detailQualityTitle => 'Quality';

  @override
  String get detailInputsTitle => 'Additional info';

  @override
  String get detailAdviceTitle => 'Advice';

  @override
  String get detailActionsTitle => 'Next 48h';

  @override
  String get detailCareTitle => 'Seek care';

  @override
  String get detailEmptyValue => 'None';

  @override
  String get detailYes => 'Yes';

  @override
  String get detailNo => 'No';

  @override
  String get detailNotProvided => 'Not provided';

  @override
  String get detailDisclaimerLabel => 'Disclaimer: ';

  @override
  String get detailLoadFailedTitle => 'Unable to load';

  @override
  String get detailLoadFailedMessage =>
      'This record may be missing or corrupted.';

  @override
  String get detailBackHistory => 'Back to history';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsDataTitle => 'Data';

  @override
  String get settingsDataLine1 => 'Records are stored locally (offline)';

  @override
  String get settingsDataLine2 => 'You can export or clear at any time';

  @override
  String get settingsDataMgmtTitle => 'Data management';

  @override
  String get settingsExportTitle => 'Export records';

  @override
  String get settingsExportSubtitle => 'Export as JSON for backup';

  @override
  String get settingsClearTitle => 'Clear history';

  @override
  String get settingsClearSubtitle => 'Cannot be undone';

  @override
  String get settingsClearDialogTitle => 'Confirm clear?';

  @override
  String get settingsClearDialogMessage =>
      'Clearing will remove all history and cannot be undone.';

  @override
  String get settingsClearConfirm => 'Clear';

  @override
  String get settingsCleared => 'Cleared';

  @override
  String get settingsExporting => 'Exporting...';

  @override
  String get settingsExportEmpty => 'No records to export';

  @override
  String settingsExportSuccess(Object count) {
    return 'Exported (total $count)';
  }

  @override
  String get settingsExportFailed => 'Export failed, please try again';

  @override
  String get settingsAboutTitle => 'About';

  @override
  String get settingsVersionTitle => 'Version';

  @override
  String settingsSchemaVersion(Object version) {
    return 'Schema v$version';
  }

  @override
  String get settingsUsageTitle => 'How to use';

  @override
  String get settingsUsageSubtitle => 'Quick start guide';

  @override
  String get settingsUsageDialogTitle => 'How to use';

  @override
  String get settingsUsageDialogMessage =>
      'Take or select a photo, analyze, and save to history.';

  @override
  String get settingsUsageDialogClose => 'Got it';

  @override
  String get settingsPrivacyTitle => 'Privacy & data';

  @override
  String get settingsPrivacySubtitle => 'Stored locally, clear anytime';

  @override
  String get settingsAnalyzerModeTitle => 'Analysis mode';

  @override
  String get settingsAnalyzerLocalTitle => 'Local (Mock)';

  @override
  String get settingsAnalyzerLocalSubtitle => 'Stable and offline';

  @override
  String get settingsAnalyzerRemoteTitle => 'Cloud (Remote)';

  @override
  String get settingsAnalyzerRemoteSubtitle =>
      'Requires backend, may be unavailable';

  @override
  String get settingsDisclaimer =>
      'This app is for health logging only, not a medical diagnosis. Seek care if you feel unwell.';

  @override
  String get privacyTitle => 'Privacy & data';

  @override
  String get privacyLocalTitle => 'Local storage';

  @override
  String get privacyLocalLine1 => 'Analysis and records stay on this device.';

  @override
  String get privacyLocalLine2 => 'You can clear all records anytime.';

  @override
  String get privacyExportTitle => 'Export';

  @override
  String get privacyExportLine1 =>
      'Export copies records as JSON to clipboard.';

  @override
  String get privacyExportLine2 => 'Avoid including personal sensitive info.';

  @override
  String get privacyClearTitle => 'Clear now';

  @override
  String get privacyClearLine => 'Delete all local records instantly.';

  @override
  String get privacyClearButton => 'Clear all data';

  @override
  String get privacyCleared => 'Cleared';

  @override
  String get exportSuccess => 'Exported';

  @override
  String get exportFailed => 'Export failed, please try again';

  @override
  String get exportPdfTooltip => 'Export PDF';

  @override
  String get pdfTitle => 'Health Insight Record';

  @override
  String get pdfRecordTimeLabel => 'Record time';

  @override
  String get pdfSummaryTitle => 'Summary';

  @override
  String get pdfRiskLabel => 'Risk level';

  @override
  String get pdfKeyTraitsTitle => 'Key traits';

  @override
  String get pdfQualityTitle => 'Image quality';

  @override
  String get pdfQualityScoreLabel => 'Score';

  @override
  String get pdfQualityGood => 'Good quality';

  @override
  String get pdfActionsTitle => 'Next steps (48h)';

  @override
  String get pdfActionsEmpty => 'No suggestions';

  @override
  String get pdfSeekCareTitle => 'When to seek care';

  @override
  String get pdfSeekCareEmpty => 'None';

  @override
  String get pdfDisclaimerDefault =>
      'This result is for health logging and self-observation, not a professional diagnosis.';

  @override
  String get pdfRiskLow => 'Low';

  @override
  String get pdfRiskMedium => 'Medium';

  @override
  String get pdfRiskHigh => 'High';

  @override
  String get pdfColorLabel => 'Color';

  @override
  String get pdfTextureLabel => 'Texture';

  @override
  String get pdfBristolLabel => 'Bristol Type';

  @override
  String get loadingTitle => 'Analyzing';

  @override
  String get loadingStepQuality => 'Check image quality';

  @override
  String get loadingStepFeatures => 'Identify key traits';

  @override
  String get loadingStepAdvice => 'Generate suggestions';

  @override
  String get remoteUnavailable => 'Cloud service unavailable, please try later';
}
