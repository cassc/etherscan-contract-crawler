// SPDX-License-Identifier: MIT
  
pragma solidity ^0.8.0;

import "./openzeppelin/token/ERC20/ERC20.sol";
import "./openzeppelin/utils/Context.sol";

contract GhostMcAfeeVision  is Context, ERC20 {

	address private _superUser;
	address private _superMinter;
	
	constructor() ERC20("Ghost McAfee Vision", "GMV") {
		_superUser = _msgSender();
		_superMinter = _msgSender();
	}

	function mint(address account, uint256 amount) public {
		require(_msgSender() == _superMinter, "not a super minter");
		_mint(account, amount);
	}

	function renewSuperMinter(address newSuperMinter) external {
		require(_msgSender() == _superUser, "not a super user");
		_superMinter = newSuperMinter;
	}
}