// SPDX-License-Identifier: MIT
// UBD Network erc20 token
pragma solidity 0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract UBDerc20 is ERC20 {

	constructor(address holder) 
	    ERC20("United Blockchain Dollar", "UBD")
	{
        _mint(holder, 1_000_000_000_000e18); 
	}
}