defmodule Discuss.TopicController do
	#Have not yet covered exactly what "use" is, but we are "inherting"
	#out of web.ex, specifically the "controller" function, because we suppiled
	#the :controller atom.
	use Discuss.Web, :controller

	alias Discuss.Topic

	plug Discuss.Plugs.RequireAuth when action in [:new, :create, :edit, :update, :delete]
	plug :check_topic_owner when action in [:update, :edit, :delete]


	def index(conn, _params) do
		topics = Repo.all(Topic)
		render conn, "index.html", topics: topics
	end

	def new(conn, _params) do
		changeset = Topic.changeset(%Topic{}, %{})
		render conn, "new.html", changeset: changeset
	end

	# I think this guy raises an exception
	def create(conn, %{"topic" => topic}) do
		# conn.assigns[:user]
		# conn.assigns.user, both give access to the user 
		changeset = Topic.changeset(%Topic{}, topic)

		changeset = conn.assigns.user
			|> build_assoc(:topics)
			|> Topic.changeset(topic)

		case Repo.insert(changeset) do
			{:ok, _topic} -> 
				conn
				|> put_flash(:info, "Topic Created")
				|> redirect(to: topic_path(conn, :index))
			{:error, changeset} -> 
			 render conn, "new.html", changeset: changeset
		end
		conn
	end

	def edit(conn, %{"id" => topic_id}) do
		topic = Repo.get(Topic, topic_id)
		changeset = Topic.changeset(topic)

		render conn, "edit.html", changeset: changeset, topic: topic
	end

	def update(conn, %{"id" => topic_id, "topic" => topic}) do 
		old_topic = Repo.get(Topic, topic_id)
		changeset = Topic.changeset(old_topic, topic)

		case Repo.update(changeset) do
			{:ok, _topic} -> 
				conn
				|> put_flash(:info, "Topic Updated")
				|> redirect(to: topic_path(conn, :index))
			{:error, changeset} ->
				render conn, "edit.html", changeset: changeset, topic: old_topic
		end
	end

	def delete(conn, %{"id" => topic_id}) do
		Repo.get!(Topic, topic_id) |> Repo.delete!

		conn 
		|> put_flash(:info, "Topic Deleted")
		|> redirect(to: topic_path(conn, :index))
	end

	# Plugs are called with different args to connection handlers, 
	# hence why we need to pull out the topic id from the connection manually
	def check_topic_owner(conn, _params) do
		%{params: %{"id" => topic_id}} = conn

		if Repo.get(Topic, topic_id).user_id == conn.assigns.user.id do
			conn
		else
			conn
			|> put_flash(:error, "You cannot edit that")
			|> redirect(to: topic_path(conn, :index))
			|> halt()
		end
	end

end





