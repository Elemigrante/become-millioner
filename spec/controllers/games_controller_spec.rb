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
    
    # Аноним не может создать игру
    it 'does not create game' do
      generate_questions(15)
      post :create
      
      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end
    
    # Аноним не может ответить на вопрос
    it 'does not answer the question ' do
      put :answer, id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key
      
      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end
    
    it 'does not take money' do
      put :take_money, id: game_w_questions.id
      
      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
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
    
    # Проверка ситуации, когда пользователь берет деньги до конца игры
    it 'take money before end game' do
      # вручную поднимем уровень вопроса до выигрыша 200
      game_w_questions.update_attribute(:current_level, 2)
      
      put :take_money, id: game_w_questions.id
      game = assigns(:game)
      expect(game.finished?).to be_truthy
      expect(game.prize).to eq(200)
      
      # пользователь изменился в базе, надо в коде перезагрузить!
      user.reload
      expect(user.balance).to eq(200)
      
      expect(response).to redirect_to(user_path(user))
      expect(flash[:warning]).to be
    end
    
    #  Порверка, что пользователь не может начать две игры. Если он начинает вторую, его редиректит на первую.
    it 'try to create second game' do
      # убедились что есть игра в работе
      expect(game_w_questions.finished?).to be_falsey
      
      # отправляем запрос на создание, убеждаемся что новых Game не создалось
      expect { post :create }.to change(Game, :count).by(0)
      
      game = assigns(:game) # вытаскиваем из контроллера поле @game
      expect(game).to be_nil
      
      # и редирект на страницу старой игры
      expect(response).to redirect_to(game_path(game_w_questions))
      expect(flash[:alert]).to be
    end
    
    # Тест на обработку помощи зала
    it 'uses audience help' do
      # сперва проверяем что в подсказках текущего вопроса пусто
      expect(game_w_questions.current_game_question.help_hash[:audience_help]).not_to be
      expect(game_w_questions.audience_help_used).to be_falsey
      
      # фигачим запрос в контроллен с нужным типом
      put :help, id: game_w_questions.id, help_type: :audience_help
      game = assigns(:game)
      
      # проверяем, что игра не закончилась, что флажок установился, и подсказка записалась
      expect(game.finished?).to be_falsey
      expect(game.audience_help_used).to be_truthy
      expect(game.current_game_question.help_hash[:audience_help]).to be
      expect(game.current_game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')
      expect(response).to redirect_to(game_path(game))
    end

    # Тест на обработку использования 50/50
    it 'does use fifty_fifty help' do
      # Проверяем использована подсказка или нет, у  теущего вопроса
      expect(game_w_questions.current_game_question.help_hash[:fifty_fifty]).not_to be
      expect(game_w_questions.fifty_fifty_used).to be_falsey
  
      put :help, id: game_w_questions.id, help_type: :fifty_fifty
      game = assigns(:game)
      
      expect(game.current_game_question.help_hash[:fifty_fifty]).to be
      expect(game.current_game_question.help_hash[:fifty_fifty].size).to eq(2)
      expect(game.current_game_question.help_hash[:fifty_fifty]).to include('d')
      expect(response).to redirect_to(game_path(game))
    end
  end
end
