// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CMT is ERC20 {
	address public owner;

	modifier onlyOwner() {
		require(owner == msg.sender, "Not authorized");
		_;
	}

	constructor(address _owner, uint256 _initialSupply) ERC20("CheckMate Token", "CMT") {
		_mint(_owner, _initialSupply);
		owner = _owner;
	}

	function mint(uint256 amount) public onlyOwner {
		_mint(owner, amount);
	}
}