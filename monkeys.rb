class Darwin
  attr_accessor :population, :target, :generation
  attr_accessor :population_size, :crossover_rate, :mutation_rate, :elitism, :elitism_range

  def initialize(target)
    self.target = target
    self.population_size = 1000
    self.elitism = 0.1
    self.elitism_range = (0..population_size * elitism)
    self.crossover_rate = 0.7
    self.mutation_rate = 0.2
    self.generation = 1
  end

  def run!
    self.population = Monkey.random_population(self.population_size, length, target).sort.reverse
    print_generation

    loop do
      self.generation += 1

      mating_season
      print_generation

      return if best_attempt.genes == target
    end
  end

  def print_generation
    puts "Generation: #{generation}\t\t#{best_attempt.genes}\t\t(#{best_attempt.fitness})"
  end

  def mating_season
    new_population = population[elitism_range]

    loop do
      break if new_population.length >= population.length

      daddy = select_parent
      mummy = select_parent

      siblings = if rand < crossover_rate
                   daddy.breed(mummy)
                 else
                   [daddy, mummy]
                 end

      if rand < mutation_rate
        siblings[0].mutate!
      end
      if rand < mutation_rate
        siblings[1].mutate!
      end

      new_population += siblings
    end

    self.population = new_population.sort.reverse
  end

  def select_parent
    # Uses roulette wheel selection
    total_fitness = population.map(&:fitness).inject(&:+)
    sum_to = rand(total_fitness)

    sum = 0
    population.each do |member|
      sum += member.fitness
      return member if sum >= sum_to
    end
  end

  def length
    target.length
  end

  def best_attempt
    population.max
  end
end

class Monkey
  CHARS = ('a'..'z').to_a + ('A'..'Z').to_a + [' ']
  attr_accessor :genes, :size, :target

  def initialize(genes, target)
    self.genes = genes
    self.size = genes.length
    self.target = target
  end

  def breed(other)
    crossover = rand(size)

    first  = genes[0...crossover] + other.genes[crossover..size]
    second = other.genes[0...crossover] + genes[crossover..size]

    [Monkey.new(first, target), Monkey.new(second, target)]
  end

  def mutate!
    bit = rand(size - 1)

    genes[bit] = self.class.random_char

    self
  end

  def fitness
    @fitness ||= target.each_char.zip(genes.each_char).select { |a,b| a == b }.count
  end

  def <=>(other)
    fitness <=> other.fitness
  end

  def self.random_population(number, gene_length, target)
    (0...number).map do
      new(random_string(gene_length), target)
    end
  end

  def self.random_char
    CHARS.sample
  end

  def self.random_string(length)
    (0...length).map { self.random_char }.join
  end
end


Darwin.new('To be or not to be that is the question').run!
