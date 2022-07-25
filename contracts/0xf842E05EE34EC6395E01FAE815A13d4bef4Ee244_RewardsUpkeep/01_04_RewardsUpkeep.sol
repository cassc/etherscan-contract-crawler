// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILiquidityOps {
    function getReward() external returns (uint256[] memory data);

    function harvestRewards() external;
}

interface IRewardsManager {
    function distribute(address _token) external;
}

interface KeeperCompatibleInterface {
    /**
     * @notice method that is simulated by the keepers to see if any work actually
     * needs to be performed. This method does does not actually need to be
     * executable, and since it is only ever simulated it can consume lots of gas.
     * @dev To ensure that it is never called, you may want to add the
     * cannotExecute modifier from KeeperBase to your implementation of this
     * method.
     * @param checkData specified in the upkeep registration so it is always the
     * same for a registered upkeep. This can easily be broken down into specific
     * arguments using `abi.decode`, so multiple upkeeps can be registered on the
     * same contract and easily differentiated by the contract.
     * @return upkeepNeeded boolean to indicate whether the keeper should call
     * performUpkeep or not.
     * @return performData bytes that the keeper should call performUpkeep with, if
     * upkeep is needed. If you would like to encode data to decode later, try
     * `abi.encode`.
     */
    function checkUpkeep(bytes calldata checkData)
        external
        returns (bool upkeepNeeded, bytes memory performData);

    /**
     * @notice method that is actually executed by the keepers, via the registry.
     * The data returned by the checkUpkeep simulation will be passed into
     * this method to actually be executed.
     * @dev The input to this method should not be trusted, and the caller of the
     * method should not even be restricted to any single registry. Anyone should
     * be able call it, and the input should be validated, there is no guarantee
     * that the data passed in is the performData returned from checkUpkeep. This
     * could happen due to malicious keepers, racing keepers, or simply a state
     * change while the performUpkeep transaction is waiting for confirmation.
     * Always validate the data passed in.
     * @param performData is the data which was passed back from the checkData
     * simulation. If it is encoded, it can easily be decoded into other types by
     * calling `abi.decode`. This data should not be trusted, and should be
     * validated against the contract's current state.
     */
    function performUpkeep(bytes calldata performData) external;
}

contract RewardsUpkeep is KeeperCompatibleInterface, Ownable {
    // Rewards manager contract address
    IRewardsManager public rewardsManager;

    // Liquidity ops contract address
    ILiquidityOps public liquidityOps;

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
    event UpkeepPerformed(uint256 lastTimeStamp);
    event RewardTokensSet(address[] _rewardTokens);

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
        require(_interval >= 3600, "Under 1 hour");
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

    function setRewardTokens(address[] memory _rewardTokens) external onlyOwner {
        rewardTokens = _rewardTokens;

        emit RewardTokensSet(_rewardTokens);
    }

    // Called by Chainlink Keepers to check if upkeep should be executed
    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        performData = checkData;
    }

    // Called by Chainlink Keepers to distribute rewards
    function performUpkeep(bytes calldata) external override {
        require((block.timestamp - lastTimeStamp) > interval, "Too early");

        // Claim and harvest the underlying rewards
        liquidityOps.getReward();
        liquidityOps.harvestRewards();

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