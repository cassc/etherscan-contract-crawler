// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*

	https://www.ryoshiswhisper.com/
	
	https://twitter.com/ryoshiswhisper
	
	https://t.me/v_portal_official

*/

contract V is ERC20 {
	
	constructor() ERC20("ryoshis whisper", "V") {
		_mint(msg.sender, 5_000_000_000 ether);
	}
  
}