require 'spec_helper'

describe IdaStarSolver do

  xit '#run on complete Dimitri-Yorick pack' do
    pack = Pack.new('data/Dimitri-Yorick.slc')

    pack.levels.each do |level|
      puts "------------"
      puts "start level: #{level.name}"
      puts "------------"

      solver = IdaStarSolver.new(level)
      solver.run

      puts "------------"
      puts "end level: #{level.name}"
      puts "------------"
    end
  end

  xit '#run (complex level)' do
    text = "################ \n"\
           "#              # \n"\
           "# # ######     # \n"\
           "# #  $ $ $ $#  # \n"\
           "# #   $@$   ## ##\n"\
           "# #  $ $ $###...#\n"\
           "# #   $ $  ##...#\n"\
           "# ##\#$$$ $ ##...#\n"\
           "#     # ## ##...#\n"\
           "#####   ## ##...#\n"\
           "    #####     ###\n"\
           "        #     #  \n"\
           "        #######  "
    # because #$$ == interpolation of process id

    level = Level.new(text)

    solver = IdaStarSolver.new(level)
    solver.run

    solver.found.should                    == true
    solver.tries.should                    == 64
    solver.total_tries.should              == 1111
    solver.pushes.should                   == 64
    solver.penalties.size.should           == 3
    solver.processed_penalties.size.should == 0
  end

  it '#run on a complex level of Dimitri-Yorick pack', :slow => true do
   text =  "########\n"\
           "#......#\n"\
           "# $##$ #\n"\
           "#  ##  #\n"\
           "# $$@$$#\n"\
           "#      #\n"\
           "#   #  #\n"\
           "########"

    level = Level.new(text)

    solver = IdaStarSolver.new(level)
    solver.run

    solver.found.should                    == true
    solver.tries.should                    == 22
    solver.total_tries.should              == 9727
    solver.pushes.should                   == 21
    solver.penalties.size.should           == 73
    solver.processed_penalties.size.should == 1456

    # Be sure that this penalty is computed
    penalty = {
      :node  => Level.new("########\n"\
                          "#+.....#\n"\
                          "#  ##$ #\n"\
                          "#  ##$ #\n"\
                          "#      #\n"\
                          "#      #\n"\
                          "#   #  #\n"\
                          "########").to_node,
      :value => Float::INFINITY
    }

    solver.penalties.should include(penalty)
  end

  it '#run (first level)', :slow => true do
    level  = Pack.new('spec/support/files/level.slc').levels[0]
    solver = IdaStarSolver.new(level)
    solver.run

    solver.found.should                    == true
    solver.tries.should                    == 97
    solver.total_tries.should              == 2456
    solver.pushes.should                   == 97
    solver.penalties.size.should           == 6
    solver.processed_penalties.size.should == 0
  end

  it '#run (little bit simplified first level)' do
    text =  "    #####          \n"\
            "    #   #          \n"\
            "    #$  #          \n"\
            "  ###   ##         \n"\
            "  #  $ $ #         \n"\
            "### # ## #   ######\n"\
            "#   # ## #####  ..#\n"\
            "# $             ..#\n"\
            "##### ### #@##    #\n"\
            "    #     #########\n"\
            "    #######        "

    level = Level.new(text)
    solver = IdaStarSolver.new(level)
    solver.run

    solver.found.should                    == true
    solver.tries.should                    == 64
    solver.total_tries.should              == 6294
    solver.pushes.should                   == 64
    solver.penalties.size.should           == 0
    solver.processed_penalties.size.should == 291
  end

  it '#run (very simplified first level)' do
    text =  "    #####          \n"\
            "    #   #          \n"\
            "    #$  #          \n"\
            "  ###   ##         \n"\
            "  #    $ #         \n"\
            "### # ## #   ######\n"\
            "#   # ## #####   .#\n"\
            "# $             ..#\n"\
            "##### ### #@##    #\n"\
            "    #     #########\n"\
            "    #######        "

    level = Level.new(text)
    solver = IdaStarSolver.new(level)
    solver.run

    solver.found.should                    == true
    solver.tries.should                    == 49
    solver.total_tries.should              == 1280
    solver.pushes.should                   == 49
    solver.penalties.size.should           == 0
    solver.processed_penalties.size.should == 74
  end

  it '#run (very *very* simplified level)' do
    text =  "    #####          \n"\
            "    #@  #          \n"\
            "    #   #          \n"\
            "  ###$  ##         \n"\
            "  #    $ #         \n"\
            "### # ## #   ######\n"\
            "#   # ## #####   .#\n"\
            "#                .#\n"\
            "##### ### # ##    #\n"\
            "    #     #########\n"\
            "    #######        "

    level = Level.new(text)
    solver = IdaStarSolver.new(level)
    solver.run

    solver.found.should                    == true
    solver.tries.should                    == 35
    solver.total_tries.should              == 35
    solver.pushes.should                   == 34
    solver.penalties.size.should           == 0
    solver.processed_penalties.size.should == 0
  end

  it '#run (simple level)' do
    text =  "  ####  \n"\
            "###  #  \n"\
            "#    #  \n"\
            "#   .###\n"\
            "### #@.#\n"\
            "  # $$ #\n"\
            "  #  $ #\n"\
            "  #. ###\n"\
            "  ####  "

    level  = Level.new(text)
    solver = IdaStarSolver.new(level)
    solver.run

    solver.found.should                    == true
    solver.tries.should                    == 253
    solver.total_tries.should              == 2471
    solver.pushes.should                   == 25
    solver.penalties.size.should           == 16
    solver.processed_penalties.size.should == 86
  end

  it '#run (level with less boxes than goals)' do
    text =  "  ####  \n"\
            "###  #  \n"\
            "#    #  \n"\
            "#   .###\n"\
            "### #@.#\n"\
            "  #  $ #\n"\
            "  #  $ #\n"\
            "  #. ###\n"\
            "  ####  "

    level  = Level.new(text)
    solver = IdaStarSolver.new(level)
    solver.run

    solver.found.should                    == true
    solver.tries.should                    == 5
    solver.total_tries.should              == 5
    solver.pushes.should                   == 5
    solver.penalties.size.should           == 0
    solver.processed_penalties.size.should == 0
  end

  it '#run (impossible level)', :focus => true do
    text =  "  ####  \n"\
            "###  #  \n"\
            "#  $ #  \n"\
            "#   .###\n"\
            "###$#@.#\n"\
            "  #    #\n"\
            "  #    #\n"\
            "  #. ###\n"\
            "  ####  "

    level  = Level.new(text)
    solver = IdaStarSolver.new(level)
    solver.run

    solver.found.should                    == false
    solver.tries.should                    == 101 # 1 push + 100 loop_tries used to detect impossible solution
    solver.total_tries.should              == 101
    solver.pushes.should                   == Float::INFINITY
    solver.penalties.size.should           == 0
    solver.processed_penalties.size.should == 0
  end

end
