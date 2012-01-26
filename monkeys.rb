class Darwin
  attr_accessor :population, :target, :generation
  attr_accessor :population_size, :crossover_rate, :mutation_rate, :elitism, :elitism_range

  def initialize(target)
    self.target = target
    self.population_size = 500
    self.elitism = 0.2
    self.elitism_range = (0..population_size * elitism)
    self.crossover_rate = 0.8
    self.mutation_rate = 0.1
    self.generation = 1
  end

  def run!
    start = Time.now

    puts "============= Welcome To Typing Monkeys ============="
    puts "\nTARGET:\t\t\t#{target}\n"
    self.population = Monkey.random_population(self.population_size, length, target)
    sort_and_total_population!

    print_generation

    loop do
      self.generation += 1

      generate_new_population!
      print_generation

      break if best_attempt.genes == target
    end

    time = Time.now - start
    puts "\n\nReached target after #{generation} generations and #{time}s."
  end

  def print_generation
    print "\rGeneration: #{generation}\t\t#{best_attempt.genes}\t\t(#{best_attempt.fitness}/#{length})"
  end

  def generate_new_population!
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
        siblings[0] = siblings[0].mutate
      end
      if rand < mutation_rate
        siblings[1] = siblings[1].mutate
      end

      new_population += siblings
    end

    self.population = new_population
    sort_and_total_population!
  end

  def select_parent
    # Uses roulette wheel selection
    sum_to = rand(@total_fitness)

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
    population[0]
  end

  def sort_and_total_population!
    self.population.sort! { |a,b| b.fitness <=> a.fitness }
    @total_fitness = population.map(&:fitness).inject(&:+)
  end
end

class Monkey
  CHARS = ('a'..'z').to_a + ('A'..'Z').to_a + [' ']
  attr_accessor :genes, :size, :target

  include Enumerable

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

  def mutate
    bit = rand(size - 1)

    mutated = genes.dup
    mutated[bit] = self.class.random_char

    Monkey.new(mutated, target)
  end

  def fitness
    @fitness ||= target.each_char.zip(genes.each_char).select { |a,b| a == b }.count
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
    CHARS.sample(length).join
  end
end

quote = ''
File.open('quotes.txt') do |f|
  quote = f.read.each_line.to_a.sample.chomp
end
Darwin.new(quote).run!
