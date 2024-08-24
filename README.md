# UBD Network DeTrust Multisig

## Main Contracts
- **DeTrustMultisigModelRegistry** - storing available templates for creating multisig. Charge creation fee (or monitoring the conditions - available UBDN balance);  

- **UsersDeTrustMultisigRegistry** - storing the list of multisigs in which the address is a signatory or creator;
- **DeTrustMultisigFactory** - the contract will create new multisigs from templates (mimmal EIP-1167 proxy to template implementations);  

- **DeTrustMultisigOnchainModel_00** - a model for creating multisigs indicating the date and time of the start of the powers of each signatory;  
- **DeTrustMultisigOnchainModel_01** - a model for creating multisigs with a “quiet period” (no transactions of the creator of the multisig) - the powers of the signatory come at the end of this period;  
- **DeTrustMultisigOffchainModel_01** - a model for creating offchain (like Gnosis) multisig "quiet period". _During the implementation, the customer decided to implement onchain multisig models (meta transactions are created and signed in the contract). As a result, this model has been tested only partially._

[Detrust Proxy Creation Sequence Diagram](./proxyCraeteSequenceDiagram.md)
### Build
```shell
$ # First build
$ git clone git@gitlab.com:ubd2/ubdn-multisig.git
$ cd ubdn-multisig
$ git submodule update --init --recursive
```

```shell
$ forge build
```

### Test

To run tests in local sandbox first please insatll [foundry](https://book.getfoundry.sh/getting-started/installation)  
```shell
$ forge test
```

### Deployments 
#### Sepolia
```shell
$ forge script script/Deploy.s.sol:DeployScript --rpc-url sepolia  --account ttwo --sender 0xDDA2F2E159d2Ce413Bd0e1dF5988Ee7A803432E3 --broadcast --verify  --etherscan-api-key $ETHERSCAN_TOKEN

$ # Script for geting hash for staroge addresses
$ forge script script/GetStorageSlot.s.sol:GetStorageSlot
```


### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

