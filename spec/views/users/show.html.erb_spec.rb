require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  context 'the user sees his page' do
    before(:each) do
      # Создание объектов для теста
      user = FactoryBot.create(:user, name: 'Grognak')
      sign_in user
      assign(:user, user )
      assign(:games, [FactoryBot.build_stubbed(:game, id: 2, created_at: Time.now, current_level: 5)])
      render
    end
    
    it 'does render user name' do
      expect(rendered).to match 'Grognak'
    end
    
    it 'does render btn for pswd change' do
      expect(rendered).to match 'Сменить имя и пароль'
    end

    it 'does render game' do
      expect(rendered).to render_template 'users/_game'
    end
  end
  
  context 'the user sees another users page' do
    before(:each) do
      assign(:user, FactoryBot.build_stubbed(:user, name: 'Grognak'))
      assign(:games, [FactoryBot.build_stubbed(:game, id: 3, created_at: Time.now, current_level: 12)])
    
      render
    end

    it 'does render user name' do
      expect(rendered).to match 'Grognak'
    end

    it 'does not render btn for pswd change' do
      expect(rendered).not_to match 'Сменить имя и пароль'
    end

    it 'does render game' do
      expect(rendered).to render_template 'users/_game'
    end
  end
end