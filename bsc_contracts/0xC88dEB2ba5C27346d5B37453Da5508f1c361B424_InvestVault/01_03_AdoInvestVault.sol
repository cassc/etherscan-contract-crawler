// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./abstracts/Context.sol";
import "./interfaces/IBEP20.sol";

contract InvestVault is Context {
	uint private _lockedUntil;
	uint constant private timeunit = 1 days;
	address private _owner;
	IBEP20 public tokenContract;
	uint256 public immutable slice;

	event InvestVaultWithdraw(address indexed to, uint256 indexed slice);

	modifier onlyOwner() {
		require(_owner == _msgSender(), "InvestVault: caller is not the owner");
		_;
	}

	constructor(address _tokenContract) {
		_owner = _msgSender();
		tokenContract = IBEP20(_tokenContract);
		_lockedUntil = block.timestamp + (6 * 365 * timeunit);
		slice = 5000000 * 10 ** 18;
	}

	function owner() external view returns (address) {
		return _owner;
	}

	function lockedUntil() external view returns (uint) {
		return _lockedUntil;
	}

	function unlockTokens(address to) external onlyOwner returns (uint) {
		require(to != address(0), "InvestVault: transfer to the zero address");
		require(block.timestamp > _lockedUntil, "InvestVault: Tokens cannot be withdrawn");
		require(tokenContract.balanceOf(address(this)) > 0, "InvestVault: The Vault is empty");
		if (tokenContract.balanceOf(address(this)) >= slice) {
			emit InvestVaultWithdraw(to, slice);
			tokenContract.transfer(to, slice);
		} else {
			uint256 amount = tokenContract.balanceOf(address(this));
			emit InvestVaultWithdraw(to, amount);
			tokenContract.transfer(to, amount);
		}
		_lockedUntil = block.timestamp + (30 * timeunit);
		return _lockedUntil;
	}
}