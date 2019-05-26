require 'rails_helper'

RSpec.feature 'USER viewing someones profile', type: :feature do
  # Создаём объект пользователь в базе для теста
  let(:user1) { FactoryBot.create :user, name: 'Grognak' }
  let(:user2) { FactoryBot.create :user, name: 'Konan' }
  
  # А также объект игры
  let!(:games) do
    [
      FactoryBot.create(:game,
                        id: 11,
                        user: user2,
                        created_at: Time.parse('2019.05.09, 13:00'),
                        current_level: 2,
                        prize: 1000),
      
      FactoryBot.create(:game,
                        id: 12,
                        user: user2,
                        created_at: Time.parse('2019.05.09, 15:00'),
                        current_level: 4,
                        prize: 4000)
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
    expect(page).to have_current_path("/users/1")
    
    # Ожидаем, что на экране не будет ссылки на смену пароля
    expect(page).not_to have_content('Сменить имя и пароль')
    
    # Ожидаем, что на экране будет:
    #
    # Имя пользователя
    expect(page).to have_content('Konan')
    # id игры
    expect(page).to have_content('11')
    # Дата создания игры
    expect(page).to have_content('09 мая, 13:00')
    # Уровень игры
    expect(page).to have_content('2')
    # Приз за игру
    expect(page).to have_content('1 000')

    expect(page).to have_content('12')
    expect(page).to have_content('09 мая, 15:00')
    expect(page).to have_content('4')
    expect(page).to have_content('4 000')
  end
end