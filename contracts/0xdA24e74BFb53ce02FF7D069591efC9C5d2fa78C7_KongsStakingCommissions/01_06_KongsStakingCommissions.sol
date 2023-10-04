// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IKongsStakingCommissions.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Kongs Staking Comissions v1.0
 * @author DeployLabs.io
 *
 * @notice This contract is used for collecting commissions for staking Alpha and Omega Kong NFTs.
 */
contract KongsStakingCommissions is IKongsStakingCommissions, Ownable {
	function payCommission(uint256 uuid) external payable {
		emit CommissionPaid(uuid, msg.sender, msg.value);
	}

	function withdraw(address payable to) external onlyOwner {
		uint256 balance = address(this).balance;
		if (balance == 0) revert KongsStaking__NothingToWithdraw();
		if (to == address(0)) revert KongsStaking__ZeroAddressProhibited();

		to.transfer(balance);
	}
}