// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import { Ownable } from "@openzeppelin/contracts-0.8/access/Ownable.sol";
import "./WmxRewardPoolV2.sol";

/**
 * @title   RewardFactory
 * @author  ConvexFinance -> WombexFinance
 * @notice  Used to deploy reward pools when a new pool is added to the Booster
 *          contract. This contract deploys BaseRewardPool that handles CRV rewards for guages
 */
contract WmxRewardPoolFactory is Ownable {
    address public immutable stakingToken;
    address public immutable rewardToken;
    address public immutable rewardManager;
    address public immutable wmxLocker;
    address public immutable penaltyForwarder;
    address[] public depositors;
    address[] public pools;

    event DepositorsUpdate(address[] depositor);
    event RewardPoolCreated(address rewardPool, uint256 startDelay, uint256 duration, uint256 maxCap);

    /**
     * @param _stakingToken  Pool LP token
     * @param _rewardToken   $WMX
     * @param _rewardManager Depositor
     * @param _wmxLocker    $WMX lock contract
     * @param _penaltyForwarder Address to which penalties are sent
     */
    constructor(
        address _stakingToken,
        address _rewardToken,
        address _rewardManager,
        address _wmxLocker,
        address _penaltyForwarder,
        address[] memory _depositors
    ) public {
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
        rewardManager = _rewardManager;
        wmxLocker = _wmxLocker;
        penaltyForwarder = _penaltyForwarder;
        depositors = _depositors;
    }

    function updateDepositors(address[] calldata _depositors) external onlyOwner {
        depositors = _depositors;

        emit DepositorsUpdate(depositors);
    }

    /**
     * @notice Create a Managed Reward Pool to handle distribution of all crv/wom mined in a pool
     */
    function CreateWmxRewardPoolV2(uint256 _startDelay, uint256 _duration, uint256 _maxCap) external onlyOwner returns (address) {
        WmxRewardPoolV2 rewardPool = new WmxRewardPoolV2(stakingToken, rewardToken, rewardManager, wmxLocker, penaltyForwarder, _startDelay, _duration, _maxCap, depositors);

        emit RewardPoolCreated(address(rewardPool), _startDelay, _duration, _maxCap);
        pools.push(address(rewardPool));
        return address(rewardPool);
    }

    function getCreatedPools() external view returns (address[] memory) {
        return pools;
    }
}