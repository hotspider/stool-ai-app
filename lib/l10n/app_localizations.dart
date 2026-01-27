import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_th.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('id'),
    Locale('ja'),
    Locale('ko'),
    Locale('th'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Health Insight'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Health Insight'**
  String get homeTitle;

  /// No description provided for @homeDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'For health reference only, not a diagnosis'**
  String get homeDisclaimer;

  /// No description provided for @homePrimaryAction.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get homePrimaryAction;

  /// No description provided for @homePrimaryDesc.
  ///
  /// In en, this message translates to:
  /// **'Capture a clear image in good light'**
  String get homePrimaryDesc;

  /// No description provided for @homeSecondaryAction.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get homeSecondaryAction;

  /// No description provided for @homeSecondaryDesc.
  ///
  /// In en, this message translates to:
  /// **'Select a recent photo to analyze'**
  String get homeSecondaryDesc;

  /// No description provided for @homeHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log health insights with a quick photo'**
  String get homeHeroSubtitle;

  /// No description provided for @homeStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get homeStepsTitle;

  /// No description provided for @homeStep1.
  ///
  /// In en, this message translates to:
  /// **'1 Choose image'**
  String get homeStep1;

  /// No description provided for @homeStep2.
  ///
  /// In en, this message translates to:
  /// **'2 Start analysis'**
  String get homeStep2;

  /// No description provided for @homeStep3.
  ///
  /// In en, this message translates to:
  /// **'3 Save to history'**
  String get homeStep3;

  /// No description provided for @homeTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo tips'**
  String get homeTipsTitle;

  /// No description provided for @homeTip1.
  ///
  /// In en, this message translates to:
  /// **'Good lighting and clear image'**
  String get homeTip1;

  /// No description provided for @homeTip2.
  ///
  /// In en, this message translates to:
  /// **'Include only the target area'**
  String get homeTip2;

  /// No description provided for @homeTip3.
  ///
  /// In en, this message translates to:
  /// **'Avoid faces or private information'**
  String get homeTip3;

  /// No description provided for @homeRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'Latest record'**
  String get homeRecentTitle;

  /// No description provided for @homeRecentEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No records yet'**
  String get homeRecentEmptyTitle;

  /// No description provided for @homeRecentEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Complete one analysis and it will appear here.'**
  String get homeRecentEmptyMessage;

  /// No description provided for @homeRecentAction.
  ///
  /// In en, this message translates to:
  /// **'Start analysis'**
  String get homeRecentAction;

  /// No description provided for @homeRecentCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Latest analysis'**
  String get homeRecentCardTitle;

  /// No description provided for @homeRecentView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get homeRecentView;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historyDeleted.
  ///
  /// In en, this message translates to:
  /// **'Record deleted'**
  String get historyDeleted;

  /// No description provided for @historyDeletedUndo.
  ///
  /// In en, this message translates to:
  /// **'Record deleted. You can undo.'**
  String get historyDeletedUndo;

  /// No description provided for @historyUndoAction.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get historyUndoAction;

  /// No description provided for @historyDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete record'**
  String get historyDeleteTitle;

  /// No description provided for @historyDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete this record?'**
  String get historyDeleteMessage;

  /// No description provided for @historyDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get historyDeleteAction;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'After your first analysis, it will be saved here.'**
  String get historyEmptyMessage;

  /// No description provided for @historyEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Start analysis'**
  String get historyEmptyAction;

  /// No description provided for @historyItemMeta.
  ///
  /// In en, this message translates to:
  /// **'Bristol Type {type} · Score {score}/100'**
  String historyItemMeta(Object type, Object score);

  /// No description provided for @previewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewTitle;

  /// No description provided for @previewNoImageTitle.
  ///
  /// In en, this message translates to:
  /// **'No image selected'**
  String get previewNoImageTitle;

  /// No description provided for @previewNoImageMessage.
  ///
  /// In en, this message translates to:
  /// **'Please select an image before analysis.'**
  String get previewNoImageMessage;

  /// No description provided for @previewBackHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get previewBackHome;

  /// No description provided for @previewValidating.
  ///
  /// In en, this message translates to:
  /// **'Checking image quality...'**
  String get previewValidating;

  /// No description provided for @previewWeakPass.
  ///
  /// In en, this message translates to:
  /// **'Image content uncertain, for reference only.'**
  String get previewWeakPass;

  /// No description provided for @previewPass.
  ///
  /// In en, this message translates to:
  /// **'Image looks good. You can start analysis.'**
  String get previewPass;

  /// No description provided for @previewRechoose.
  ///
  /// In en, this message translates to:
  /// **'Choose again'**
  String get previewRechoose;

  /// No description provided for @previewStartAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Start analysis'**
  String get previewStartAnalyze;

  /// No description provided for @previewHint.
  ///
  /// In en, this message translates to:
  /// **'We will generate insights and suggestions from this image.'**
  String get previewHint;

  /// No description provided for @previewCanceled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get previewCanceled;

  /// No description provided for @previewPickFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to get image, please try again'**
  String get previewPickFailed;

  /// No description provided for @previewNotTargetTitle.
  ///
  /// In en, this message translates to:
  /// **'Target not detected'**
  String get previewNotTargetTitle;

  /// No description provided for @previewNotTargetMessage.
  ///
  /// In en, this message translates to:
  /// **'This image doesn\'t look like stool. Please retake or select a clearer image (only the target area).'**
  String get previewNotTargetMessage;

  /// No description provided for @previewBlurryMessage.
  ///
  /// In en, this message translates to:
  /// **'Image is not clear. Please retake or choose a clearer one.'**
  String get previewBlurryMessage;

  /// No description provided for @previewUnknownMessage.
  ///
  /// In en, this message translates to:
  /// **'Image cannot be recognized. Please try another.'**
  String get previewUnknownMessage;

  /// No description provided for @previewRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get previewRetake;

  /// No description provided for @previewSelectAgain.
  ///
  /// In en, this message translates to:
  /// **'Select again'**
  String get previewSelectAgain;

  /// No description provided for @previewCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get previewCancel;

  /// No description provided for @placeholderImage.
  ///
  /// In en, this message translates to:
  /// **'Placeholder'**
  String get placeholderImage;

  /// No description provided for @permissionCameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera permission needed'**
  String get permissionCameraTitle;

  /// No description provided for @permissionGalleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Gallery permission needed'**
  String get permissionGalleryTitle;

  /// No description provided for @permissionCameraMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enable camera permission in system settings.'**
  String get permissionCameraMessage;

  /// No description provided for @permissionGalleryMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enable photo permission in system settings.'**
  String get permissionGalleryMessage;

  /// No description provided for @permissionGoSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get permissionGoSettings;

  /// No description provided for @resultTitle.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get resultTitle;

  /// No description provided for @resultErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Analysis incomplete'**
  String get resultErrorTitle;

  /// No description provided for @resultErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get resultErrorMessage;

  /// No description provided for @resultRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry analysis'**
  String get resultRetry;

  /// No description provided for @resultSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get resultSummaryTitle;

  /// No description provided for @resultRiskTitle.
  ///
  /// In en, this message translates to:
  /// **'Risk level'**
  String get resultRiskTitle;

  /// No description provided for @resultRiskNote.
  ///
  /// In en, this message translates to:
  /// **'For health records only, not a medical diagnosis'**
  String get resultRiskNote;

  /// No description provided for @resultKeyTraitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Key traits'**
  String get resultKeyTraitsTitle;

  /// No description provided for @resultBristolTitle.
  ///
  /// In en, this message translates to:
  /// **'Bristol Type'**
  String get resultBristolTitle;

  /// No description provided for @resultBristolValue.
  ///
  /// In en, this message translates to:
  /// **'Type {type}'**
  String resultBristolValue(Object type);

  /// No description provided for @resultColorCaption.
  ///
  /// In en, this message translates to:
  /// **'Color may be diet-related'**
  String get resultColorCaption;

  /// No description provided for @resultTextureCaption.
  ///
  /// In en, this message translates to:
  /// **'Texture may reflect digestion'**
  String get resultTextureCaption;

  /// No description provided for @resultQualityTitle.
  ///
  /// In en, this message translates to:
  /// **'Image quality'**
  String get resultQualityTitle;

  /// No description provided for @resultQualityScore.
  ///
  /// In en, this message translates to:
  /// **'Score {score}/100'**
  String resultQualityScore(Object score);

  /// No description provided for @resultQualityGood.
  ///
  /// In en, this message translates to:
  /// **'Good quality'**
  String get resultQualityGood;

  /// No description provided for @resultQualityMore.
  ///
  /// In en, this message translates to:
  /// **'See more'**
  String get resultQualityMore;

  /// No description provided for @resultQualityLess.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get resultQualityLess;

  /// No description provided for @resultActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Next steps'**
  String get resultActionsTitle;

  /// No description provided for @resultActionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No suggestions'**
  String get resultActionsEmpty;

  /// No description provided for @resultMetricBristol.
  ///
  /// In en, this message translates to:
  /// **'Bristol'**
  String get resultMetricBristol;

  /// No description provided for @resultMetricColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get resultMetricColor;

  /// No description provided for @resultMetricTexture.
  ///
  /// In en, this message translates to:
  /// **'Texture'**
  String get resultMetricTexture;

  /// No description provided for @resultMetricScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get resultMetricScore;

  /// No description provided for @resultWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get resultWarningTitle;

  /// No description provided for @resultWarningHint.
  ///
  /// In en, this message translates to:
  /// **'Please seek care if you feel unwell.'**
  String get resultWarningHint;

  /// No description provided for @resultSeekCareTitle.
  ///
  /// In en, this message translates to:
  /// **'When to seek care'**
  String get resultSeekCareTitle;

  /// No description provided for @resultSeekCareEmpty.
  ///
  /// In en, this message translates to:
  /// **'No items'**
  String get resultSeekCareEmpty;

  /// No description provided for @resultDisclaimersDefault.
  ///
  /// In en, this message translates to:
  /// **'This result is for health logging and self-observation, not a professional diagnosis.'**
  String get resultDisclaimersDefault;

  /// No description provided for @resultExtraTitle.
  ///
  /// In en, this message translates to:
  /// **'Additional info'**
  String get resultExtraTitle;

  /// No description provided for @resultOdorLabel.
  ///
  /// In en, this message translates to:
  /// **'Odor'**
  String get resultOdorLabel;

  /// No description provided for @resultPainLabel.
  ///
  /// In en, this message translates to:
  /// **'Pain/Strain'**
  String get resultPainLabel;

  /// No description provided for @resultDietLabel.
  ///
  /// In en, this message translates to:
  /// **'Diet keywords'**
  String get resultDietLabel;

  /// No description provided for @resultDietHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. spicy, takeout, dairy'**
  String get resultDietHint;

  /// No description provided for @resultSubmitUpdate.
  ///
  /// In en, this message translates to:
  /// **'Submit and update'**
  String get resultSubmitUpdate;

  /// No description provided for @resultUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get resultUpdated;

  /// No description provided for @resultReanalyze.
  ///
  /// In en, this message translates to:
  /// **'Re-analyze'**
  String get resultReanalyze;

  /// No description provided for @resultSave.
  ///
  /// In en, this message translates to:
  /// **'Save record'**
  String get resultSave;

  /// No description provided for @resultSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get resultSaved;

  /// No description provided for @resultSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed, try again'**
  String get resultSaveFailed;

  /// No description provided for @resultAdviceUpdated.
  ///
  /// In en, this message translates to:
  /// **'Suggestions updated'**
  String get resultAdviceUpdated;

  /// No description provided for @resultAdviceUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update suggestions'**
  String get resultAdviceUpdateFailed;

  /// No description provided for @resultSummaryExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get resultSummaryExpand;

  /// No description provided for @resultSummaryCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get resultSummaryCollapse;

  /// No description provided for @resultAnalysisTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Analysis time: {time}'**
  String resultAnalysisTimeLabel(Object time);

  /// No description provided for @resultHealthReference.
  ///
  /// In en, this message translates to:
  /// **'For health reference only'**
  String get resultHealthReference;

  /// No description provided for @riskLowDesc.
  ///
  /// In en, this message translates to:
  /// **'Stable overall. Keep observing and logging.'**
  String get riskLowDesc;

  /// No description provided for @riskMediumDesc.
  ///
  /// In en, this message translates to:
  /// **'Some signals need attention. Observe with diet/symptoms.'**
  String get riskMediumDesc;

  /// No description provided for @riskHighDesc.
  ///
  /// In en, this message translates to:
  /// **'Stronger warning. Seek care if discomfort occurs.'**
  String get riskHighDesc;

  /// No description provided for @bristolHintDry.
  ///
  /// In en, this message translates to:
  /// **'Dry/hard'**
  String get bristolHintDry;

  /// No description provided for @bristolHintIdeal.
  ///
  /// In en, this message translates to:
  /// **'Ideal'**
  String get bristolHintIdeal;

  /// No description provided for @bristolHintLoose.
  ///
  /// In en, this message translates to:
  /// **'Loose'**
  String get bristolHintLoose;

  /// No description provided for @riskLowLabel.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get riskLowLabel;

  /// No description provided for @riskMediumLabel.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get riskMediumLabel;

  /// No description provided for @riskHighLabel.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get riskHighLabel;

  /// No description provided for @colorBrown.
  ///
  /// In en, this message translates to:
  /// **'Brown'**
  String get colorBrown;

  /// No description provided for @colorYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get colorYellow;

  /// No description provided for @colorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colorGreen;

  /// No description provided for @colorBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get colorBlack;

  /// No description provided for @colorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colorRed;

  /// No description provided for @colorPale.
  ///
  /// In en, this message translates to:
  /// **'Pale'**
  String get colorPale;

  /// No description provided for @colorMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get colorMixed;

  /// No description provided for @colorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get colorUnknown;

  /// No description provided for @textureWatery.
  ///
  /// In en, this message translates to:
  /// **'Watery'**
  String get textureWatery;

  /// No description provided for @textureMushy.
  ///
  /// In en, this message translates to:
  /// **'Mushy'**
  String get textureMushy;

  /// No description provided for @textureNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get textureNormal;

  /// No description provided for @textureHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get textureHard;

  /// No description provided for @textureOily.
  ///
  /// In en, this message translates to:
  /// **'Oily'**
  String get textureOily;

  /// No description provided for @textureFoamy.
  ///
  /// In en, this message translates to:
  /// **'Foamy'**
  String get textureFoamy;

  /// No description provided for @textureUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get textureUnknown;

  /// No description provided for @odorNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get odorNone;

  /// No description provided for @odorLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get odorLight;

  /// No description provided for @odorStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get odorStrong;

  /// No description provided for @odorSour.
  ///
  /// In en, this message translates to:
  /// **'Sour'**
  String get odorSour;

  /// No description provided for @odorRotten.
  ///
  /// In en, this message translates to:
  /// **'Rotten'**
  String get odorRotten;

  /// No description provided for @odorOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get odorOther;

  /// No description provided for @detailTitle.
  ///
  /// In en, this message translates to:
  /// **'Record details'**
  String get detailTitle;

  /// No description provided for @detailRiskSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Risk overview'**
  String get detailRiskSummaryTitle;

  /// No description provided for @detailResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get detailResultTitle;

  /// No description provided for @detailSuspiciousSignalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Suspicious signals'**
  String get detailSuspiciousSignalsTitle;

  /// No description provided for @detailQualityTitle.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get detailQualityTitle;

  /// No description provided for @detailInputsTitle.
  ///
  /// In en, this message translates to:
  /// **'Additional info'**
  String get detailInputsTitle;

  /// No description provided for @detailAdviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Advice'**
  String get detailAdviceTitle;

  /// No description provided for @detailActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Next 48h'**
  String get detailActionsTitle;

  /// No description provided for @detailCareTitle.
  ///
  /// In en, this message translates to:
  /// **'Seek care'**
  String get detailCareTitle;

  /// No description provided for @detailEmptyValue.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get detailEmptyValue;

  /// No description provided for @detailYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get detailYes;

  /// No description provided for @detailNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get detailNo;

  /// No description provided for @detailNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get detailNotProvided;

  /// No description provided for @detailDisclaimerLabel.
  ///
  /// In en, this message translates to:
  /// **'Disclaimer: '**
  String get detailDisclaimerLabel;

  /// No description provided for @detailLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load'**
  String get detailLoadFailedTitle;

  /// No description provided for @detailLoadFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'This record may be missing or corrupted.'**
  String get detailLoadFailedMessage;

  /// No description provided for @detailBackHistory.
  ///
  /// In en, this message translates to:
  /// **'Back to history'**
  String get detailBackHistory;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsDataTitle;

  /// No description provided for @settingsDataLine1.
  ///
  /// In en, this message translates to:
  /// **'Records are stored locally (offline)'**
  String get settingsDataLine1;

  /// No description provided for @settingsDataLine2.
  ///
  /// In en, this message translates to:
  /// **'You can export or clear at any time'**
  String get settingsDataLine2;

  /// No description provided for @settingsDataMgmtTitle.
  ///
  /// In en, this message translates to:
  /// **'Data management'**
  String get settingsDataMgmtTitle;

  /// No description provided for @settingsExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export records'**
  String get settingsExportTitle;

  /// No description provided for @settingsExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Export as JSON for backup'**
  String get settingsExportSubtitle;

  /// No description provided for @settingsClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get settingsClearTitle;

  /// No description provided for @settingsClearSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cannot be undone'**
  String get settingsClearSubtitle;

  /// No description provided for @settingsClearDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm clear?'**
  String get settingsClearDialogTitle;

  /// No description provided for @settingsClearDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Clearing will remove all history and cannot be undone.'**
  String get settingsClearDialogMessage;

  /// No description provided for @settingsClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get settingsClearConfirm;

  /// No description provided for @settingsCleared.
  ///
  /// In en, this message translates to:
  /// **'Cleared'**
  String get settingsCleared;

  /// No description provided for @settingsExporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting...'**
  String get settingsExporting;

  /// No description provided for @settingsExportEmpty.
  ///
  /// In en, this message translates to:
  /// **'No records to export'**
  String get settingsExportEmpty;

  /// No description provided for @settingsExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Exported (total {count})'**
  String settingsExportSuccess(Object count);

  /// No description provided for @settingsExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed, please try again'**
  String get settingsExportFailed;

  /// No description provided for @settingsAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAboutTitle;

  /// No description provided for @settingsVersionTitle.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersionTitle;

  /// No description provided for @settingsSchemaVersion.
  ///
  /// In en, this message translates to:
  /// **'Schema v{version}'**
  String settingsSchemaVersion(Object version);

  /// No description provided for @settingsUsageTitle.
  ///
  /// In en, this message translates to:
  /// **'How to use'**
  String get settingsUsageTitle;

  /// No description provided for @settingsUsageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quick start guide'**
  String get settingsUsageSubtitle;

  /// No description provided for @settingsUsageDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'How to use'**
  String get settingsUsageDialogTitle;

  /// No description provided for @settingsUsageDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Take or select a photo, analyze, and save to history.'**
  String get settingsUsageDialogMessage;

  /// No description provided for @settingsUsageDialogClose.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get settingsUsageDialogClose;

  /// No description provided for @settingsPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy & data'**
  String get settingsPrivacyTitle;

  /// No description provided for @settingsPrivacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stored locally, clear anytime'**
  String get settingsPrivacySubtitle;

  /// No description provided for @settingsAnalyzerModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Analysis mode'**
  String get settingsAnalyzerModeTitle;

  /// No description provided for @settingsAnalyzerLocalTitle.
  ///
  /// In en, this message translates to:
  /// **'Local (Mock)'**
  String get settingsAnalyzerLocalTitle;

  /// No description provided for @settingsAnalyzerLocalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stable and offline'**
  String get settingsAnalyzerLocalSubtitle;

  /// No description provided for @settingsAnalyzerRemoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud (Remote)'**
  String get settingsAnalyzerRemoteTitle;

  /// No description provided for @settingsAnalyzerRemoteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Requires backend, may be unavailable'**
  String get settingsAnalyzerRemoteSubtitle;

  /// No description provided for @settingsDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This app is for health logging only, not a medical diagnosis. Seek care if you feel unwell.'**
  String get settingsDisclaimer;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy & data'**
  String get privacyTitle;

  /// No description provided for @privacyLocalTitle.
  ///
  /// In en, this message translates to:
  /// **'Local storage'**
  String get privacyLocalTitle;

  /// No description provided for @privacyLocalLine1.
  ///
  /// In en, this message translates to:
  /// **'Analysis and records stay on this device.'**
  String get privacyLocalLine1;

  /// No description provided for @privacyLocalLine2.
  ///
  /// In en, this message translates to:
  /// **'You can clear all records anytime.'**
  String get privacyLocalLine2;

  /// No description provided for @privacyExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get privacyExportTitle;

  /// No description provided for @privacyExportLine1.
  ///
  /// In en, this message translates to:
  /// **'Export copies records as JSON to clipboard.'**
  String get privacyExportLine1;

  /// No description provided for @privacyExportLine2.
  ///
  /// In en, this message translates to:
  /// **'Avoid including personal sensitive info.'**
  String get privacyExportLine2;

  /// No description provided for @privacyClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear now'**
  String get privacyClearTitle;

  /// No description provided for @privacyClearLine.
  ///
  /// In en, this message translates to:
  /// **'Delete all local records instantly.'**
  String get privacyClearLine;

  /// No description provided for @privacyClearButton.
  ///
  /// In en, this message translates to:
  /// **'Clear all data'**
  String get privacyClearButton;

  /// No description provided for @privacyCleared.
  ///
  /// In en, this message translates to:
  /// **'Cleared'**
  String get privacyCleared;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Exported'**
  String get exportSuccess;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed, please try again'**
  String get exportFailed;

  /// No description provided for @exportPdfTooltip.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdfTooltip;

  /// No description provided for @pdfTitle.
  ///
  /// In en, this message translates to:
  /// **'Health Insight Record'**
  String get pdfTitle;

  /// No description provided for @pdfRecordTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Record time'**
  String get pdfRecordTimeLabel;

  /// No description provided for @pdfSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get pdfSummaryTitle;

  /// No description provided for @pdfRiskLabel.
  ///
  /// In en, this message translates to:
  /// **'Risk level'**
  String get pdfRiskLabel;

  /// No description provided for @pdfKeyTraitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Key traits'**
  String get pdfKeyTraitsTitle;

  /// No description provided for @pdfQualityTitle.
  ///
  /// In en, this message translates to:
  /// **'Image quality'**
  String get pdfQualityTitle;

  /// No description provided for @pdfQualityScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get pdfQualityScoreLabel;

  /// No description provided for @pdfQualityGood.
  ///
  /// In en, this message translates to:
  /// **'Good quality'**
  String get pdfQualityGood;

  /// No description provided for @pdfActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Next steps (48h)'**
  String get pdfActionsTitle;

  /// No description provided for @pdfActionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No suggestions'**
  String get pdfActionsEmpty;

  /// No description provided for @pdfSeekCareTitle.
  ///
  /// In en, this message translates to:
  /// **'When to seek care'**
  String get pdfSeekCareTitle;

  /// No description provided for @pdfSeekCareEmpty.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get pdfSeekCareEmpty;

  /// No description provided for @pdfDisclaimerDefault.
  ///
  /// In en, this message translates to:
  /// **'This result is for health logging and self-observation, not a professional diagnosis.'**
  String get pdfDisclaimerDefault;

  /// No description provided for @pdfRiskLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get pdfRiskLow;

  /// No description provided for @pdfRiskMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get pdfRiskMedium;

  /// No description provided for @pdfRiskHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get pdfRiskHigh;

  /// No description provided for @pdfColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get pdfColorLabel;

  /// No description provided for @pdfTextureLabel.
  ///
  /// In en, this message translates to:
  /// **'Texture'**
  String get pdfTextureLabel;

  /// No description provided for @pdfBristolLabel.
  ///
  /// In en, this message translates to:
  /// **'Bristol Type'**
  String get pdfBristolLabel;

  /// No description provided for @loadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Analyzing'**
  String get loadingTitle;

  /// No description provided for @loadingStepQuality.
  ///
  /// In en, this message translates to:
  /// **'Check image quality'**
  String get loadingStepQuality;

  /// No description provided for @loadingStepFeatures.
  ///
  /// In en, this message translates to:
  /// **'Identify key traits'**
  String get loadingStepFeatures;

  /// No description provided for @loadingStepAdvice.
  ///
  /// In en, this message translates to:
  /// **'Generate suggestions'**
  String get loadingStepAdvice;

  /// No description provided for @remoteUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Cloud service unavailable, please try later'**
  String get remoteUnavailable;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'de',
        'en',
        'es',
        'fr',
        'id',
        'ja',
        'ko',
        'th',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'id':
      return AppLocalizationsId();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'th':
      return AppLocalizationsTh();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
