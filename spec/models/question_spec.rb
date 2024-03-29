require 'rails_helper'

RSpec.describe Question, type: :model do
  context 'validations check' do
    # Проверяем наличие валидации
    it { should validate_presence_of :text }
    it { should validate_presence_of :level }
    # Проверяем, что уровень входит в диапазон
    it { should validate_inclusion_of(:level).in_range(0..14) }
    # Проверяем, разрешено ли поле со значением 14
    it { should allow_value(14).for(:level) }
    it { should_not allow_value(15).for(:level) }
    
    # Проверяем на валидацию уникальности текста вопроса
    # Явно создаем "предмет тестирования" - валидный объект
    subject { Question.new(text: 'some',
                           level: 0, answer1: '1', answer2: '1', answer3: '1', answer4: '1') }
    # Только с валидным объектом работает этот тест,
    # Иначе пытается создать в базе новый невалидный
    it { should validate_uniqueness_of(:text) }
  end
end