// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract TestToken is ERC20, Ownable {
	using SafeMath for uint256;
	using Address for address;
	uint8 _decimal;
	mapping(address => bool) admin;

	constructor(
		string memory name_,
		string memory symbol_,
		uint8 decimal_
	) ERC20(name_, symbol_) {
		admin[_msgSender()] = true;
		_decimal = decimal_;
	}

	function decimals() public view virtual override returns (uint8) {
		return _decimal;
	}

	function mint(address addr_, uint256 amount_) public onlyAdmin {
		_mint(addr_, amount_);
	}

	modifier onlyAdmin() {
		require(admin[_msgSender()], "not damin");
		_;
	}

	function setAdmin(address com_) public onlyOwner {
		require(com_ != address(0), "wrong adress");
		admin[com_] = true;
	}
}