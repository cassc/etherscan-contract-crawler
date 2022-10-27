// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@exoda/contracts/access/Ownable.sol";
import "@exoda/contracts/interfaces/token/ERC20/IERC20.sol";
import "@exoda/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IFermionReactor.sol";
import "./interfaces/IFermion.sol";

contract FermionReactor is IFermionReactor, Ownable
{
	uint256 private immutable _lowerLimit;
	uint256 private immutable _upperLimit;
	uint256 private immutable _rate;
	IFermion private immutable _fermion;
	bool private _active;

	constructor(uint256 lowerLimit, uint256 upperLimit, IFermion fermion, uint256 rate) Ownable()
	{
		require(rate > 0, "FR: Rate < 0");
		require(upperLimit > lowerLimit, "FR: upperLimit <= lowerLimit");
		_lowerLimit = lowerLimit;
		_upperLimit = upperLimit;
		_rate = rate;
		_fermion = fermion;
		_active = true;
	}

	function buyFermion() override external payable
	{
		require(_active, "FR: Contract is not active");
		uint256 amountETH = msg.value;
		require(amountETH >= _lowerLimit, "FR: Insufficient ETH");
		require(amountETH <= _upperLimit, "FR: ETH exceeds upper Limit");
		// Get available Fermions
		uint256 fAvailable = _fermion.balanceOf(address(this));
		// Calculate Fermion Amount
		uint256 fAmount = amountETH * _rate;
		// Check if enought Fermions
		if(fAvailable < fAmount)
		{
			unchecked
			{
				// If not enouth use max possible amount of Fermions and refund unused eth
				fAmount = fAvailable;
				amountETH = fAmount / _rate;
				// refund unused eth
				_safeTransferETH(_msgSender(), (msg.value - amountETH));
				_active = false;
			}
		}
		// Transfer ETH to owner
		_safeTransferETH(owner(), amountETH);
		// Transfer Fermions to caller
		SafeERC20.safeTransfer(_fermion, _msgSender(), fAmount);
		emit Buy(_msgSender(), amountETH, fAmount);
	}

	function disable() override external onlyOwner
	{
		_active = false;
		uint256 fAvailable = _fermion.balanceOf(address(this));
		SafeERC20.safeTransfer(_fermion, owner(), fAvailable);
	}

	function transferOtherERC20Token(IERC20 token) override external onlyOwner returns (bool)
	{
		require(token != _fermion, "FR: Fermion can not be removed.");
		return token.transfer(owner(), token.balanceOf(address(this)));
	}

	function getFermionAddress() override external view returns(IFermion)
	{
		return _fermion;
	}

	function getLowerEthLimit() override external view returns(uint256)
	{
		return _lowerLimit;
	}

	function getRate() override external view returns(uint256)
	{
		return _rate;
	}

	function getUpperEthLimit() override external view returns(uint256)
	{
		return _upperLimit;
	}

	function isActive() override external view returns(bool)
	{
		return _active;
	}

	function _safeTransferETH(address to, uint256 value) private
	{
		// solhint-disable-next-line avoid-low-level-calls
		(bool success, ) = to.call{value: value}(new bytes(0));
		require(success, "FR: ETH transfer failed");
	}
}