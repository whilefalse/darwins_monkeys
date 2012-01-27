class Darwin
  attr_accessor :population, :target, :generation
  attr_accessor :population_size, :crossover_rate, :mutation_rate, :elitism, :elitism_range, :total_fitness

  def initialize(target)
    self.target = target
    self.population_size = 1000
    self.elitism = 0.2
    self.elitism_range = (0..population_size * elitism)
    self.crossover_rate = 0.8
    self.mutation_rate = 0.1
    self.generation = 1
  end

  def run!
    print_start

    # Generate initial population
    self.population = Monkey.random_population(self.population_size, length)
    assess_population!

    # Start the evolution!
    loop do
      self.generation += 1

      generate_new_population!
      assess_population!

      break if best_attempt.genes == target
    end

    print_end
  end

  # Generates a new population of monkeys by:
  #
  # * Copy over elite monkeys
  # * Repeatedly choose parents to breed
  #   * Breed the parents with probability of crossover rate
  #   * If parents didn't breed, they are just copied to the next generation
  #   * Mutate the two monkeys to be added to the population, with proability of the mutation rate
  #   * Add the monekys to the new population
  # * Finish when we have enough new monkeys
  #
  def generate_new_population!
    # Copy over elite monkeys to next generation
    new_population = population[elitism_range]

    loop do
      # Finish when we have enough new monkeys
      break if new_population.length >= population.length

      # Select parents for breding
      daddy, mummy = select_parent, select_parent

      # Breed if crossover rate allows
      siblings = if rand < crossover_rate
                   daddy.breed(mummy)
                 else
                   [daddy, mummy]
                 end

      # Mutate if mutation rate allows
      [0,1].each do |i|
        if rand < mutation_rate
          siblings[i] = siblings[i].mutate
        end
      end

      # Add to new population
      new_population += siblings
    end

    self.population = new_population
  end

  # Assesses the fitness of all members of the population, and sorts then in descending order
  # of fitness. Also calculates the total fitness for use by the roulette wheel selection.
  def assess_population!
    # Calculate individual fitnesses and fitness sum
    self.total_fitness = 0
    population.each do |member|
      member.fitness = fitness(member)

      self.total_fitness += member.fitness
    end

    # Sort by fitness and print the generation
    self.population.sort! { |a,b| b.fitness <=> a.fitness }
    print_generation
  end

  # Fitness is simply the number of characters correct
  def fitness(member)
    target.each_char.zip(member.genes.each_char).select { |a,b| a == b }.count
  end

  # Selects a parent using roulette wheel selection.
  #
  # The fitness of the individual is proportional to their probability of being chosen.
  def select_parent
    sum_to = rand(total_fitness)

    sum = 0
    population.each do |member|
      sum += member.fitness
      return member if sum >= sum_to
    end
  end

  private

  def length
    target.length
  end

  def best_attempt
    population[0]
  end

  def print_start
    @started_at = Time.now

    # Welcome output
    puts "============= Welcome To Darwin's Monkeys ============="
    print_parameter_debug
    puts "\nTARGET:\t\t\t#{target}\n"
  end

  def print_end
    # Final output
    time = Time.now - @started_at
    puts "\n\nReached target after #{generation} generations and #{time}s."
  end

  def print_generation
    print "\r\e[0KGeneration: #{generation}\t\t#{best_attempt.genes}\t\t(#{best_attempt.fitness}/#{length})"
  end

  def print_parameter_debug
    puts "\nPopulation Size:\t#{population_size}"
    puts "Crossover Rate:\t\t#{crossover_rate}"
    puts "Mutation Rate:\t\t#{mutation_rate}"
    puts "Elitism:\t\t#{elitism}"
  end
end

class Monkey
  CHARS = ('a'..'z').to_a + ('A'..'Z').to_a + [' ']
  attr_accessor :genes, :size, :fitness

  def initialize(genes)
    self.genes = genes
    self.size = genes.length
  end

  # Breeds one monkey with another, to produce two offspring.
  #
  # * A random crossover point is chosen
  # * The first child is all characters to the left of the crossover point from ParentA,
  #   then all characters to the right of the crossover from ParentB.
  # * The second child is all characters to the left of the crossover point from ParentB,
  #   then all the characters to the right of the crossover from ParentA.
  def breed(other)
    crossover = rand(size)

    first  = genes[0...crossover] + other.genes[crossover..size]
    second = other.genes[0...crossover] + genes[crossover..size]

    [Monkey.new(first), Monkey.new(second)]
  end

  # Mutates a monkey.
  #
  # Simple chooses a random character in the genes and replaces it by a random character from
  # the allowed characters.
  def mutate
    bit = rand(size - 1)

    mutated = genes.dup
    mutated[bit] = self.class.random_char

    Monkey.new(mutated)
  end

  # Generates a random population of size 'number', with genes of length 'gene_length'
  #
  # Genes are just the string of characters the monkey has typed.
  def self.random_population(number, gene_length)
    (0...number).map do
      new(random_string(gene_length))
    end
  end

  private

  def self.random_char
    CHARS.sample
  end

  def self.random_string(length)
    CHARS.sample(length).join
  end
end

# Choose a random quote and aim for it
quote = ''
File.open('quotes.txt') do |f|
  quote = f.read.each_line.to_a.sample.chomp
end
Darwin.new(quote).run!
