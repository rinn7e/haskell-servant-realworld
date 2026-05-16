.PHONY: build watch server server-watch resetdb seed migrate-generate migrate-up migrate-down migrate-check lint format build-haddock build-hoogle hoogle test compile install exec run-installed

# Build with fast compilation
build:
	stack build --fast

# Build and watch for changes
watch:
	stack build --fast --file-watch

# Build and run the server
server:
	stack build --fast && stack exec haskell-servant-realworld-exe

# Build, watch, and auto-restart the server
server-watch:
	stack build --fast --file-watch --exec "haskell-servant-realworld-exe"

# Reset database and start dev server
resetdb:
	./my-scripts/resetdb.sh
	$(MAKE) migrate-up
	$(MAKE) seed
	$(MAKE) server

# Populate database with seed data
seed:
	psql "$(DB_CONN)" -f resource/seed.sql

# Generate a new migration (Usage: make migrate-generate NAME=add_users)
migrate-generate:
	@if [ -z "$(NAME)" ]; then echo "Error: NAME is required. Usage: make migrate-generate NAME=some_name"; exit 1; fi
	stack build --fast && stack exec migrate-exe -- generate $(NAME)

# Run all pending up migrations
migrate-up:
	stack build --fast && stack exec migrate-exe -- up

# Run a single down migration
migrate-down:
	stack build --fast && stack exec migrate-exe -- down

# Check for schema mismatches
migrate-check:
	stack build --fast && stack exec migrate-exe -- check

# Lint Haskell code
lint:
	hlint src exe
	find src exe test -name "*.hs" | xargs fourmolu --mode check

# Format Haskell code
format:
	find src exe test -name "*.hs" | xargs fourmolu --mode inplace

# Generate documentation
build-haddock:
	stack build --fast --haddock

# Start local Hoogle server
build-hoogle:
# generate Haddock docs for all your packages
	$(MAKE) haddock
# generate the Hoogle index
	stack hoogle -- generate --local --database=.stack-work/hoogle
# perform a search for map
	stack hoogle -- map --database=.stack-work/hoogle
# start a server
	stack hoogle -- server --local --database=.stack-work/hoogle

# Start local Hoogle server
hoogle:
	stack hoogle -- server --local --database=.stack-work/hoogle

# Run tests
test:
	stack build --fast --test

# Compile binary (production build)
compile:
	stack build

# Install binary to ~/.local/bin
install:
	stack install

# Run the compiled binary via stack
exec:
	stack exec haskell-servant-realworld-exe

# Run the installed binary (assumes ~/.local/bin is in PATH)
run-installed:
	haskell-servant-realworld-exe
