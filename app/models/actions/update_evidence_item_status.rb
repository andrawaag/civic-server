module Actions
  class UpdateEvidenceItemStatus
    include Actions::Transactional
    attr_reader :evidence_item, :originating_user, :new_status

    def initialize(evidence_item, originating_user, new_status)
      @evidence_item = evidence_item
      @originating_user = originating_user
      @new_status = new_status
    end

    private
    def execute
      evidence_item.lock!
      if evidence_item.status != new_status
        update_source_status
        evidence_item.status = new_status
        evidence_item.save!
        Event.create(
          action: new_status,
          originating_user: originating_user,
          subject: evidence_item
        )
        evidence_item.subscribe_user(originating_user)
      else
        errors << "Attempted to update to status #{new_status} but it was already completed"
      end
    end

    def update_source_status
      conditions = [
        new_status == 'accepted',
        evidence_item_count_for_source == 0,
        evidence_item.source.status == 'submitted'
      ]

      if conditions.all?
        evidence_item.source.status = 'partially curated'
        evidence_item.source.save
      end
    end

    def evidence_item_count_for_source
      evidence_item.source.evidence_items.where(status: 'accepted').count
    end
  end
end
