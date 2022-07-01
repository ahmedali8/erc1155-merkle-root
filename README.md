# ERC1155 Merkle example using [hardhat](https://github.com/NomicFoundation/hardhat) and [foundry](https://github.com/foundry-rs/foundry)

### Build Locally

```bash
# Clone repo
$ git clone https://github.com/ahmedali8/erc1155-merkle-example

# Initialize submodule dependencies
$ git submodule update --init --recursive

# Install development dependencies
$ yarn install
```

### Testing with hardhat

```bash
$ yarn test:hh

or

$ yarn hardhat test
```

### Testing with foundry

```bash
# additionally add -vvvv for verbose

$ yarn test:forge

or

$ forge test
```

### Note: refer to [hardhat-foundry-template](https://github.com/ahmedali8/foundry-hardhat-template) for more information and commands
