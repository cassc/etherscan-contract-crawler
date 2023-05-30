pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Ferrum Staking interface for adding reward
 */
interface IFestakeWithdrawer {

    event PaidOut(address indexed token, address indexed rewardToken, address indexed staker_, uint256 amount_, uint256 reward_);

    /**
     * @dev withdraws a certain amount and distributes rewards.
     */
    function withdraw(uint256 amount) external returns (bool);
}