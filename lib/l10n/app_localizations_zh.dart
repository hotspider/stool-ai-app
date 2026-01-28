// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '健康识别';

  @override
  String get navHome => '主页';

  @override
  String get navHistory => '历史';

  @override
  String get navSettings => '设置';

  @override
  String get homeTitle => '健康识别';

  @override
  String get homeDisclaimer => '仅供健康参考，不替代诊断';

  @override
  String get homePrimaryAction => '拍照分析';

  @override
  String get homePrimaryDesc => '在光线良好的环境下拍摄清晰照片';

  @override
  String get homeSecondaryAction => '从相册选择';

  @override
  String get homeSecondaryDesc => '选择最近的照片进行分析';

  @override
  String get homeHeroSubtitle => '用一张照片记录健康变化';

  @override
  String get homeStepsTitle => '使用步骤';

  @override
  String get homeStep1 => '1 选择图片';

  @override
  String get homeStep2 => '2 开始分析';

  @override
  String get homeStep3 => '3 保存到历史';

  @override
  String get homeTipsTitle => '拍摄建议';

  @override
  String get homeTip1 => '光线充足、画面清晰';

  @override
  String get homeTip2 => '尽量只包含目标区域';

  @override
  String get homeTip3 => '不要包含脸部/隐私信息';

  @override
  String get homeRecentTitle => '最近一次记录';

  @override
  String get homeRecentEmptyTitle => '还没有记录';

  @override
  String get homeRecentEmptyMessage => '完成一次分析后，会自动保存在这里。';

  @override
  String get homeRecentAction => '开始分析';

  @override
  String get homeRecentCardTitle => '最近一次分析';

  @override
  String get homeRecentView => '查看';

  @override
  String get historyTitle => '历史记录';

  @override
  String get historyDeleted => '记录已删除';

  @override
  String get historyDeletedUndo => '记录已删除，可撤销';

  @override
  String get historyUndoAction => '撤销';

  @override
  String get historyDeleteTitle => '删除记录';

  @override
  String get historyDeleteMessage => '确认删除这条记录吗？';

  @override
  String get historyDeleteAction => '删除';

  @override
  String get historyEmptyTitle => '还没有历史记录';

  @override
  String get historyEmptyMessage => '完成一次分析后，会自动保存在这里。';

  @override
  String get historyEmptyAction => '开始分析';

  @override
  String historyItemMeta(Object type, Object score) {
    return 'Bristol Type $type · 评分 $score/100';
  }

  @override
  String get previewTitle => '预览';

  @override
  String get previewNoImageTitle => '未获取到图片';

  @override
  String get previewNoImageMessage => '请选择一张图片后继续分析。';

  @override
  String get previewBackHome => '返回首页';

  @override
  String get previewValidating => '正在检查图片质量...';

  @override
  String get previewWeakPass => '图片内容不确定，结果仅供参考。';

  @override
  String get previewPass => '图片检查通过，可以开始分析。';

  @override
  String get previewRechoose => '重新选择';

  @override
  String get previewStartAnalyze => '开始分析';

  @override
  String get previewHint => '我们将基于图片生成健康识别结果与建议。';

  @override
  String get previewCanceled => '已取消';

  @override
  String get previewPickFailed => '获取图片失败，请重试';

  @override
  String get previewNotTargetTitle => '未识别到目标';

  @override
  String get previewNotTargetMessage =>
      '这张图片看起来不是便便。请重新拍摄或从相册选择更清晰的图片（建议只包含目标区域）。';

  @override
  String get previewBlurryMessage => '图片不清晰，请重新拍摄或选择更清晰的图片（建议只包含目标区域）。';

  @override
  String get previewUnknownMessage => '图片暂时无法识别，请重新选择。';

  @override
  String get previewRetake => '重新拍照';

  @override
  String get previewSelectAgain => '重新选择';

  @override
  String get previewCancel => '取消';

  @override
  String get placeholderImage => '占位图';

  @override
  String get permissionCameraTitle => '相机权限未开启';

  @override
  String get permissionGalleryTitle => '相册权限未开启';

  @override
  String get permissionCameraMessage => '请在系统设置中开启相机权限。';

  @override
  String get permissionGalleryMessage => '请在系统设置中开启相册权限。';

  @override
  String get permissionGoSettings => '去设置';

  @override
  String get resultTitle => '分析结果';

  @override
  String get resultErrorTitle => '分析未完成';

  @override
  String get resultErrorMessage => '当前分析出现异常，请重试。';

  @override
  String get resultRetry => '重试分析';

  @override
  String get resultSummaryTitle => '本次结论';

  @override
  String get resultRiskTitle => '风险等级';

  @override
  String get resultRiskNote => '仅供健康记录参考，不替代医生诊断';

  @override
  String get resultKeyTraitsTitle => '关键特征';

  @override
  String get resultBristolTitle => 'Bristol Type';

  @override
  String resultBristolValue(Object type) {
    return 'Type $type';
  }

  @override
  String get resultColorCaption => '颜色变化可能与饮食相关';

  @override
  String get resultTextureCaption => '质地变化提示消化状态';

  @override
  String get resultQualityTitle => '图片质量';

  @override
  String resultQualityScore(Object score) {
    return '评分 $score/100';
  }

  @override
  String get resultQualityGood => '质量良好';

  @override
  String get resultQualityMore => '查看更多';

  @override
  String get resultQualityLess => '收起';

  @override
  String get resultActionsTitle => '下一步建议';

  @override
  String get resultInsightsTitle => '解释点';

  @override
  String get resultActionsTodayTitle => '今日行动清单';

  @override
  String get resultRedFlagsTitle => '红旗预警';

  @override
  String get resultFollowUpTitle => '追问问题';

  @override
  String get resultInsufficientMessage => '未识别/信息不足';

  @override
  String get resultActionsDiet => '饮食';

  @override
  String get resultActionsHydration => '补液';

  @override
  String get resultActionsCare => '护理';

  @override
  String get resultActionsObserve => '观察（未来24小时）';
  @override
  String get resultActionsAvoid => '今日避免';

  @override
  String get resultActionsEmpty => '暂无建议';

  @override
  String get resultMetricBristol => 'Bristol';

  @override
  String get resultMetricColor => '颜色';

  @override
  String get resultMetricTexture => '质地';

  @override
  String get resultMetricScore => '评分';

  @override
  String get resultWarningTitle => '需要关注';

  @override
  String get resultWarningHint => '如出现不适，请及时就医。';

  @override
  String get resultSeekCareTitle => '何时需要就医';

  @override
  String get resultSeekCareEmpty => '暂无';

  @override
  String get resultDisclaimersDefault => '本结果用于健康记录与自我观察，不替代专业医疗诊断。';

  @override
  String get resultExtraTitle => '补充信息';

  @override
  String get resultOdorLabel => '气味';

  @override
  String get resultPainLabel => '是否疼痛或费力';

  @override
  String get resultDietLabel => '饮食关键词';

  @override
  String get resultDietHint => '例如：辛辣、外卖、奶制品';

  @override
  String get resultSubmitUpdate => '提交并更新建议';

  @override
  String get resultUpdated => '已更新建议';

  @override
  String get resultReanalyze => '重新分析';

  @override
  String get resultSave => '保存本次记录';

  @override
  String get resultSaved => '已保存本次记录';

  @override
  String get resultSaveFailed => '保存失败，请稍后重试';

  @override
  String get resultAdviceUpdated => '已更新建议';

  @override
  String get resultAdviceUpdateFailed => '建议更新失败，请稍后重试';

  @override
  String get resultSummaryExpand => '展开';

  @override
  String get resultSummaryCollapse => '收起';

  @override
  String resultAnalysisTimeLabel(Object time) {
    return '分析时间：$time';
  }

  @override
  String get resultHealthReference => '仅供健康参考';

  @override
  String get riskLowDesc => '总体表现较稳定，可继续观察并保持记录';

  @override
  String get riskMediumDesc => '存在一些需要注意的信号，建议结合饮食/症状继续观察';

  @override
  String get riskHighDesc => '出现较强警示信号，如伴随不适请尽快就医';

  @override
  String get bristolHintDry => '偏干硬';

  @override
  String get bristolHintIdeal => '较理想';

  @override
  String get bristolHintLoose => '偏稀软';

  @override
  String get riskLowLabel => '低';

  @override
  String get riskMediumLabel => '中';

  @override
  String get riskHighLabel => '高';

  @override
  String get colorBrown => '棕色';

  @override
  String get colorYellow => '黄色';

  @override
  String get colorGreen => '绿色';

  @override
  String get colorBlack => '黑色';

  @override
  String get colorRed => '红色';

  @override
  String get colorPale => '偏淡';

  @override
  String get colorMixed => '混合色';

  @override
  String get colorUnknown => '未知';

  @override
  String get textureWatery => '稀水样';

  @override
  String get textureMushy => '糊状';

  @override
  String get textureNormal => '正常';

  @override
  String get textureHard => '偏硬';

  @override
  String get textureOily => '偏油';

  @override
  String get textureFoamy => '泡沫样';

  @override
  String get textureUnknown => '未知';

  @override
  String get odorNone => '无';

  @override
  String get odorLight => '轻';

  @override
  String get odorStrong => '明显';

  @override
  String get odorSour => '酸臭';

  @override
  String get odorRotten => '腐败';

  @override
  String get odorOther => '其他';

  @override
  String get detailTitle => '记录详情';

  @override
  String get detailRiskSummaryTitle => '风险概览';

  @override
  String get detailResultTitle => '识别结果';

  @override
  String get detailSuspiciousSignalsTitle => '疑似点';

  @override
  String get detailQualityTitle => '质量提示';

  @override
  String get detailInputsTitle => '补充信息';

  @override
  String get detailAdviceTitle => '建议';

  @override
  String get detailActionsTitle => '48小时行动';

  @override
  String get detailCareTitle => '就医关注';

  @override
  String get detailEmptyValue => '暂无';

  @override
  String get detailYes => '是';

  @override
  String get detailNo => '否';

  @override
  String get detailNotProvided => '未填写';

  @override
  String get detailDisclaimerLabel => '免责声明：';

  @override
  String get detailLoadFailedTitle => '记录无法加载';

  @override
  String get detailLoadFailedMessage => '该记录可能已损坏或不存在。';

  @override
  String get detailBackHistory => '返回历史记录';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsDataTitle => '数据';

  @override
  String get settingsDataLine1 => '记录保存在本机（离线）';

  @override
  String get settingsDataLine2 => '可随时导出或清空';

  @override
  String get settingsDataMgmtTitle => '数据管理';

  @override
  String get settingsExportTitle => '导出记录';

  @override
  String get settingsExportSubtitle => '导出为 JSON 文本，便于备份';

  @override
  String get settingsClearTitle => '清空历史记录';

  @override
  String get settingsClearSubtitle => '不可恢复，请谨慎操作';

  @override
  String get settingsClearDialogTitle => '确认清空？';

  @override
  String get settingsClearDialogMessage => '清空后将删除所有历史记录，且无法恢复。';

  @override
  String get settingsClearConfirm => '确认清空';

  @override
  String get settingsCleared => '已清空';

  @override
  String get settingsExporting => '正在导出...';

  @override
  String get settingsExportEmpty => '暂无可导出记录';

  @override
  String settingsExportSuccess(Object count) {
    return '已导出（共 $count 条）';
  }

  @override
  String get settingsExportFailed => '导出失败，请重试';

  @override
  String get settingsAboutTitle => '关于';

  @override
  String get settingsVersionTitle => '版本';

  @override
  String settingsSchemaVersion(Object version) {
    return 'Schema v$version';
  }

  @override
  String get settingsUsageTitle => '使用说明';

  @override
  String get settingsUsageSubtitle => '快速了解如何开始使用';

  @override
  String get settingsUsageDialogTitle => '使用说明';

  @override
  String get settingsUsageDialogMessage => '拍照或选择图片进行分析，结果可保存到历史记录中。';

  @override
  String get settingsUsageDialogClose => '知道了';

  @override
  String get settingsPrivacyTitle => '隐私与数据';

  @override
  String get settingsPrivacySubtitle => '本机保存、可随时清空';

  @override
  String get settingsAnalyzerModeTitle => '分析方式';

  @override
  String get settingsAnalyzerLocalTitle => '本地（Mock）';

  @override
  String get settingsAnalyzerLocalSubtitle => '稳定可用，离线运行';

  @override
  String get settingsAnalyzerRemoteTitle => '云端（Remote）';

  @override
  String get settingsAnalyzerRemoteSubtitle => '需要后端服务，当前可能不可用';

  @override
  String get settingsDisclaimer =>
      '本应用用于健康记录与自我观察，不替代专业医疗诊断。如出现明显不适或警示信号，请及时就医。';

  @override
  String get privacyTitle => '隐私与数据';

  @override
  String get privacyLocalTitle => '本地保存';

  @override
  String get privacyLocalLine1 => '分析与记录仅保存在本机，不会上传到服务器。';

  @override
  String get privacyLocalLine2 => '你可以随时清空全部记录。';

  @override
  String get privacyExportTitle => '导出说明';

  @override
  String get privacyExportLine1 => '导出会将记录以 JSON 形式复制到剪贴板。';

  @override
  String get privacyExportLine2 => '请勿在导出内容中包含身份证、手机号等敏感信息。';

  @override
  String get privacyClearTitle => '立即清空';

  @override
  String get privacyClearLine => '如需删除所有本地记录，可立即清空。';

  @override
  String get privacyClearButton => '立即清空全部数据';

  @override
  String get privacyCleared => '已清空全部记录';

  @override
  String get exportSuccess => '导出成功';

  @override
  String get exportFailed => '导出失败，请重试';

  @override
  String get exportPdfTooltip => '导出 PDF';

  @override
  String get pdfTitle => '健康识别记录';

  @override
  String get pdfRecordTimeLabel => '记录时间';

  @override
  String get pdfSummaryTitle => '本次结论';

  @override
  String get pdfRiskLabel => '风险等级';

  @override
  String get pdfKeyTraitsTitle => '关键特征';

  @override
  String get pdfQualityTitle => '图片质量';

  @override
  String get pdfQualityScoreLabel => '评分';

  @override
  String get pdfQualityGood => '质量良好';

  @override
  String get pdfActionsTitle => '下一步建议（48小时）';

  @override
  String get pdfActionsEmpty => '暂无建议';

  @override
  String get pdfSeekCareTitle => '何时需要就医';

  @override
  String get pdfSeekCareEmpty => '暂无';

  @override
  String get pdfDisclaimerDefault => '本结果用于健康记录与自我观察，不替代专业医疗诊断。';

  @override
  String get pdfRiskLow => '低';

  @override
  String get pdfRiskMedium => '中';

  @override
  String get pdfRiskHigh => '高';

  @override
  String get pdfColorLabel => '颜色';

  @override
  String get pdfTextureLabel => '质地';

  @override
  String get pdfBristolLabel => 'Bristol Type';

  @override
  String get loadingTitle => '分析中';

  @override
  String get loadingStepQuality => '检查图片质量';

  @override
  String get loadingStepFeatures => '识别关键特征';

  @override
  String get loadingStepAdvice => '生成行动建议';

  @override
  String get remoteUnavailable => '云端暂不可用，请稍后重试';
}
