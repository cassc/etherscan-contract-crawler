pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Ferrum Staking interface for adding reward
 */
interface IFestakeRewardManager {
    /**
     * @dev legacy add reward. To be used by contract support time limitted rewards.
     */
    function addReward(uint256 rewardAmount) external returns (bool);

    /**
     * @dev withdraw rewards for the user.
     * The only option is to withdraw all rewards is one go.
     */
    function withdrawRewards() external returns (uint256);

    /**
     * @dev marginal rewards is to be used by contracts supporting ongoing rewards.
     * Send the reward to the contract address first.
     */
    function addMarginalReward() external returns (bool);

    function rewardToken() external view returns (IERC20);

    function rewardsTotal() external view returns (uint256);

    /**
     * @dev returns current rewards for an address
     */
    function rewardOf(address addr) external view returns (uint256);
}