# UBD Network De Trust
## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

To run tests in local sandbox
```shell
$ forge test --match-contract DeTrustModel_01_ExecutiveTest*
```
To run tests for forked chain  
```shell
$ source .env
$ forge test --match-contract UniV3TestETH_Trust_* -vv --fork-url  https://mainnet.infura.io/v3/$WEB3_INFURA_PROJECT_ID --etherscan-api-key $ETHERSCAN_TOKEN
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

### Deploy 
#### Sepolia
```shell
$ forge script script/Deploy.s.sol:DeployScript --rpc-url sepolia  --account ttwo --sender 0xDDA2F2E159d2Ce413Bd0e1dF5988Ee7A803432E3 --broadcast --verify  --etherscan-api-key $ETHERSCAN_TOKEN
```

```shell
$ forge script script/Deploy-BalanceChecker.s.sol:DeployScriptBalanceChecker --rpc-url sepolia  --account ttwo --sender 0xDDA2F2E159d2Ce413Bd0e1dF5988Ee7A803432E3 --broadcast --verify
```
```shell
$ forge  create --rpc-url sepolia  --account ttwo   --etherscan-api-key $ETHERSCAN_TOKEN  --verify  src/DeTrustModel_02_Executive.sol:DeTrustModel_02_Executive

$ forge verify-contract 0xCe05ABB733072Bb81bc16802120729f910299Bc9  ./src/DeTrustModel_02_Executive.sol:DeTrustModel_02_Executive  --num-of-optimizations 200 --compiler-version 0.8.23 --etherscan-api-key ${ETHERSCAN_TOKEN} --chain 11155111 

$ cast  send 0x663BeF18503572FC29d7db80cb79e44A9DBC4672  "setModelState(address,(bytes1,address,uint256,address,uint256))" "0xCe05ABB733072Bb81bc16802120729f910299Bc9" "(0x07,0x7ce7abb7F8794dCe67FB2dc4d8eBf2F033472730,1000000000000000000,0x7ce7abb7F8794dCe67FB2dc4d8eBf2F033472730,22000000000000000000)" --rpc-url sepolia  --account ttwo
```
```
### Verify
```shell
$ forge verify-contract 0x0e332Ee59191CD43a035fB705e82e53934cd2014  ./src/DeTrustFactory.sol:DeTrustFactory  --num-of-optimizations 200 --compiler-version 0.8.23 --etherscan-api-key ${ETHERSCAN_TOKEN} --chain 11155111 --constructor-args $(cast abi-encode "constructor(address modelReg, address userReg)" 0x1b813d6F365294535e4aB10c4547EcD05B39bE07 0xde03361b17c0cCa0A8E3a9864283CF9f46dA3f40)

$ forge verify-contract 0x1b813d6F365294535e4aB10c4547EcD05B39bE07  ./src/DeTrustModelRegistry.sol:DeTrustModelRegistry   --num-of-optimizations 200 --compiler-version 0.8.23 --etherscan-api-key ${ETHERSCAN_TOKEN} --chain 11155111

$ forge verify-contract 0xde03361b17c0cCa0A8E3a9864283CF9f46dA3f40  ./src/UsersDeTrustRegistry.sol:UsersDeTrustRegistry   --num-of-optimizations 200 --compiler-version 0.8.23 --etherscan-api-key ${ETHERSCAN_TOKEN} --chain 11155111

$ forge verify-contract 0x3A2E0c04c5007E9fcD637935E7B5Ee6d9eA906C0  ./src/DeTrustModel_00.sol:DeTrustModel_00   --num-of-optimizations 200 --compiler-version 0.8.23 --etherscan-api-key ${ETHERSCAN_TOKEN} --chain 11155111

$ forge verify-contract 0xd6591B614Fac2BB4AE48FE11195995e2bBD81d19  ./src/DeTrustProxy.sol:DeTrustProxy  --num-of-optimizations 200 --compiler-version 0.8.23 --etherscan-api-key ${ETHERSCAN_TOKEN} --chain 11155111 --constructor-args $(cast abi-encode "constructor(address, address, bytes32, uint64, string)" 	0x3A2E0c04c5007E9fcD637935E7B5Ee6d9eA906C0 0xDDA2F2E159d2Ce413Bd0e1dF5988Ee7A803432E3 0x405787fa12a823e0f2b7631cc41b3ba8828b3321ca811111fa75cd3aa3bb5ace 100 InitialTrust)

$ forge verify-contract 0xCe232a897E4d46d251f247Bc286eBAac60CeB94D  ./src/BalanceChecker.sol:BalanceChecker   --num-of-optimizations 200 --compiler-version 0.8.23 --etherscan-api-key ${ETHERSCAN_TOKEN} --chain 11155111 --constructor-args $(cast abi-encode "constructor(address token, address locker)" 0x7ce7abb7F8794dCe67FB2dc4d8eBf2F033472730 0xCCF7028D83D0b6eD8e68124Efe07E5FaD1C4E17F)
```
### Cast

