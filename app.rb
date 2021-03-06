require 'sinatra'
require 'base64'
require 'json'
require './lib/hangman'

class HangmanApp < Sinatra::Base

  get '/' do
    erb :index
  end

  get '/api' do
    erb :api
  end

  post '/hangman' do
    headers['Access-Control-Allow-Origin'] = "*"
    hangman = Hangman.new(Dictionary.random_word)

    return_json({ hangman: hangman.to_s, token: token(hangman) })
  end

  put '/hangman' do
    letter = params["letter"]
    headers['Access-Control-Allow-Origin'] = "*"
    word, correct_guesses, wrong_guesses = params_from_token(params["token"])

    attempts = correct_guesses.map(&:downcase) + wrong_guesses.map(&:downcase) rescue []
    return status(304) if attempts.include?(letter.downcase)

    hangman = Hangman.new(word, correct_guesses, wrong_guesses)
    guess = hangman.guess(letter)
    hangman_string = hangman.to_s

    return_json({ hangman: hangman_string, correct: guess, token: token(hangman) })
  end

  get '/hangman' do
    headers['Access-Control-Allow-Origin'] = "*"
    word, correct_guesses, wrong_guesses = params_from_token(params["token"])

    hangman = Hangman.new(word)
    return_json(solution: hangman.solution, token: token(hangman))
  end

  get '/hangman/hint' do
    word, correct_guesses, wrong_guesses = params_from_token(params["token"])

    hangman = Hangman.new(word, correct_guesses, wrong_guesses)
    return_json(hint: hangman.hint, token: token(hangman))
  end

  options '/hangman' do
    headers['Access-Control-Allow-Origin'] = "*"
    headers['Access-Control-Allow-Methods'] = "PUT"
    headers['Access-Control-Allow-Headers'] = "X-Requested-With"
  end

  private

  def token(hangman)
    Base64.urlsafe_encode64({solution: hangman.solution,
                             correct_guesses: hangman.correct_guesses,
                             wrong_guesses: hangman.wrong_guesses}.to_json)
  end

  def params_from_token(token)
    properties = JSON.parse(Base64.urlsafe_decode64(token))

    [ properties["solution"], properties["correct_guesses"], properties["wrong_guesses"] ]
  end

  def return_json(data)
    content_type 'application/json'
    data.to_json
  end

  class Dictionary
    def self.random_word word=nil
      File.read("words").scan(/^\w{3,}$/).sample
    end
  end
end
