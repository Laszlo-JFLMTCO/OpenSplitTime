require 'rails_helper'

RSpec.describe ComputeDataEntryNodes do
  let(:distance_threshold) { ComputeDataEntryNodes::SPLIT_DISTANCE_THRESHOLD }

  describe '#perform' do
    subject { ComputeDataEntryNodes.new(event_group) }

    let(:event_group) { build_stubbed(:event_group, events: [event_1, event_2]) }
    let(:event_1) { build_stubbed(:event, splits: event_1_splits, aid_stations: event_1_aid_stations) }
    let(:event_2) { build_stubbed(:event, splits: event_2_splits, aid_stations: event_2_aid_stations) }

    let(:event_1_split_1) { build_stubbed(:start_split, base_name: 'Start') }
    let(:event_1_split_2) { build_stubbed(:split, base_name: 'Aid 1') }
    let(:event_1_split_3) { build_stubbed(:split, base_name: 'Aid 2') }
    let(:event_1_split_4) { build_stubbed(:finish_split, base_name: 'Finish') }

    let(:event_1_aid_1) { build_stubbed(:aid_station, split: event_1_split_1) }
    let(:event_1_aid_2) { build_stubbed(:aid_station, split: event_1_split_2) }
    let(:event_1_aid_3) { build_stubbed(:aid_station, split: event_1_split_3) }
    let(:event_1_aid_4) { build_stubbed(:aid_station, split: event_1_split_4) }

    let(:event_2_split_1) { build_stubbed(:start_split, base_name: 'Start') }
    let(:event_2_split_2) { build_stubbed(:split, base_name: 'Aid 2') }
    let(:event_2_split_3) { build_stubbed(:finish_split, base_name: 'Finish') }

    let(:event_2_aid_1) { build_stubbed(:aid_station, split: event_2_split_1) }
    let(:event_2_aid_2) { build_stubbed(:aid_station, split: event_2_split_2) }
    let(:event_2_aid_3) { build_stubbed(:aid_station, split: event_2_split_3) }

    let(:event_1_splits) { [event_1_split_1, event_1_split_2, event_1_split_3, event_1_split_4] }
    let(:event_2_splits) { [event_2_split_1, event_2_split_2, event_2_split_3] }

    let(:event_1_aid_stations) { [event_1_aid_1, event_1_aid_2, event_1_aid_3, event_1_aid_4] }
    let(:event_2_aid_stations) { [event_2_aid_1, event_2_aid_2, event_2_aid_3] }


    context 'when splits with matching names have matching sub_splits' do

      it 'returns a Struct having a title and data_entry_nodes' do
        data_entry_nodes = subject.perform
        expect(data_entry_nodes.map(&:split_name)).to eq(%w(start aid-1 aid-1 aid-2 aid-2 finish))
        expect(data_entry_nodes.map(&:sub_split_kind)).to eq(%w(in in out in out in))
        expect(data_entry_nodes.map(&:label)).to eq(['Start', 'Aid 1 In', 'Aid 1 Out', 'Aid 2 In', 'Aid 2 Out', 'Finish'])
        expect(data_entry_nodes.first.event_split_ids).to eq({event_1.id => event_1_split_1.id, event_2.id => event_2_split_1.id})
        expect(data_entry_nodes.first.event_aid_station_ids).to eq({event_1.id => event_1_aid_1.id, event_2.id => event_2_aid_1.id})
      end
    end

    context 'when splits with matching names have non-matching sub_splits' do
      let(:event_1_split_3) { build_stubbed(:split, base_name: 'Aid 2', sub_split_bitmap: 65) }
      let(:event_2_split_2) { build_stubbed(:split, base_name: 'Aid 2', sub_split_bitmap: 1) }

      it 'ignores the difference but returns a Struct having a title and data_entry_nodes' do
        data_entry_nodes = subject.perform
        expect(data_entry_nodes.map(&:split_name)).to eq(%w(start aid-1 aid-1 aid-2 aid-2 finish))
        expect(data_entry_nodes.map(&:sub_split_kind)).to eq(%w(in in out in out in))
        expect(data_entry_nodes.map(&:label)).to eq(['Start', 'Aid 1 In', 'Aid 1 Out', 'Aid 2 In', 'Aid 2 Out', 'Finish'])
      end
    end

    context 'when splits with matching names have matching sub_splits and identical locations' do
      let(:event_1_split_3) { build_stubbed(:split, base_name: 'Aid 2', latitude: 40, longitude: -105) }
      let(:event_2_split_2) { build_stubbed(:split, base_name: 'Aid 2', latitude: 40, longitude: -105) }

      it 'returns a Struct having a title and data_entry_nodes with latitudes and longitudes' do
        data_entry_nodes = subject.perform
        expect(data_entry_nodes.map(&:split_name)).to eq(%w(start aid-1 aid-1 aid-2 aid-2 finish))
        expect(data_entry_nodes.map(&:sub_split_kind)).to eq(%w(in in out in out in))
        expect(data_entry_nodes.map(&:label)).to eq(['Start', 'Aid 1 In', 'Aid 1 Out', 'Aid 2 In', 'Aid 2 Out', 'Finish'])
        expect(data_entry_nodes.map(&:latitude)).to eq([nil, nil, nil, 40.0, 40.0, nil])
        expect(data_entry_nodes.map(&:longitude)).to eq([nil, nil, nil, -105.0, -105.0, nil])
      end
    end

    context 'when splits with matching names have matching sub_splits and locations within tolerance' do
      let(:event_1_split_3) { build_stubbed(:split, base_name: 'Aid 2', latitude: 40, longitude: -105) }
      let(:event_2_split_2) { build_stubbed(:split, base_name: 'Aid 2', latitude: 40.0001, longitude: -105.0001) }

      it 'returns a Struct having a title and data_entry_nodes with average latitudes and longitudes' do
        data_entry_nodes = subject.perform
        expect(event_1_split_3.distance_from(event_2_split_2)).to be < distance_threshold
        expect(data_entry_nodes.map(&:split_name)).to eq(%w(start aid-1 aid-1 aid-2 aid-2 finish))
        expect(data_entry_nodes.map(&:sub_split_kind)).to eq(%w(in in out in out in))
        expect(data_entry_nodes.map(&:label)).to eq(['Start', 'Aid 1 In', 'Aid 1 Out', 'Aid 2 In', 'Aid 2 Out', 'Finish'])
        expect(data_entry_nodes.map(&:latitude)).to eq([nil, nil, nil, 40.00005, 40.00005, nil])
        expect(data_entry_nodes.map(&:longitude)).to eq([nil, nil, nil, -105.00005, -105.00005, nil])
      end
    end

    context 'when splits with matching names have matching sub_splits but locations outside tolerance' do
      let(:event_1_split_3) { build_stubbed(:split, base_name: 'Aid 2', latitude: 40, longitude: -105) }
      let(:event_2_split_2) { build_stubbed(:split, base_name: 'Aid 2', latitude: 40.1, longitude: -105.1) }

      it 'returns an empty array' do
        data_entry_nodes = subject.perform
        expect(event_1_split_3.distance_from(event_2_split_2)).to be > distance_threshold
        expect(data_entry_nodes).to eq([])
      end
    end
  end
end