```shell
## Latest block number
$ cast block --rpc-url blast_sepolia | grep number

$ cast send 0xd6591B614Fac2BB4AE48FE11195995e2bBD81d19 "transferNative(address,uint256)" "0xDDA2F2E159d2Ce413Bd0e1dF5988Ee7A803432E3" "100" --rpc-url sepolia --account ttwo 


$ cast send 0xd6591B614Fac2BB4AE48FE11195995e2bBD81d19 "transferERC20(address,address,uint256)" "0x7ce7abb7F8794dCe67FB2dc4d8eBf2F033472730" "0xDDA2F2E159d2Ce413Bd0e1dF5988Ee7A803432E3" "100" --rpc-url sepolia --account ttwo 

$ # ERC20 topup
$ cast send 0x7ce7abb7F8794dCe67FB2dc4d8eBf2F033472730 "transfer(address,uint256)" "0xd6591B614Fac2BB4AE48FE11195995e2bBD81d19" "100000" --rpc-url sepolia --account ttwo 

$ # ERC20 Balance
$ cast abi-decode "balanceOf(address)(uint256)" $(cast call 0x7ce7abb7F8794dCe67FB2dc4d8eBf2F033472730 "balanceOf(address)" "0xDDA2F2E159d2Ce413Bd0e1dF5988Ee7A803432E3" --rpc-url sepolia )

$ # Native Balance
$ cast balance 0xDDA2F2E159d2Ce413Bd0e1dF5988Ee7A803432E3 --rpc-url sepolia

$ # Register model
$ cast send 0x1b813d6F365294535e4aB10c4547EcD05B39bE07 "setModelState(address,(bytes1,address,uint256,address))" "0x3A2E0c04c5007E9fcD637935E7B5Ee6d9eA906C0" "(0x03, 0xCe232a897E4d46d251f247Bc286eBAac60CeB94D, 100000000000000000000, 0x0000000000000000000000000000000000000000)" --rpc-url sepolia --account ttwo 

$ # UBDN balance
$ cast from-wei $(cast call 0x7ce7abb7F8794dCe67FB2dc4d8eBf2F033472730 "balanceOf(address)" "0xDDA2F2E159d2Ce413Bd0e1dF5988Ee7A803432E3" --rpc-url sepolia)

$ #keccak256(abi.encode( uint256(keccak256("ubdn.storage.DeTrustModel_01_Executive")) - 1)) & ~bytes32(uint256(0xff) )
$ cast keccak 
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

### Add forge to existing Brownie project
```shell
$ forge init --force
$ forge install OpenZeppelin/openzeppelin-contracts
$ forge install OpenZeppelin/openzeppelin-contracts-upgradeable.git
$ forge buld
```
### First build
```shell
git clone git@gitlab.com:ubd2/ubdn-detrust.git
git submodule update --init --recursive
```