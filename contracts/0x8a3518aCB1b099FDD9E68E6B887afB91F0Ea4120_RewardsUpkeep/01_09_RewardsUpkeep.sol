// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../../interfaces/investments/frax-gauge/temple-frax/ILiquidityOps.sol";
import "../../../interfaces/investments/frax-gauge/temple-frax/IRewardsManager.sol";
import "../../../interfaces/investments/frax-gauge/tranche/ITranche.sol";
import "../../../interfaces/external/chainlink/IKeeperCompatibleInterface.sol";

interface IOldLiquidityOps {
    function getReward() external returns (uint256[] memory data);
    function harvestRewards() external;
}

/// @notice A Chainlink Keeper contract which can automate collection & distribution of
///         rewards on a periodic basis
contract RewardsUpkeep is IKeeperCompatibleInterface, Ownable {
    // Rewards manager contract address
    IRewardsManager public rewardsManager;

    // Liquidity ops contract address
    ILiquidityOps public liquidityOps;

    // The old liquidity ops contract - we need to harvest rewards
    // from here until the TVL is migrated into the new one.
    IOldLiquidityOps public oldLiquidityOps;

    // Time interval between distributions
    uint256 public interval;

    // Last distribution time
    uint256 public lastTimeStamp;

    // The list of reward token addresses to distribute.
    // This may be direct gauge rewards, and also extra protocol rewards.
    address[] public rewardTokens;

    event IntervalSet(uint256 _interval);
    event RewardsManagerSet(address _rewardsManager);
    event LiquidityOpsSet(address _liquidityOps);
    event OldLiquidityOpsSet(address _liquidityOps);
    event UpkeepPerformed(uint256 lastTimeStamp);
    event RewardTokensSet(address[] _rewardTokens);

    error NotLongEnough(uint256 minExpected);

    constructor(
        uint256 _updateInterval,
        address _rewardsManager,
        address _liquidityOps
    ) {
        interval = _updateInterval;
        rewardsManager = IRewardsManager(_rewardsManager);
        liquidityOps = ILiquidityOps(_liquidityOps);
    }

    function setInterval(uint256 _interval) external onlyOwner {
        if (_interval < 3600) revert NotLongEnough(3600);
        interval = _interval;

        emit IntervalSet(_interval);
    }

    function setRewardsManager(address _rewardsManager) external onlyOwner {
        rewardsManager = IRewardsManager(_rewardsManager);

        emit RewardsManagerSet(_rewardsManager);
    }

    function setLiquidityOps(address _liquidityOps) external onlyOwner {
        liquidityOps = ILiquidityOps(_liquidityOps);

        emit LiquidityOpsSet(_liquidityOps);
    }

    function setOldLiquidityOps(address _oldLiquidityOps) external onlyOwner {
        oldLiquidityOps = IOldLiquidityOps(_oldLiquidityOps);

        emit OldLiquidityOpsSet(_oldLiquidityOps);
    }

    function setRewardTokens(address[] memory _rewardTokens) external onlyOwner {
        rewardTokens = _rewardTokens;

        emit RewardTokensSet(_rewardTokens);
    }

    // Called by Chainlink Keepers to check if upkeep should be executed
    function checkUpkeep(bytes calldata)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        address[] memory tranches = liquidityOps.allTranches();

        // First get the number of active tranches, to create the fixed size array
        uint256 numActive;
        for (uint256 i=0; i<tranches.length; i++) {
            if (!ITranche(tranches[i]).disabled()) {
                numActive++;
            }
        }

        // Now create and fill the activeTranches
        uint256 index;
        address[] memory activeTranches = new address[](numActive);
        for (uint256 i=0; i<tranches.length; i++) {
            if (!ITranche(tranches[i]).disabled()) {
                activeTranches[index] = tranches[i];
                index++;
            }
        }

        performData = abi.encode(activeTranches);
    }

    // Called by Chainlink Keepers to distribute rewards
    function performUpkeep(bytes calldata performData) external override {
        if ((block.timestamp - lastTimeStamp) <= interval) revert NotLongEnough(interval);
        (address[] memory activeTranches) = abi.decode(performData, (address[]));

        // Claim and harvest the underlying rewards
        liquidityOps.getRewards(activeTranches);
        liquidityOps.harvestRewards();

        // Support harvesting from the old liquidity ops and sending to the 
        // current rewards manager.
        // Rewards from both the old and the current liquidity ops are harvested
        // to the same rewards manager.
        if (address(oldLiquidityOps) != address(0)) {
            oldLiquidityOps.getReward();
            oldLiquidityOps.harvestRewards();
        }

        // Loop through and distribute reward tokens
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            uint256 rewardBalance = IERC20(rewardTokens[i]).balanceOf(address(rewardsManager));
            if (rewardBalance > 0) {
                rewardsManager.distribute(rewardTokens[i]);
            }
        }

        lastTimeStamp = block.timestamp;
        emit UpkeepPerformed(lastTimeStamp);
    }
}