// contracts/RewardPoolFee.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract RewardPoolFee is Ownable {
	using SafeMath for uint256;
	address public rewardPoolAddress;
	uint256 public rewardPoolFee = 0; // 0 %

	/**
	 * @dev Calculates the fee that will go to the Game Reward Pool based on _amount.
	 */
	function getRewardPoolFeeAmount(uint256 _amount)
		public
		view
		returns (uint256)
	{
		return _amount.mul(rewardPoolFee).div(100);
	}

	/**
	 * @dev Changes the reward pool address {rewardPoolAddress} to {_rewardPoolAddress}.
	 */
	function setRewardPoolAddress(address _rewardPoolAddress) external onlyOwner {
		rewardPoolAddress = _rewardPoolAddress;
	}

	/**
	 * @dev Changes the reward pool fee (%) {rewardPoolFee} to {_rewardPoolAddress}.
	 */
	function setRewardPoolFee(uint256 _rewardPoolFee) external onlyOwner {
    require(_rewardPoolFee <= 5, "RewardPoolFee: max reward pool fee is 5%");
		rewardPoolFee = _rewardPoolFee;
	}
}