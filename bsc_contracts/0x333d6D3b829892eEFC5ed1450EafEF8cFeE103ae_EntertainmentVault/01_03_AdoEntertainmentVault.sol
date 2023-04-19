// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./abstracts/Context.sol";
import "./interfaces/IBEP20.sol";

contract EntertainmentVault is Context {
	uint private _lockedUntil;
	uint constant private timeunit = 1 days;
	address private _owner;
	IBEP20 public tokenContract;
	uint256 public immutable slice;

	event EntertainmentVaultWithdraw(address indexed to, uint256 indexed slice);

	modifier onlyOwner() {
		require(_owner == _msgSender(), "EntertainmentVault: caller is not the owner");
		_;
	}

	constructor(address _tokenContract) {
		_owner = _msgSender();
		tokenContract = IBEP20(_tokenContract);
		_lockedUntil = block.timestamp + (5 * 365 * timeunit);
		slice = 5000000 * 10 ** 18;
	}

	function owner() external view returns (address) {
		return _owner;
	}

	function lockedUntil() external view returns (uint) {
		return _lockedUntil;
	}

	function unlockTokens(address to) external onlyOwner returns (uint) {
		require(to != address(0), "EntertainmentVault: transfer to the zero address");
		require(block.timestamp > _lockedUntil, "EntertainmentVault: Tokens cannot be withdrawn");
		require(tokenContract.balanceOf(address(this)) > 0, "EntertainmentVault: The Vault is empty");
		if (tokenContract.balanceOf(address(this)) >= slice) {
			emit EntertainmentVaultWithdraw(to, slice);
			tokenContract.transfer(to, slice);
		} else {
			uint256 amount = tokenContract.balanceOf(address(this));
			emit EntertainmentVaultWithdraw(to, amount);
			tokenContract.transfer(to, amount);
		}
		_lockedUntil = block.timestamp + (30 * timeunit);
		return _lockedUntil;
	}
}