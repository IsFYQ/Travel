/// P1-3.11：AI 场景参数配置
enum PromptScene {
  itineraryGeneration,
  destinationRecommend,
  dailyChat,
  followUpSuggestions,
  diaryFromItinerary,
  profileExtract,
}

class PromptSceneConfig {
  final double temperature;
  final int maxTokens;

  const PromptSceneConfig({
    required this.temperature,
    required this.maxTokens,
  });
}

/// P1-3.11：Prompt 分层组装
class PromptBuilder {
  static const sceneConfigs = {
    PromptScene.itineraryGeneration: PromptSceneConfig(temperature: 0.3, maxTokens: 4096),
    PromptScene.destinationRecommend: PromptSceneConfig(temperature: 0.7, maxTokens: 512),
    PromptScene.dailyChat: PromptSceneConfig(temperature: 0.5, maxTokens: 2048),
    PromptScene.followUpSuggestions: PromptSceneConfig(temperature: 0.4, maxTokens: 256),
    PromptScene.diaryFromItinerary: PromptSceneConfig(temperature: 0.3, maxTokens: 4096),
    PromptScene.profileExtract: PromptSceneConfig(temperature: 0.3, maxTokens: 1024),
  };

  static PromptSceneConfig configFor(PromptScene scene) =>
      sceneConfigs[scene]!;

  /// 四层拼接：人设 / 画像 / RAG / 任务指令
  static String assemble({
    required String systemPersona,
    String? profileText,
    String? ragContext,
    String? taskInstruction,
    String? followUpInstruction,
  }) {
    final buffer = StringBuffer(systemPersona);

    if (profileText != null && profileText.isNotEmpty) {
      buffer.writeln('\n$profileText');
    }
    if (ragContext != null && ragContext.isNotEmpty) {
      buffer.writeln('\n$ragContext');
    }
    if (taskInstruction != null && taskInstruction.isNotEmpty) {
      buffer.writeln('\n$taskInstruction');
    }
    if (followUpInstruction != null && followUpInstruction.isNotEmpty) {
      buffer.writeln('\n$followUpInstruction');
    }
    return buffer.toString();
  }
}
