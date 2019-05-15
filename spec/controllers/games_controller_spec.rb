require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe GamesController, type: :controller do
  # Обычный пользователь
  let(:user) { FactoryBot.create(:user) }
  # Админ
  let(:admin) { FactoryBot.create(:user, is_admin: true) }
  # Игра с прописанными игровыми вопросвми
  let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user) }
  
  # Группа тестов для незалогиненного юзера (Анонимус)
  context 'Anon' do
    # Из экшена show анона посылаем
    it 'kicks from #show' do
      # вызываем экшен
      get :show, id: game_w_questions.id
      # проверяем ответ
      expect(response.status).not_to eq(200) # статус не 200 ОК
      expect(response).to redirect_to(new_user_session_path) # devise должен отправить на логин
      expect(flash[:alert]).to be # во flash должен быть прописана ошибка
    end
  end
  
  # Группа тестов на экшены контроллера, доступных залогиненным юзерам
  context 'Usual user' do
    # Хелпер devise before, перед каждым тестом в группе
    before(:each) { sign_in user } # логиним юзера user с помощью спец. Devise метода sign_in

    # юзер может создать новую игру
    it 'creates game' do
      generate_questions(15)
      
      post :create
      game = assigns(:game) # вытаскиваем из контроллера поле @game
  
      # проверяем состояние этой игры
      expect(game.finished?).to be_falsey
      expect(game.user).to eq(user)
      # и редирект на страницу этой игры
      expect(response).to redirect_to game_path(game)
      expect(flash[:notice]).to be
    end
    
    # Юзер видит свою игру
    it '#show game' do
      get :show, id: game_w_questions.id
      game = assigns(:game) # вытаскиваем из контроллера поле @game
      expect(game.finished?).to be_falsey
      expect(game.user).to eq(user)

      expect(response.status).to eq(200) # должен быть ответ HTTP 200
      expect(response).to render_template('show') # и отрендерить шаблон show
    end

    # Юзер отвечает на игру корректно - игра продолжается
    it 'answer correct' do
      # передаем параметр params[:letter]
      put :answer, id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key
      game = assigns(:game)

      expect(game.finished?).to be_falsey
      expect(game.current_level).to be > 0
      expect(response).to redirect_to(game_path(game))
      expect(flash.empty?).to be_truthy # удачный ответ не заполняет flash
    end
    
    # Проверка, что пользовтеля посылают из чужой игры
    it '#show alien game' do
      # Создаем новую игру, юзер не прописан, будет создан фабрикой новый
      alien_game = FactoryBot.create(:game_with_questions)
      # Пробуем зайти на эту игру текущий залогиненным user
      get :show, id: alien_game.id

      expect(response.status).not_to eq(200) # статус не 200 ОК
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be # во flash должен быть прописана ошибка
    end
  end
end
