require 'rails_helper'

RSpec.describe Api::V1::CoursesController do
  let(:course) { create(:course) }
  let(:type) { 'courses' }

  describe '#index' do
    subject(:make_request) { get :index, params: params }
    let(:params) { {} }

    before do
      create(:course, name: 'Bravo', description: 'Fabulous')
      create(:course, name: 'Charlie', description: 'Beautiful')
      create(:course, name: 'Alpha', description: 'Beautiful')
      create(:course, name: 'Delta', description: 'Gorgeous')
    end

    via_login_and_jwt do
      it 'returns a successful 200 response' do
        make_request
        expect(response.status).to eq(200)
      end

      it 'returns each course' do
        make_request
        expect(response.status).to eq(200)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['data'].size).to eq(4)
        expect(parsed_response['data'].map { |item| item['id'].to_i }).to eq(Course.all.map(&:id))
      end

      context 'when a sort parameter is provided' do
        let(:params) { {sort: 'name'} }

        it 'sorts properly in ascending order based on the parameter' do
          make_request
          expected = %w(Alpha Bravo Charlie Delta)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data'].map { |item| item.dig('attributes', 'name') }).to eq(expected)
        end
      end

      context 'when a negative sort parameter is provided' do
        let(:params) { {sort: '-name'} }

        it 'sorts properly in descending order based on the parameter' do
          make_request
          expected = %w(Delta Charlie Bravo Alpha)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data'].map { |item| item.dig('attributes', 'name') }).to eq(expected)
        end
      end

      context 'when multiple sort parameters are provided' do
        let(:params) { {sort: 'description,name'} }

        it 'sorts properly on multiple fields' do
          make_request
          expected = %w(Alpha Charlie Bravo Delta)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data'].map { |item| item.dig('attributes', 'name') }).to eq(expected)
        end
      end
    end
  end

  describe '#show' do
    subject(:make_request) { get :show, params: params }

    via_login_and_jwt do
      context 'when an existing course.id is provided' do
        let(:params) { {id: course} }

        it 'returns a successful 200 response' do
          make_request
          expect(response.status).to eq(200)
        end

        it 'returns data of a single course' do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data']['id'].to_i).to eq(course.id)
          expect(response.body).to be_jsonapi_response_for(type)
        end
      end

      context 'if the course does not exist' do
        let(:params) { {id: 0} }

        it 'returns an error' do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['errors']).to include(/not found/)
          expect(response.status).to eq(404)
        end
      end
    end
  end

  describe '#create' do
    subject(:make_request) { post :create, params: params }

    via_login_and_jwt do
      context 'when provided data is valid' do
        let(:params) { {data: {type: type, attributes: {name: 'Test Course'}}} }

        it 'returns a successful json response' do
          make_request
          expect(response.body).to be_jsonapi_response_for(type)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['data']['id']).not_to be_nil
          expect(response.status).to eq(201)
        end

        it 'creates a course record' do
          expect(Course.all.count).to eq(0)
          make_request
          expect(Course.all.count).to eq(1)
        end
      end
    end
  end

  describe '#update' do
    subject(:make_request) { put :update, params: params }
    let(:params) { {id: course_id, data: {type: type, attributes: attributes}} }
    let(:attributes) { {name: 'Updated Course Name'} }

    via_login_and_jwt do
      context 'when the course exists' do
        let(:course_id) { course.id }

        it 'returns a successful json response' do
          make_request
          expect(response.body).to be_jsonapi_response_for(type)
          expect(response.status).to eq(200)
        end

        it 'updates the specified fields' do
          make_request
          course.reload
          expect(course.name).to eq(attributes[:name])
        end
      end

      context 'when the course does not exist' do
        let(:course_id) { 0 }

        it 'returns an error if the course does not exist' do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['errors']).to include(/not found/)
          expect(response.status).to eq(404)
        end
      end
    end
  end

  describe '#destroy' do
    subject(:make_request) { delete :destroy, params: {id: course_id} }

    via_login_and_jwt do
      context 'when the record exists' do
        let!(:course) { create(:course) }
        let(:course_id) { course.id }

        it 'returns a successful json response' do
          make_request
          expect(response.status).to eq(200)
        end

        it 'destroys the course record' do
          expect(Course.all.count).to eq(1)
          make_request
          expect(Course.all.count).to eq(0)
        end
      end

      context 'when the record does not exist' do
        let(:course_id) { 0 }

        it 'returns an error if the course does not exist' do
          make_request
          parsed_response = JSON.parse(response.body)
          expect(parsed_response['errors']).to include(/not found/)
          expect(response.status).to eq(404)
        end
      end
    end
  end
end
