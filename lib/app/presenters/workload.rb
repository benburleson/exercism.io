class NullWorkload
  attr_reader :user, :language, :slug
  def initialize(user, language, slug)
    @user, @language, @slug = user, language, slug
  end

  def breakdown
    {}
  end

  def submissions
    []
  end

  def available_exercises
    []
  end
end

class Workload
  attr_reader :user, :language, :slug
  def initialize(user, language, slug)
    @user = user
    @language = language
    @slug = slug
  end

  def breakdown
    @breakdown ||= pending.group('submissions.slug').count
  end

  def submissions
    return @submissions if @submissions

    scope = pending.order('created_at ASC')
    case slug
    when 'looks-great'
      scope = scope.where(is_liked: true)
    when 'no-nits'
      scope = scope.where(nit_count: 0)
    else
      scope = pending.where(slug: slug)
    end

    @submissions = scope.select do |submission|
      user.nitpicker_on?(submission.exercise)
    end
  end

  def available_exercises
    Exercism.curriculum.in(language).exercises.select {|exercise|
      user.nitpicker_on?(exercise)
    }
  end

  private

  def pending
    @pending ||= Submission.pending.where(language: language).unmuted_for(user)
  end
end

