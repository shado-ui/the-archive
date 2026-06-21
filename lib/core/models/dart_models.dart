// Helper date formatter/parsers
DateTime? parseDate(dynamic value) {
  if (value == null) return null;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

List<String> parseStringList(dynamic value) {
  if (value == null) return [];
  if (value is List) return value.map((e) => e.toString()).toList();
  return [];
}

double parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

// --------------------------------------------------------------------
// 1. UserProfile Model
// --------------------------------------------------------------------
class UserProfile {
  final String id;
  final String? firstName;
  final String? lastName;
  final String vaultSalt;

  UserProfile({
    required this.id,
    this.firstName,
    this.lastName,
    required this.vaultSalt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      vaultSalt: json['vault_salt'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'first_name': firstName,
        'last_name': lastName,
        'vault_salt': vaultSalt,
      };
}

// --------------------------------------------------------------------
// 2. PartnerProfile Model (Krisha complete personal profile)
// --------------------------------------------------------------------
class PartnerProfile {
  final String id;
  final String userId;
  final String fullName;
  final List<String> nicknames;
  final DateTime? birthday;
  final String? zodiacSign;
  final String? favoriteColor;
  final String? favoriteFlower;
  final String? favoriteAnimal;
  final String? favoriteFood;
  final String? favoriteDrink;
  final String? favoritePerfume;
  final List<String> favoriteBrands;
  final List<String> favoriteClothingStyles;
  final String? shoeSize;
  final String? ringSize;
  final List<String> hobbies;
  final List<String> dreams;
  final List<String> goals;
  final List<String> bucketList;
  final List<String> fears;
  final List<String> insecurities;
  final List<String> strengths;
  final List<String> weaknesses;
  final String? personalityNotes;

  PartnerProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.nicknames,
    this.birthday,
    this.zodiacSign,
    this.favoriteColor,
    this.favoriteFlower,
    this.favoriteAnimal,
    this.favoriteFood,
    this.favoriteDrink,
    this.favoritePerfume,
    required this.favoriteBrands,
    required this.favoriteClothingStyles,
    this.shoeSize,
    this.ringSize,
    required this.hobbies,
    required this.dreams,
    required this.goals,
    required this.bucketList,
    required this.fears,
    required this.insecurities,
    required this.strengths,
    required this.weaknesses,
    this.personalityNotes,
  });

  factory PartnerProfile.fromJson(Map<String, dynamic> json) {
    return PartnerProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      nicknames: parseStringList(json['nicknames']),
      birthday: parseDate(json['birthday']),
      zodiacSign: json['zodiac_sign'] as String?,
      favoriteColor: json['favorite_color'] as String?,
      favoriteFlower: json['favorite_flower'] as String?,
      favoriteAnimal: json['favorite_animal'] as String?,
      favoriteFood: json['favorite_food'] as String?,
      favoriteDrink: json['favorite_drink'] as String?,
      favoritePerfume: json['favorite_perfume'] as String?,
      favoriteBrands: parseStringList(json['favorite_brands']),
      favoriteClothingStyles: parseStringList(json['favorite_clothing_styles']),
      shoeSize: json['shoe_size'] as String?,
      ringSize: json['ring_size'] as String?,
      hobbies: parseStringList(json['hobbies']),
      dreams: parseStringList(json['dreams']),
      goals: parseStringList(json['goals']),
      bucketList: parseStringList(json['bucket_list']),
      fears: parseStringList(json['fears']),
      insecurities: parseStringList(json['insecurities']),
      strengths: parseStringList(json['strengths']),
      weaknesses: parseStringList(json['weaknesses']),
      personalityNotes: json['personality_notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'full_name': fullName,
        'nicknames': nicknames,
        'birthday': birthday?.toIso8601String().split('T').first,
        'zodiac_sign': zodiacSign,
        'favorite_color': favoriteColor,
        'favorite_flower': favoriteFlower,
        'favorite_animal': favorite_animal,
        'favorite_food': favoriteFood,
        'favorite_drink': favoriteDrink,
        'favorite_perfume': favoritePerfume,
        'favorite_brands': favoriteBrands,
        'favorite_clothing_styles': favoriteClothingStyles,
        'shoe_size': shoeSize,
        'ring_size': ringSize,
        'hobbies': hobbies,
        'dreams': dreams,
        'goals': goals,
        'bucket_list': bucketList,
        'fears': fears,
        'insecurities': insecurities,
        'strengths': strengths,
        'weaknesses': weaknesses,
        'personality_notes': personalityNotes,
      };

  String get favorite_animal => favoriteAnimal ?? '';
}

// --------------------------------------------------------------------
// 3. PlatformCredential Model (Encrypted Secrets Vault)
// --------------------------------------------------------------------
class PlatformCredential {
  final String id;
  final String userId;
  final String platformName;
  final String? websiteUrl;
  final String? usernameEmail;
  final String encryptedPassword; // AES encrypted
  final String? recoveryEmail;
  final String? securityQuestions; // AES encrypted JSON string
  final String? notes; // AES encrypted

  PlatformCredential({
    required this.id,
    required this.userId,
    required this.platformName,
    this.websiteUrl,
    this.usernameEmail,
    required this.encryptedPassword,
    this.recoveryEmail,
    this.securityQuestions,
    this.notes,
  });

  factory PlatformCredential.fromJson(Map<String, dynamic> json) {
    return PlatformCredential(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      platformName: json['platform_name'] as String,
      websiteUrl: json['website_url'] as String?,
      usernameEmail: json['username_email'] as String?,
      encryptedPassword: json['encrypted_password'] as String,
      recoveryEmail: json['recovery_email'] as String?,
      securityQuestions: json['security_questions'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'platform_name': platformName,
        'website_url': websiteUrl,
        'username_email': usernameEmail,
        'encrypted_password': encryptedPassword,
        'recovery_email': recoveryEmail,
        'security_questions': securityQuestions,
        'notes': notes,
      };

  /// Get password (no encryption)
  String get password => encryptedPassword;

  /// Get notes (no encryption)
  String? get decryptedNotes => notes;
}

// --------------------------------------------------------------------
// 4. LoveLanguage Model
// --------------------------------------------------------------------
class LoveLanguage {
  final String id;
  final String userId;
  final String category; // service, quality_time, words, touch, gifts
  final List<String> whatWorks;
  final List<String> whatDoesnt;
  final double historicalSuccessRate;
  final String? notes;
  final List<String> examples;

  LoveLanguage({
    required this.id,
    required this.userId,
    required this.category,
    required this.whatWorks,
    required this.whatDoesnt,
    required this.historicalSuccessRate,
    this.notes,
    required this.examples,
  });

  factory LoveLanguage.fromJson(Map<String, dynamic> json) {
    return LoveLanguage(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      category: json['category'] as String,
      whatWorks: parseStringList(json['what_works']),
      whatDoesnt: parseStringList(json['what_doesnt']),
      historicalSuccessRate: parseDouble(json['historical_success_rate']),
      notes: json['notes'] as String?,
      examples: parseStringList(json['examples']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'category': category,
        'what_works': whatWorks,
        'what_doesnt': whatDoesnt,
        'historical_success_rate': historicalSuccessRate,
        'notes': notes,
        'examples': examples,
      };
}

// --------------------------------------------------------------------
// 5. ComfortGuideline Model (Comfort/Calm methods)
// --------------------------------------------------------------------
class ComfortGuideline {
  final String id;
  final String userId;
  final String comfortType; // 'comfort' or 'calm'
  final String trigger;
  final List<String> symptoms;
  final String? severity;
  final List<String> actionSteps;
  final List<String> recommendedResponses;
  final List<String> thingsToAvoid;
  final double successRating;
  final List<String> messagesToSend;
  final List<String> physicalMethods;
  final List<String> followUpActions;

  ComfortGuideline({
    required this.id,
    required this.userId,
    required this.comfortType,
    required this.trigger,
    required this.symptoms,
    this.severity,
    required this.actionSteps,
    required this.recommendedResponses,
    required this.thingsToAvoid,
    required this.successRating,
    required this.messagesToSend,
    required this.physicalMethods,
    required this.followUpActions,
  });

  factory ComfortGuideline.fromJson(Map<String, dynamic> json) {
    return ComfortGuideline(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      comfortType: json['comfort_type'] as String,
      trigger: json['trigger'] as String,
      symptoms: parseStringList(json['symptoms']),
      severity: json['severity'] as String?,
      actionSteps: parseStringList(json['action_steps']),
      recommendedResponses: parseStringList(json['recommended_responses']),
      thingsToAvoid: parseStringList(json['things_to_avoid']),
      successRating: parseDouble(json['success_rating']),
      messagesToSend: parseStringList(json['messages_to_send']),
      physicalMethods: parseStringList(json['physical_methods']),
      followUpActions: parseStringList(json['follow_up_actions']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'comfort_type': comfortType,
        'trigger': trigger,
        'symptoms': symptoms,
        'severity': severity,
        'action_steps': actionSteps,
        'recommended_responses': recommendedResponses,
        'things_to_avoid': thingsToAvoid,
        'success_rating': successRating,
        'messages_to_send': messagesToSend,
        'physical_methods': physicalMethods,
        'follow_up_actions': followUpActions,
      };
}

// --------------------------------------------------------------------
// 6. Preference Model
// --------------------------------------------------------------------
class Preference {
  final String id;
  final String userId;
  final String category;
  final String itemName;
  final int rating;
  final String? priority;
  final String? notes;

  Preference({
    required this.id,
    required this.userId,
    required this.category,
    required this.itemName,
    required this.rating,
    this.priority,
    this.notes,
  });

  factory Preference.fromJson(Map<String, dynamic> json) {
    return Preference(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      category: json['category'] as String,
      itemName: json['item_name'] as String,
      rating: json['rating'] as int? ?? 1,
      priority: json['priority'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'category': category,
        'item_name': itemName,
        'rating': rating,
        'priority': priority,
        'notes': notes,
      };
}

// --------------------------------------------------------------------
// 7. Memory Model
// --------------------------------------------------------------------
class Memory {
  final String id;
  final String userId;
  final String title;
  final String story;
  final DateTime memoryDate;
  final String? location;
  final String? mood;
  final int importanceScore;
  final List<String> tags;

  Memory({
    required this.id,
    required this.userId,
    required this.title,
    required this.story,
    required this.memoryDate,
    this.location,
    this.mood,
    required this.importanceScore,
    required this.tags,
  });

  factory Memory.fromJson(Map<String, dynamic> json) {
    return Memory(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      story: json['story'] as String,
      memoryDate: parseDate(json['memory_date']) ?? DateTime.now(),
      location: json['location'] as String?,
      mood: json['mood'] as String?,
      importanceScore: json['importance_score'] as int? ?? 5,
      tags: parseStringList(json['tags']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'story': story,
        'memory_date': memoryDate.toIso8601String(),
        'location': location,
        'mood': mood,
        'importance_score': importanceScore,
        'tags': tags,
      };
}

// --------------------------------------------------------------------
// 8. MediaItem Model
// --------------------------------------------------------------------
class MediaItem {
  final String id;
  final String userId;
  final String? memoryId;
  final String storagePath;
  final String mediaType;
  final String? albumName;
  final List<String> tags;

  MediaItem({
    required this.id,
    required this.userId,
    this.memoryId,
    required this.storagePath,
    required this.mediaType,
    this.albumName,
    required this.tags,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      memoryId: json['memory_id'] as String?,
      storagePath: json['storage_path'] as String,
      mediaType: json['media_type'] as String,
      albumName: json['album_name'] as String?,
      tags: parseStringList(json['tags']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'memory_id': memoryId,
        'storage_path': storagePath,
        'media_type': mediaType,
        'album_name': albumName,
        'tags': tags,
      };
}

// --------------------------------------------------------------------
// 9. RelationshipEvent Model
// --------------------------------------------------------------------
class RelationshipEvent {
  final String id;
  final String userId;
  final String title;
  final DateTime eventDate;
  final String eventType; // anniversary, monthsary, birthday, first_meeting...
  final bool countdownEnabled;

  RelationshipEvent({
    required this.id,
    required this.userId,
    required this.title,
    required this.eventDate,
    required this.eventType,
    required this.countdownEnabled,
  });

  factory RelationshipEvent.fromJson(Map<String, dynamic> json) {
    return RelationshipEvent(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      eventDate: parseDate(json['event_date']) ?? DateTime.now(),
      eventType: json['event_type'] as String,
      countdownEnabled: json['countdown_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'event_date': eventDate.toIso8601String(),
        'event_type': eventType,
        'countdown_enabled': countdownEnabled,
      };
}

// --------------------------------------------------------------------
// 10. PeriodRecord Model
// --------------------------------------------------------------------
class PeriodRecord {
  final String id;
  final String userId;
  final DateTime startDate;
  final DateTime? endDate;
  final List<String> symptoms;
  final String? mood;
  final String? flowLevel;
  final String? painLevel;
  final String? notes;

  PeriodRecord({
    required this.id,
    required this.userId,
    required this.startDate,
    this.endDate,
    required this.symptoms,
    this.mood,
    this.flowLevel,
    this.painLevel,
    this.notes,
  });

  factory PeriodRecord.fromJson(Map<String, dynamic> json) {
    return PeriodRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      startDate: parseDate(json['start_date']) ?? DateTime.now(),
      endDate: parseDate(json['end_date']),
      symptoms: parseStringList(json['symptoms']),
      mood: json['mood'] as String?,
      flowLevel: json['flow_level'] as String?,
      painLevel: json['pain_level'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'start_date': startDate.toIso8601String().split('T').first,
        'end_date': endDate?.toIso8601String().split('T').first,
        'symptoms': symptoms,
        'mood': mood,
        'flow_level': flowLevel,
        'pain_level': painLevel,
        'notes': notes,
      };
}

// --------------------------------------------------------------------
// 11. Quote Model
// --------------------------------------------------------------------
class Quote {
  final String id;
  final String userId;
  final String quote;
  final DateTime quoteDate;
  final String? context;
  final String? emotion;
  final String? significance;
  final List<String> tags;

  Quote({
    required this.id,
    required this.userId,
    required this.quote,
    required this.quoteDate,
    this.context,
    this.emotion,
    this.significance,
    required this.tags,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      quote: json['quote'] as String,
      quoteDate: parseDate(json['quote_date']) ?? DateTime.now(),
      context: json['context'] as String?,
      emotion: json['emotion'] as String?,
      significance: json['significance'] as String?,
      tags: parseStringList(json['tags']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'quote': quote,
        'quote_date': quoteDate.toIso8601String().split('T').first,
        'context': context,
        'emotion': emotion,
        'significance': significance,
        'tags': tags,
      };
}

// --------------------------------------------------------------------
// 12. ConflictLog Model
// --------------------------------------------------------------------
class ConflictLog {
  final String id;
  final String userId;
  final DateTime conflictDate;
  final String whatHappened;
  final String? emotionalImpact;
  final String? rootCause;
  final String? resolution;
  final String? lessonsLearned;
  final String? growthNotes;

  ConflictLog({
    required this.id,
    required this.userId,
    required this.conflictDate,
    required this.whatHappened,
    this.emotionalImpact,
    this.rootCause,
    this.resolution,
    this.lessonsLearned,
    this.growthNotes,
  });

  factory ConflictLog.fromJson(Map<String, dynamic> json) {
    return ConflictLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      conflictDate: parseDate(json['conflict_date']) ?? DateTime.now(),
      whatHappened: json['what_happened'] as String,
      emotionalImpact: json['emotional_impact'] as String?,
      rootCause: json['root_cause'] as String?,
      resolution: json['resolution'] as String?,
      lessonsLearned: json['lessons_learned'] as String?,
      growthNotes: json['growth_notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'conflict_date': conflictDate.toIso8601String().split('T').first,
        'what_happened': whatHappened,
        'emotional_impact': emotionalImpact,
        'root_cause': rootCause,
        'resolution': resolution,
        'lessons_learned': lessonsLearned,
        'growth_notes': growthNotes,
      };
}

// --------------------------------------------------------------------
// 13. SocialPerson Model (Social Matrix entries)
// --------------------------------------------------------------------
class SocialPerson {
  final String id;
  final String userId;
  final String name;
  final String relationshipType; // 'like' or 'dislike'
  final String? reasonOrStatus;
  final List<String> topicsOrGuidelines;
  final List<String> positiveTraits;

  SocialPerson({
    required this.id,
    required this.userId,
    required this.name,
    required this.relationshipType,
    this.reasonOrStatus,
    required this.topicsOrGuidelines,
    required this.positiveTraits,
  });

  factory SocialPerson.fromJson(Map<String, dynamic> json) {
    return SocialPerson(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      relationshipType: json['relationship_type'] as String,
      reasonOrStatus: json['reason_or_status'] as String?,
      topicsOrGuidelines: parseStringList(json['topics_or_guidelines']),
      positiveTraits: parseStringList(json['positive_traits']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'relationship_type': relationshipType,
        'reason_or_status': reasonOrStatus,
        'topics_or_guidelines': topicsOrGuidelines,
        'positive_traits': positiveTraits,
      };
}

// --------------------------------------------------------------------
// 14. Gift Model
// --------------------------------------------------------------------
class Gift {
  final String id;
  final String userId;
  final String giftIdea;
  final String status; // 'idea', 'purchased', 'gifted'
  final double budget;
  final String? reaction;
  final int successScore;
  final String? historyNotes;
  final DateTime? dateGifted;

  Gift({
    required this.id,
    required this.userId,
    required this.giftIdea,
    required this.status,
    required this.budget,
    this.reaction,
    required this.successScore,
    this.historyNotes,
    this.dateGifted,
  });

  factory Gift.fromJson(Map<String, dynamic> json) {
    return Gift(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      giftIdea: json['gift_idea'] as String,
      status: json['status'] as String? ?? 'idea',
      budget: parseDouble(json['budget']),
      reaction: json['reaction'] as String?,
      successScore: json['success_score'] as int? ?? 5,
      historyNotes: json['history_notes'] as String?,
      dateGifted: parseDate(json['date_gifted']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'gift_idea': giftIdea,
        'status': status,
        'budget': budget,
        'reaction': reaction,
        'success_score': successScore,
        'history_notes': historyNotes,
        'date_gifted': dateGifted?.toIso8601String().split('T').first,
      };
}

// --------------------------------------------------------------------
// 15. HealthWellness Model
// --------------------------------------------------------------------
class HealthWellness {
  final String id;
  final String userId;
  final List<String> allergies;
  final String? medicalNotes;
  final List<String> dietaryPreferences;
  final List<String> comfortFoods;
  final List<String> stressTriggers;
  final String? sleepNotes;
  final String? wellnessPreferences;

  HealthWellness({
    required this.id,
    required this.userId,
    required this.allergies,
    this.medicalNotes,
    required this.dietaryPreferences,
    required this.comfortFoods,
    required this.stressTriggers,
    this.sleepNotes,
    this.wellnessPreferences,
  });

  factory HealthWellness.fromJson(Map<String, dynamic> json) {
    return HealthWellness(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      allergies: parseStringList(json['allergies']),
      medicalNotes: json['medical_notes'] as String?,
      dietaryPreferences: parseStringList(json['dietary_preferences']),
      comfortFoods: parseStringList(json['comfort_foods']),
      stressTriggers: parseStringList(json['stress_triggers']),
      sleepNotes: json['sleep_notes'] as String?,
      wellnessPreferences: json['wellness_preferences'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'allergies': allergies,
        'medical_notes': medicalNotes,
        'dietary_preferences': dietaryPreferences,
        'comfort_foods': comfortFoods,
        'stress_triggers': stressTriggers,
        'sleep_notes': sleepNotes,
        'wellness_preferences': wellnessPreferences,
      };
}

// --------------------------------------------------------------------
// 16. TimelineEvent Model (Unified Feed Entity)
// --------------------------------------------------------------------
class TimelineEvent {
  final String id;
  final String userId;
  final String sourceTable; // memories, relationship_events, quote_vault...
  final String sourceId;
  final DateTime eventDate;
  final String title;
  final String? description;
  final String? mood;
  final List<String> tags;
  final int? importanceScore;

  TimelineEvent({
    required this.id,
    required this.userId,
    required this.sourceTable,
    required this.sourceId,
    required this.eventDate,
    required this.title,
    this.description,
    this.mood,
    required this.tags,
    this.importanceScore,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      sourceTable: json['source_table'] as String,
      sourceId: json['source_id'] as String,
      eventDate: parseDate(json['event_date']) ?? DateTime.now(),
      title: json['title'] as String,
      description: json['description'] as String?,
      mood: json['mood'] as String?,
      tags: parseStringList(json['tags']),
      importanceScore: json['importance_score'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'source_table': sourceTable,
        'source_id': sourceId,
        'event_date': eventDate.toIso8601String(),
        'title': title,
        'description': description,
        'mood': mood,
        'tags': tags,
        'importance_score': importanceScore,
      };
}

// --------------------------------------------------------------------
// 17. TimeBlock Model
// --------------------------------------------------------------------
class TimeBlock {
  final String id;
  final String ownerId;
  final String title;
  final String? description;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? category;
  final String? color;
  final bool completed;
  final bool recurring;
  final String? recurrenceRule;

  TimeBlock({
    required this.id,
    required this.ownerId,
    required this.title,
    this.description,
    this.startTime,
    this.endTime,
    this.category,
    this.color,
    this.completed = false,
    this.recurring = false,
    this.recurrenceRule,
  });

  factory TimeBlock.fromJson(Map<String, dynamic> json) {
    return TimeBlock(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startTime: parseDate(json['start_time']),
      endTime: parseDate(json['end_time']),
      category: json['category'] as String?,
      color: json['color'] as String?,
      completed: json['completed'] as bool? ?? false,
      recurring: json['recurring'] as bool? ?? false,
      recurrenceRule: json['recurrence_rule'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'title': title,
        'description': description,
        'start_time': startTime?.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'category': category,
        'color': color,
        'completed': completed,
        'recurring': recurring,
        'recurrence_rule': recurrenceRule,
      };
}

// --------------------------------------------------------------------
// 18. Task Model
// --------------------------------------------------------------------
class Task {
  final String id;
  final String ownerId;
  final String title;
  final String? description;
  final int priority; // 1 = Low, 2 = Medium, 3 = High, 4 = Critical
  final DateTime? dueDate;
  final bool completed;
  final DateTime? completedAt;

  Task({
    required this.id,
    required this.ownerId,
    required this.title,
    this.description,
    this.priority = 1,
    this.dueDate,
    this.completed = false,
    this.completedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: json['priority'] as int? ?? 1,
      dueDate: parseDate(json['due_date']),
      completed: json['completed'] as bool? ?? false,
      completedAt: parseDate(json['completed_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'title': title,
        'description': description,
        'priority': priority,
        'due_date': dueDate?.toIso8601String(),
        'completed': completed,
        'completed_at': completedAt?.toIso8601String(),
      };
}

// --------------------------------------------------------------------
// 19. GoalCategory Model
// --------------------------------------------------------------------
class GoalCategory {
  final String id;
  final String? ownerId;
  final String name;

  GoalCategory({
    required this.id,
    this.ownerId,
    required this.name,
  });

  factory GoalCategory.fromJson(Map<String, dynamic> json) {
    return GoalCategory(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String?,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'name': name,
      };
}

// --------------------------------------------------------------------
// 20. Goal Model
// --------------------------------------------------------------------
class Goal {
  final String id;
  final String? ownerId;
  final String? categoryId;
  final String title;
  final String? description;
  final DateTime? targetDate;
  final double progress;
  final String? status;

  Goal({
    required this.id,
    this.ownerId,
    this.categoryId,
    required this.title,
    this.description,
    this.targetDate,
    this.progress = 0.0,
    this.status,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String?,
      categoryId: json['category_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      targetDate: parseDate(json['target_date']),
      progress: parseDouble(json['progress']),
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'category_id': categoryId,
        'title': title,
        'description': description,
        'target_date': targetDate?.toIso8601String().split('T').first,
        'progress': progress,
        'status': status,
      };
}

// --------------------------------------------------------------------
// 21. GoalMilestone Model
// --------------------------------------------------------------------
class GoalMilestone {
  final String id;
  final String? goalId;
  final String? title;
  final bool completed;
  final DateTime? completedAt;

  GoalMilestone({
    required this.id,
    this.goalId,
    this.title,
    this.completed = false,
    this.completedAt,
  });

  factory GoalMilestone.fromJson(Map<String, dynamic> json) {
    return GoalMilestone(
      id: json['id'] as String,
      goalId: json['goal_id'] as String?,
      title: json['title'] as String?,
      completed: json['completed'] as bool? ?? false,
      completedAt: parseDate(json['completed_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'goal_id': goalId,
        'title': title,
        'completed': completed,
        'completed_at': completedAt?.toIso8601String(),
      };
}

// --------------------------------------------------------------------
// 22. Habit Model
// --------------------------------------------------------------------
class Habit {
  final String id;
  final String? ownerId;
  final String? title;
  final String? description;
  final int? targetFrequency;
  final int streak;

  Habit({
    required this.id,
    this.ownerId,
    this.title,
    this.description,
    this.targetFrequency,
    this.streak = 0,
  });

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      targetFrequency: json['target_frequency'] as int?,
      streak: json['streak'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'title': title,
        'description': description,
        'target_frequency': targetFrequency,
        'streak': streak,
      };
}

// --------------------------------------------------------------------
// 23. HabitLog Model
// --------------------------------------------------------------------
class HabitLog {
  final String id;
  final String? habitId;
  final DateTime? completedDate;

  HabitLog({
    required this.id,
    this.habitId,
    this.completedDate,
  });

  factory HabitLog.fromJson(Map<String, dynamic> json) {
    return HabitLog(
      id: json['id'] as String,
      habitId: json['habit_id'] as String?,
      completedDate: parseDate(json['completed_date']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'habit_id': habitId,
        'completed_date': completedDate?.toIso8601String().split('T').first,
      };
}

// --------------------------------------------------------------------
// 24. Routine Model
// --------------------------------------------------------------------
class Routine {
  final String id;
  final String? ownerId;
  final String? title;
  final String? routineType; // 'Morning', 'Afternoon', 'Evening', 'Night'

  Routine({
    required this.id,
    this.ownerId,
    this.title,
    this.routineType,
  });

  factory Routine.fromJson(Map<String, dynamic> json) {
    return Routine(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String?,
      title: json['title'] as String?,
      routineType: json['routine_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'title': title,
        'routine_type': routineType,
      };
}

// --------------------------------------------------------------------
// 25. RoutineStep Model
// --------------------------------------------------------------------
class RoutineStep {
  final String id;
  final String? routineId;
  final int? stepOrder;
  final String? title;
  final int? estimatedMinutes;

  RoutineStep({
    required this.id,
    this.routineId,
    this.stepOrder,
    this.title,
    this.estimatedMinutes,
  });

  factory RoutineStep.fromJson(Map<String, dynamic> json) {
    return RoutineStep(
      id: json['id'] as String,
      routineId: json['routine_id'] as String?,
      stepOrder: json['step_order'] as int?,
      title: json['title'] as String?,
      estimatedMinutes: json['estimated_minutes'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'routine_id': routineId,
        'step_order': stepOrder,
        'title': title,
        'estimated_minutes': estimatedMinutes,
      };
}

// --------------------------------------------------------------------
// 26. FocusSession Model
// --------------------------------------------------------------------
class FocusSession {
  final String id;
  final String? ownerId;
  final String? title;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final int? productivityScore;
  final String? notes;

  FocusSession({
    required this.id,
    this.ownerId,
    this.title,
    this.startTime,
    this.endTime,
    this.durationMinutes,
    this.productivityScore,
    this.notes,
  });

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String?,
      title: json['title'] as String?,
      startTime: parseDate(json['start_time']),
      endTime: parseDate(json['end_time']),
      durationMinutes: json['duration_minutes'] as int?,
      productivityScore: json['productivity_score'] as int?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'title': title,
        'start_time': startTime?.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'duration_minutes': durationMinutes,
        'productivity_score': productivityScore,
        'notes': notes,
      };
}

// --------------------------------------------------------------------
// 27. DailyReflection Model
// --------------------------------------------------------------------
class DailyReflection {
  final String id;
  final String? ownerId;
  final DateTime reflectionDate;
  final String? wins;
  final String? challenges;
  final String? gratitude;
  final String? lessonsLearned;
  final int? mood;

  DailyReflection({
    required this.id,
    this.ownerId,
    required this.reflectionDate,
    this.wins,
    this.challenges,
    this.gratitude,
    this.lessonsLearned,
    this.mood,
  });

  factory DailyReflection.fromJson(Map<String, dynamic> json) {
    return DailyReflection(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String?,
      reflectionDate: parseDate(json['reflection_date']) ?? DateTime.now(),
      wins: json['wins'] as String?,
      challenges: json['challenges'] as String?,
      gratitude: json['gratitude'] as String?,
      lessonsLearned: json['lessons_learned'] as String?,
      mood: json['mood'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'reflection_date': reflectionDate.toIso8601String().split('T').first,
        'wins': wins,
        'challenges': challenges,
        'gratitude': gratitude,
        'lessons_learned': lessonsLearned,
        'mood': mood,
      };
}

// --------------------------------------------------------------------
// 28. TimeLog Model (Advanced Analytics)
// --------------------------------------------------------------------
class TimeLog {
  final String id;
  final String? ownerId;
  final String? category;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? durationMinutes;

  TimeLog({
    required this.id,
    this.ownerId,
    this.category,
    this.startedAt,
    this.endedAt,
    this.durationMinutes,
  });

  factory TimeLog.fromJson(Map<String, dynamic> json) {
    return TimeLog(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String?,
      category: json['category'] as String?,
      startedAt: parseDate(json['started_at']),
      endedAt: parseDate(json['ended_at']),
      durationMinutes: json['duration_minutes'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'category': category,
        'started_at': startedAt?.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
        'duration_minutes': durationMinutes,
      };
}

