// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/IERC20.sol';

contract Withdrawable is Ownable {
	/**
	 * Withdraw ERC20 from contract to owner address
	 * @param contractAddress addres of ERC20 contract
	 * @notice any ERC20 token can be withdrawed
	 * @notice only owner can withdraw
	 */
	function withdrawERC20(address contractAddress) external onlyOwner {
		uint256 balance = IERC20(contractAddress).balanceOf(address(this));
		bool succeded = IERC20(contractAddress).transfer(msg.sender, balance);
		require(succeded, 'Withdrawable: Transfer did not happen');
	}

	/**
	 * Withdraw ETH from contract to owner address
	 * @notice only owner can withdraw
	 */
	function withdrawETH() external onlyOwner {
		(bool sent, ) = msg.sender.call{value: address(this).balance}('');
		require(sent, 'Failed to withdraw ETH');
	}
}