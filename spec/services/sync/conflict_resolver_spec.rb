# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sync::ConflictResolver do
  let(:synced_at) { Time.zone.parse("2026-02-15 10:00:00") }

  describe ".resolve" do
    it "returns :pull when only external changed" do
      result = described_class.resolve(
        ext_updated_at: synced_at + 1.hour,
        local_updated_at: synced_at - 1.hour,
        synced_at: synced_at
      )

      expect(result).to eq(:pull)
    end

    it "returns :push when only local changed" do
      result = described_class.resolve(
        ext_updated_at: synced_at - 1.hour,
        local_updated_at: synced_at + 1.hour,
        synced_at: synced_at
      )

      expect(result).to eq(:push)
    end

    it "returns :none when neither side changed" do
      result = described_class.resolve(
        ext_updated_at: synced_at - 1.hour,
        local_updated_at: synced_at - 1.hour,
        synced_at: synced_at
      )

      expect(result).to eq(:none)
    end

    it "returns :pull when both changed and external is newer" do
      result = described_class.resolve(
        ext_updated_at: synced_at + 2.hours,
        local_updated_at: synced_at + 1.hour,
        synced_at: synced_at
      )

      expect(result).to eq(:pull)
    end

    it "returns :push when both changed and local is newer" do
      result = described_class.resolve(
        ext_updated_at: synced_at + 1.hour,
        local_updated_at: synced_at + 2.hours,
        synced_at: synced_at
      )

      expect(result).to eq(:push)
    end

    it "returns :pull when both changed at the same time (external wins ties)" do
      same_time = synced_at + 1.hour
      result = described_class.resolve(
        ext_updated_at: same_time,
        local_updated_at: same_time,
        synced_at: synced_at
      )

      expect(result).to eq(:pull)
    end
  end
end
