// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract IndiGG is ERC20("IndiGG", "INDI") {

    constructor() public {
		_mint(_msgSender(), 1_000_000_000 ether);
	}
}