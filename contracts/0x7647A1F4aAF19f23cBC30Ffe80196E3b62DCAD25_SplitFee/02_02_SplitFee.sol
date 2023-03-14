// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error SplitFee__ZeroAddressProhibited();
error SplitFee__InvalidOwnerFeePercentage(uint8 ownerFeePercentage);

error SplitFee__NotAuthorized();
error SplitFee__ZeroTokenBalance();

/**
 * @title Split Fee
 * @author DeployLabs.io
 *
 * @dev The purpose of this contract is to split the fee between the owner and the artist.
 */
contract SplitFee {
	address payable private i_owner;
	address payable private i_artist;

	uint8 private i_ownerFeePercentage;

	constructor(address payable owner, address payable artist, uint8 ownerFeePercentage) {
		if (owner == address(0) || artist == address(0)) revert SplitFee__ZeroAddressProhibited();
		i_owner = owner;
		i_artist = artist;

		if (ownerFeePercentage > 100)
			revert SplitFee__InvalidOwnerFeePercentage(ownerFeePercentage);
		i_ownerFeePercentage = ownerFeePercentage;
	}

	receive() external payable {
		uint256 ownerFee = (msg.value * i_ownerFeePercentage) / 100;
		uint256 artistFee = msg.value - ownerFee;

		i_owner.transfer(ownerFee);
		i_artist.transfer(artistFee);
	}

	function withdrawErc20(IERC20 tokenContract) external {
		uint256 balance = tokenContract.balanceOf(address(this));

		if (msg.sender != i_owner && msg.sender != i_artist) revert SplitFee__NotAuthorized();
		if (balance == 0) revert SplitFee__ZeroTokenBalance();

		uint256 ownerFee = (balance * i_ownerFeePercentage) / 100;
		uint256 artistFee = balance - ownerFee;

		tokenContract.transfer(i_owner, ownerFee);
		tokenContract.transfer(i_artist, artistFee);
	}
}