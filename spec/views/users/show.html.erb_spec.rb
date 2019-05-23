require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  context 'user page' do
    before(:each) do
      # Создание объектов для теста
      assign(:user, FactoryBot.create(:user, name: 'Grognak') )
      assign(:games, [FactoryBot.build_stubbed(:game, id: 2, created_at: Time.now, current_level: 5)])
      
      render
    end
    
    it 'does render user name' do
      expect(rendered).to match 'Grognak'
    end
    
    it 'does render btn for pswd change' do
      expect(rendered).not_to match 'Сменить имя и пароль'
    end
    
    it 'does render game' do
      expect(rendered).to render_template 'users/_game'
    end
  end
end