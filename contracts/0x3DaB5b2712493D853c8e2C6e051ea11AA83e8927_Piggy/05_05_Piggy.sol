// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//         Oink             Oink oink 
//           \                  \
//
//           (\___/)            (\___/)
//           / _"_ \________    / _"_ \________
//          ( (o o) )       \9 ( (o o) )       \9
//           \__^__/         \  \__O__/         \
//          _.::::::::::::::::::._\  __         /
//          \"""""""""""""""\""""/ (_ (___)_(___)
//           \_______________\__/   )_/)_/)_/)_/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Piggy is ERC20("PIGGY", "PIGGY") {
	constructor() {
		_mint(msg.sender, 1_000_000_000 ether);
	}
}