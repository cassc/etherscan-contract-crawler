// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "./MultiRewards.sol";

contract Leaderboard is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @notice 100% in BPS
    uint256 public constant BPS_DENOMINATOR = 10_000;

    /// @notice UniswapRouter
    IUniswapV2Router02 public immutable router;

    /// @notice Staking contract
    MultiRewards public stakingRewards;
    /// @notice The proportion in BPS of the buyback that goes towards reward
    /// distrubtion. The rest of the buyback remains in this contract.
    uint256 public buybackProportion;
    /// @notice The reward token with the most votes from the latest epoch run.
    /// This gets reset after a buyback.
    address public winningRewardToken;

    event BuybackExecuted(address indexed token, uint256 amount);
    event BuybackProportionChanged(
        uint256 prevBuybackProportion,
        uint256 nextBuybackProportion
    );
    event StakingRewardsChanged(
        address prevStakingRewards,
        address nextStakingRewards
    );
    event Recovered(address token, uint256 amount);
    event RecoveredETH(uint256 amount);

    constructor(
        MultiRewards _stakingRewards,
        IUniswapV2Router02 _router,
        uint256 _buybackProportion
    ) {
        stakingRewards = _stakingRewards;
        router = _router;
        buybackProportion = _buybackProportion;
    }

    /// @notice Change the buybackProportion
    /// @param _buybackProportion The new buybackProportion
    function setBuybackProportion(uint256 _buybackProportion)
        external
        onlyOwner
    {
        require(
            _buybackProportion <= BPS_DENOMINATOR,
            "_buybackProportion too large"
        );
        emit BuybackProportionChanged(buybackProportion, _buybackProportion);
        buybackProportion = _buybackProportion;
    }

    /// @notice Change the stakingRewards
    /// @param _stakingRewards The new stakingRewards
    function setStakingRewards(address _stakingRewards) external onlyOwner {
        emit StakingRewardsChanged(address(stakingRewards), _stakingRewards);
        stakingRewards = MultiRewards(_stakingRewards);
    }

    /// @notice Run the epoch
    function runEpoch() external onlyOwner {
        uint256 rewardTokensCount = stakingRewards.rewardTokensCount();
        require(rewardTokensCount > 0, "No reward tokens");
        address _winningRewardToken;
        uint256 _winningVotes;
        for (uint256 i; i < rewardTokensCount; i++) {
            address rewardToken = stakingRewards.rewardTokens(i);
            uint256 votes = stakingRewards.tokenToVotes(rewardToken);
            if (_winningRewardToken == address(0) || votes > _winningVotes) {
                _winningRewardToken = rewardToken;
                _winningVotes = votes;
            }
        }
        winningRewardToken = _winningRewardToken;
    }

    /// @notice Finalize the epoch with a buyback
    /// @param minOut Minimum amount of tokens received from the buyback. Used for slippage protection
    function buyback(uint256 minOut) external onlyOwner {
        buybackSpecificETH(minOut, address(this).balance);
    }

    // /// @notice Finalize the epoch with a buyback and a specific ETH amount to use
    // /// @param minOut Minimum amount of tokens received from the buyback. Used for slippage protection
    // /// @param ethAmount Amount of ETH to use
    function buybackSpecificETH(uint256 minOut, uint256 ethAmount)
        public
        onlyOwner
    {
        require(winningRewardToken != address(0), "No winning reward token");
        require(ethAmount <= address(this).balance, "ethAmount too large");
        if (ethAmount > 0) {
            address[] memory path = new address[](2);
            path[0] = router.WETH();
            path[1] = winningRewardToken;
            router.swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: ethAmount
            }(minOut, path, address(this), block.timestamp);
        }
        uint256 transferAmount = IERC20(winningRewardToken)
            .balanceOf(address(this))
            .mul(buybackProportion)
            .div(BPS_DENOMINATOR);
        IERC20(winningRewardToken).approve(
            address(stakingRewards),
            transferAmount
        );
        stakingRewards.notifyRewardAmount(winningRewardToken, transferAmount);
        emit BuybackExecuted(winningRewardToken, transferAmount);

        // Reset
        winningRewardToken = address(0);
    }

    /* ========== MultiRewards management ========== */

    /// @notice Manually notify rewards. The rewardsToken must already be in
    /// this contract.
    /// @param rewardsToken The reward token to notify
    /// @param reward The amount of rewards to distrubute over the rewardsDuration
    function notifyRewardAmount(address rewardsToken, uint256 reward)
        external
        onlyOwner
    {
        IERC20(rewardsToken).approve(address(stakingRewards), reward);
        stakingRewards.notifyRewardAmount(rewardsToken, reward);
    }

    /// @notice Update a reward token's reward duration.
    /// @param rewardsToken The reward token to notify
    /// @param rewardsDuration The new rewards duration
    function setRewardsDuration(address rewardsToken, uint256 rewardsDuration)
        external
        onlyOwner
    {
        stakingRewards.setRewardsDuration(rewardsToken, rewardsDuration);
    }

    /* ========== Emergency recovery ========== */

    /// @notice Emergency token recovery
    /// @param tokenAddress The ERC20 token to recover
    /// @param tokenAmount The amount to recover
    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        onlyOwner
    {
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    /// @notice Emergency ETH recovery
    /// @param amount The amount to recover
    function recoverETH(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
        emit RecoveredETH(amount);
    }

    receive() external payable {}
}