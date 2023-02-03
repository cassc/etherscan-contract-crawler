// contracts/SoulProtection.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./AntiBot.sol";
import "./AntiWhale.sol";
import "./RewardPoolFee.sol";

contract SoulProtection is AntiBot, AntiWhale, RewardPoolFee {
	mapping(address => bool) internal _transferWhitelist;
	mapping(address => bool) internal _liquidityPool;

	/**
	 * @dev Returns if _wallet belongs to {_transferWhitelist}.
	 */
	function isWalletWhitelisted(address _wallet) public view returns (bool) {
		return _transferWhitelist[_wallet];
	}

	/**
	 * @dev Changes the status of a wallet for our {_transferWhitelist}.
	 */
	function setTransferWhitelist(address _wallet, bool _status)
		external
		onlyOwner
	{
		_transferWhitelist[_wallet] = _status;
	}

	/**
	 * @dev Changes the status of a wallet for our {_liquidityPool}.
	 */
	function setLiquidityWhitelist(address _wallet, bool _status)
		external
		onlyOwner
	{
		_liquidityPool[_wallet] = _status;
	}
}