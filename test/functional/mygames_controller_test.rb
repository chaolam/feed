require 'test_helper'

class MygamesControllerTest < ActionController::TestCase
  setup do
    @mygame = mygames(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:mygames)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create mygame" do
    assert_difference('Mygame.count') do
      post :create, mygame: @mygame.attributes
    end

    assert_redirected_to mygame_path(assigns(:mygame))
  end

  test "should show mygame" do
    get :show, id: @mygame
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @mygame
    assert_response :success
  end

  test "should update mygame" do
    put :update, id: @mygame, mygame: @mygame.attributes
    assert_redirected_to mygame_path(assigns(:mygame))
  end

  test "should destroy mygame" do
    assert_difference('Mygame.count', -1) do
      delete :destroy, id: @mygame
    end

    assert_redirected_to mygames_path
  end
end
