# dotfiles

These are my personal configurations files that I use for software development
on my machine. This README and my commit messages should help describe
the process of creating and maintaining your own dotfiles. There might be some
obvious things that are written here but I want it to be accessible to as many
skill levels as possible.

### What are dotfiles?

Dotfiles are typically configuration files that are used to tell programs how
to run. They are called dotfiles because they use a dot/period(`.`) to prefix
the name of the directory or file (e.g.  `.gitconfig`,
`.awesome_whatever_dir`). Anything with this prefix is treated as hidden and
can be seen by typing `$ ls -a` in your terminal. Generally, a users personal
configurations settings are stored in the users home directory (`~/`) in a
collection of different dotfiles. For example, configurations for vim are
found in `.vimrc`. Because of their location, a lot of programs will look
there for the users settings when starting.

### Installation

It has become a common convention to share your dotfiles in a single
repository and use various methods to get them in the correct spots on your
local machine. Some have gone so far as to automate the set up process so
getting started on a new machine takes minimal effort. This generally consists
of installation scripts that creates `symlink`s from a dotfile in your home
directory to the repository that houses all your dotfiles. You might not be
surprised to find that the community has got you covered and has created
[tools](#tools) to help with installation and organization of dotfiles such as
[thoughtbots rc managment tool](https://github.com/thoughtbot/rcm). At the
same time a lot of people create their own ways of installing and managing so
it's up to you how you want to move forward.

I decided to try my hand at creating my own installation script.

## Creating your own

You might be like me and just want to create your own dotfiles without cloning
someone else's but don't really know where to begin. The rest of this should
help you get comfortable creating your own dotfiles.

### Getting Started

##### Create your dotfiles repo
To get started, create a directory named `.dotfiles` in your home directory,
create a `README.md` and set it all up to be tracked by `git`.

```
$ mkdir ~/.dotfiles
$ cd ~/.dotfiles
$ touch README.md
$ git init
$ git add README.md
$ git commit -m 'Starting dotfiles'
```

`.dotfiles` doesn't have to be in your home directory. It could be anywhere actually.
You'll just have to adjust installation scripts to account for the different
path.

##### start simple installation script

This is just how I have chosen to manage my dotfiles so feel free to adjust
this however you see fit.

Create a `bin` directory with an `install` file

```
$ mkdir ~/.dotfiles/bin
$ touch ~/.dotfiles/bin/install
```

Change permissions on the install file so it can be executed. I'm setting it
so the user can execute and the rest of the system can read the file.

```
$ chmod 744 ~/.dotfiles/bin/install
```

Now that the file is an executable you can create your installation script.
Here is what I'm starting out with in this repository. This will change over
time but this should work on a most basic level.

```ruby
#!/usr/bin/env ruby

require 'fileutils'
require 'pathname'

class DotfileLinker
  def initialize(dotfiles_path)
    @dotfiles_path = Pathname.new(dotfiles_path)
    @base_path = @dotfiles_path.expand_path
  end

  def link(pointer_file, source_file)
    if File.exist?("#{@base_path}/#{source_file}")
      FileUtils.ln_s "#{@base_path}/#{source_file}", Pathname.new("~/#{pointer_file}").expand_path, force: true
    else
      puts "File, #{@base_path}/#{source_file}, doesn't exist"
    end
  end
end

linker = DotfileLinker.new("~/.dotfiles")

# Vim
linker.link(".vim", "vim/vimrc")
```

I'll explain the idea behind some of the pieces that make it work.

```
#!/usr/bin/env ruby
```

This tells the file what interpreter to use when executing the file. I picked
ruby since it is the language I'm most familiar with but you can use whatever
you want that interact with your file system. You can read more about [sheband
here](https://en.wikipedia.org/wiki/Shebang_(Unix).

```ruby
def link(pointer_file, source_file)
  if File.exist?("#{@base_path}/#{source_file}")
    FileUtils.ln_s "#{@base_path}/#{source_file}", Pathname.new("~/#{pointer_file}").expand_path, force: true
  else
    puts "File, #{@base_path}/#{source_file}, doesn't exist"
  end
end
```

This method takes the `point_file` that you want to be linked to the second
argument, the `source_file`. This should be written relative to the repository
root since we are getting the `base_path` in the classe's initializer. This
source file is the file that exists here, within the `.dotfiles` directory. If
the source file doesn't exist for some reason it will just print out a warning
and won't create a sym link. If the source file exists then it will create a
link. `fource: true` makes it so it overwrites any existing pointer files sym
link. For example if you change your source file from `foo` to `foobar` then
the link sym link will be correctly changed.

```ruby
linker = DotfileLinker.new("~/.dotfiles")

linker.link(".foorc", "foo/foorc")
linker.link(".bar", "bar/baz")
```

Since it's wrapped in a class we can initialize the object and call `link` any
number of time in order to create any of the links we need.

To run your installation script, change directories to the root of the
dotfiles and run the script.

```
$ cd ~./.dotfiles
$ bin/install
```

Over time you can tweak this file as needed, and maybe move to a pre built
management tool if you don't want to maintain your own. In any case this is a
great place to start with dotfiles.

### Resources

* [dotfiles on github](http://dotfiles.github.io)
  - Provides links to helpful resources around the dotfiles community.

##### Tools

Some Dotfile managment tools if you don't want to write your own.
* [rcm](https://github.com/thoughtbot/rcm)
* [homesick](https://github.com/technicalpickles/homesick)
* [vcsh](https://github.com/RichiH/vcsh)
