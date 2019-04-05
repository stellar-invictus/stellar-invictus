require 'rails_helper'

RSpec.describe NpcsController, type: :controller do
  describe 'without login' do
    describe 'POST target' do
      it 'should redirect to new session path' do
        post :target
        expect(response.status).to eq(302)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'with login' do
    before(:each) do
      @user = create(:user_with_faction)
      sign_in @user
      @enemy = create(:npc, location: @user.location, hp: 100)
    end

    describe 'POST target' do
      it 'should target npc if user is in same location and can be attacked' do
        post :target, params: { id: @enemy.id }
        expect(response).to have_http_status(:ok)
        expect(TargetNpcWorker.jobs.size).to eq(1)
      end

      it 'should not target npc if user is in warp' do
        @user.update(in_warp: true)
        post :target, params: { id: @enemy.id }
        expect(response).to have_http_status(:bad_request)
        expect(TargetNpcWorker.jobs.size).to eq(0)
      end

      it 'should not target npc if npc is not found' do
        post :target, params: { id: 2000 }
        expect(response).to have_http_status(:bad_request)
        expect(TargetNpcWorker.jobs.size).to eq(0)
      end

      it 'should not target npc if npc is in another location' do
        @enemy.update(location_id: Location.last.id)
        post :target, params: { id: @enemy.id }
        expect(response).to have_http_status(:bad_request)
        expect(TargetNpcWorker.jobs.size).to eq(0)
      end
    end

    describe 'POST untarget' do
      it 'should remove npc_target_id and is_attacking' do
        @enemy.update(location_id: Location.last.id)
        @user.update(npc_target_id: @enemy.id, is_attacking: true)
        post :untarget
        expect(response).to have_http_status(:ok)
        expect(@user.reload.npc_target_id).to eq(nil)
        expect(@user.is_attacking).to eq(false)
      end
    end
  end
end
