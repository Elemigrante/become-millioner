require 'rails_helper'

RSpec.feature 'USER viewing someones profile', type: :feature do
  # Создаём объект пользователь в базе для теста
  let(:user1) { FactoryBot.create :user, id: 1, name: 'Grognak' }
  let(:user2) { FactoryBot.create :user, id: 2, name: 'Konan' }
  
  # А также объект игры
  let!(:games) do
    [
      FactoryBot.create(:game,
                        id: 1,
                        user: user2,
                        created_at: Time.parse('2019.05.09, 13:00'),
                        prize: 1000
      ),

      FactoryBot.create(:game,
                        id: 2,
                        user: user2,
                        created_at: Time.parse('2019.05.09, 14:00'),
                        prize: 2000
      )
     ]
  end
  
  # Перед началом сценария, авторизовываем пользователя
  before(:each) do
    login_as user1
  end
  
  # Сценарий успешного просмотра профиля
  scenario 'successfully' do
    # Заходим на главную
    visit '/'
    
    # Кликаем на ссылку с именем пользователя
    click_link 'Konan'
    
    # Ожидаем, что попадем на нужный url
    expect(page).to have_current_path("/users/2")
    
    # Имя пользователя
    expect(page).to have_content('Konan')
    
    # Ожидаем, что на экране не будет ссылки на смену пароля
    expect(page).not_to have_content('Сменить имя и пароль')
    
    # Ожидаем, что на экране будет:
    expect(page).to have_content('1 в процессе 09 мая, 13:00 0 1 000 ₽ 50/50')
    expect(page).to have_content('2 в процессе 09 мая, 14:00 0 2 000 ₽ 50/50')

  end
end