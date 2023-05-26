// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DevFund {
    /// --- External contracts

    // token to be awarded as reward to holders
    IERC20 public rewardToken;

    // token to claim rewards
    IERC20 public holderToken;

    /// --- Storage

    // total reward on contract
    uint256 public totalReward;

    // previously seen reward balance on contract
    uint256 public prevBalance;

    // User's address => Reward at time of withdraw
    mapping(address => uint256) public rewardAtTimeOfWithdraw;

    // User's address => Reward which can be withdrawn
    mapping(address => uint256) public owed;

    /**
     * @dev Contract constructor sets reward token address.
     */
    constructor(address _rewardToken) {
        rewardToken = IERC20(_rewardToken);
    }

    /**
     * @dev Setup function sets dev holder token address and owner, callable only once.
     * @param _holderToken Dev holder Token address.
     */
    function setup(address _holderToken) external returns (bool){
        require(address(holderToken) == address(0), "DevFund: already setup");

        holderToken = IERC20(_holderToken);

        return true;
    }

    /// --- Contract functions

    /**
     * @dev Withdraws reward for holder. Returns reward.
     */
    function withdrawReward() public returns (uint256) {
        updateTotalReward();
        uint256 value = calcReward(msg.sender) + owed[msg.sender];
        rewardAtTimeOfWithdraw[msg.sender] = totalReward;
        owed[msg.sender] = 0;

        require(value > 0, "DevFund: withdrawReward nothing to transfer");

        rewardToken.transfer(msg.sender, value);

        prevBalance = rewardToken.balanceOf(address(this));

        return value;
    }

    /**
     * @dev Credits reward to owed balance.
     * @param forAddress holder's address.
     */
    function softWithdrawRewardFor(address forAddress) external returns (uint256){
        updateTotalReward();
        uint256 value = calcReward(forAddress);
        rewardAtTimeOfWithdraw[forAddress] = totalReward;
        owed[forAddress] += value;

        return value;
    }

    /**
     * @dev View remaining reward for an address.
     * @param forAddress holder's address.
     */
    function rewardFor(address forAddress) public view returns (uint256) {
        uint256 _currentBalance = rewardToken.balanceOf(address(this));
        uint256 _totalReward = totalReward +
        (_currentBalance > prevBalance ? _currentBalance - prevBalance : 0);
        return
        owed[forAddress] +
        (holderToken.balanceOf(forAddress) *
        (_totalReward - rewardAtTimeOfWithdraw[forAddress])) /
        holderToken.totalSupply();
    }

    /**
     * @dev if we got some tokens update the totalReward, has to be called on every withdraw
     */
    function updateTotalReward() internal returns (uint256) {
        uint256 currentBalance = rewardToken.balanceOf(address(this));
        if (currentBalance > prevBalance) {
            totalReward += currentBalance - prevBalance;
        }
        return totalReward;
    }

    /**
     * @dev Compute reward for holder. Returns reward.
     * @param forAddress holder address.
     */
    function calcReward(address forAddress) internal view returns (uint256) {
        return
        (holderToken.balanceOf(forAddress) *
        (totalReward - rewardAtTimeOfWithdraw[forAddress])) /
        holderToken.totalSupply();
    }

    // 0 ETH transfers to trigger withdrawReward
    fallback() external {withdrawReward();}
}