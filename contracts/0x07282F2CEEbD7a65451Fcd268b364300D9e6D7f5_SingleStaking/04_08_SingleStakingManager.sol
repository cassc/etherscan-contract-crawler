// SPDX-License-Identifier: MIT
// @author Pendle Labs - pendle.finance
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./SingleStaking.sol";

contract SingleStakingManager is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public immutable pendle;
    address public immutable stakingContract;

    uint256 public rewardPerBlock;
    uint256 public finishedDistToBlock;

    constructor(
        IERC20 _pendle,
        uint256 _rewardPerBlock,
        uint256 _startBlock
    ) {
        require(address(_pendle) != address(0), "ZERO_ADDRESS");
        require(_rewardPerBlock != 0, "ZERO_REWARD_PER_BLOCK");
        require(_startBlock > block.number, "PAST_BLOCK_START");
        pendle = _pendle;
        rewardPerBlock = _rewardPerBlock;
        stakingContract = address(new SingleStaking(_pendle));
        finishedDistToBlock = _startBlock;
    }

    function distributeRewards() external {
        require(msg.sender == stakingContract, "NOT_STAKING_CONTRACT");
        _distributeRewardsInternal();
    }

    function adjustRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        _distributeRewardsInternal(); // distribute until the latest block first

        rewardPerBlock = _rewardPerBlock;
    }

    function getBlocksLeft() public view returns (uint256 blocksLeft) {
        uint256 currentRewardBalance = pendle.balanceOf(address(this));
        blocksLeft = currentRewardBalance.div(rewardPerBlock);
    }

    // Distribute the rewards to the staking contract, until the latest block, or until we run out of rewards
    function _distributeRewardsInternal() internal {
        if (finishedDistToBlock >= block.number) return;
        uint256 blocksToDistribute = min(block.number.sub(finishedDistToBlock), getBlocksLeft());
        finishedDistToBlock += blocksToDistribute;

        pendle.safeTransfer(stakingContract, blocksToDistribute.mul(rewardPerBlock));
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}