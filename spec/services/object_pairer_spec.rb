require 'rails_helper'

RSpec.describe ObjectPairer do
  subject { ObjectPairer.new(objects: objects, identical_attributes: identical_attributes, pairing_criteria: pairing_criteria) }
  let(:live_time_1) { build_stubbed(:live_time, bib_number: 10, split_id: 101, bitkey: 1) }
  let(:live_time_2) { build_stubbed(:live_time, bib_number: 10, split_id: 101, bitkey: 64) }
  let(:live_time_3) { build_stubbed(:live_time, bib_number: 11, split_id: 101, bitkey: 1) }
  let(:live_time_4) { build_stubbed(:live_time, bib_number: 11, split_id: 101, bitkey: 64) }
  let(:live_time_5) { build_stubbed(:live_time, bib_number: 10, split_id: 102, bitkey: 1) }
  let(:live_time_6) { build_stubbed(:live_time, bib_number: 10, split_id: 102, bitkey: 64) }
  let(:live_time_7) { build_stubbed(:live_time, bib_number: 10, split_id: 101, bitkey: 64) }

  describe '#pair' do
    context 'when all objects can be paired' do
      let(:objects) { [live_time_1, live_time_2, live_time_3, live_time_4] }
      let(:identical_attributes) { [:bib_number] }
      let(:pairing_criteria) { [{split_id: 101, bitkey: 1}, {split_id: 101, bitkey: 64}] }

      it 'returns an array of paired object arrays' do
        expected = [[live_time_1, live_time_2], [live_time_3, live_time_4]]
        expect(subject.pair).to eq(expected)
      end
    end

    context 'when objects have more than one pairing possibility' do
      let(:objects) { [live_time_1, live_time_2, live_time_3, live_time_4, live_time_7] }
      let(:identical_attributes) { [:bib_number] }
      let(:pairing_criteria) { [{split_id: 101, bitkey: 1}, {split_id: 101, bitkey: 64}] }

      it 'returns an array of paired object arrays and pairs the additional object with nil' do
        expected = [[live_time_1, live_time_2], [nil, live_time_7], [live_time_3, live_time_4]]
        expect(subject.pair).to eq(expected)
      end
    end

    context 'when no objects can be paired' do
      let(:objects) { [live_time_1, live_time_4, live_time_5, live_time_6] }
      let(:identical_attributes) { [:bib_number] }
      let(:pairing_criteria) { [{split_id: 101, bitkey: 1}, {split_id: 101, bitkey: 64}] }

      it 'returns an array of objects paired with nils' do
        expected = [[live_time_1, nil], [nil, live_time_4]]
        p subject.pair
        expect(subject.pair).to eq(expected)
      end
    end

    context 'when no objects match the pairing criteria' do
      let(:objects) { [live_time_1, live_time_2, live_time_3, live_time_4] }
      let(:identical_attributes) { [:bib_number] }
      let(:pairing_criteria) { [{split_id: 102, bitkey: 1}, {split_id: 102, bitkey: 64}] }

      it 'returns an empty array' do
        expected = []
        expect(subject.pair).to eq(expected)
      end
    end
  end
end
