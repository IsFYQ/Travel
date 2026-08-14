/// P1-3.3：领域事件定义
sealed class DomainEvent {
  const DomainEvent();
}

class RecordSaved extends DomainEvent {
  final String recordId;
  const RecordSaved(this.recordId);
}

class RecordDeleted extends DomainEvent {
  final String recordId;
  const RecordDeleted(this.recordId);
}

class RecordHidden extends DomainEvent {
  final String recordId;
  final bool hidden;
  const RecordHidden(this.recordId, this.hidden);
}

class ItineraryCreated extends DomainEvent {
  final String itineraryId;
  const ItineraryCreated(this.itineraryId);
}

class ItineraryStatusChanged extends DomainEvent {
  final String itineraryId;
  const ItineraryStatusChanged(this.itineraryId);
}

class ItineraryItemRated extends DomainEvent {
  final String itineraryId;
  const ItineraryItemRated(this.itineraryId);
}

class ProfileDeclaredChanged extends DomainEvent {
  const ProfileDeclaredChanged();
}

class SyncCompleted extends DomainEvent {
  const SyncCompleted();
}
