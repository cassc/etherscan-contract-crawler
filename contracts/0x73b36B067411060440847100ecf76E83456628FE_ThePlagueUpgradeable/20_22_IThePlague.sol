// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IThePlague is IERC721Upgradeable {
    struct StakeConfiguration {
        string description;
        /// First is default, followed by bonusIntervals rates
        uint256[] periodEmissions;
        // Minimum intervals (interval * denominator) to begin bonus emissions
        uint256[] bonusIntervals;
        // Duration of a single period (e.g, 1...30 days)
        uint256 periodDenominator;
        // Whether or not the current bonus works retroactively
        // e.g, Lock in 12 months gives 4x bonus but only multiplies the base reward after 12 months
        bool isRetroactiveBonus;
        // Minimum stake period (e.g, 1...365...x days)
        uint256 minimumStakePeriod;
    }

    // Pack struct for some gas savings
    struct StakedToken {
        uint16 configId;
        uint120 stakedAt;
        uint120 claimedAt;
    }

    event Stake(uint256 indexed tokenId);

    event Unstake(
        uint256 indexed tokenId,
        uint256 stakedAtTimestamp,
        uint256 removedFromStakeAtTimestamp
    );

    function totalSupply() external view returns (uint256);

    function stake(uint256[] calldata tokenIds) external;

    function delegatedStake(
        uint256[] calldata tokenIds,
        address vault
    ) external;

    function stakeByConfigId(
        uint256 configId,
        uint256[] calldata tokenIds
    ) external;

    function delegatedStakeByConfigId(
        uint256 configId,
        uint256[] calldata tokenIds,
        address vault
    ) external;

    function unstake(uint256[] calldata tokenIds) external;

    function delegatedUnstake(
        uint256[] calldata tokenIds,
        address vault
    ) external;

    function migrateTokens(
        uint256[] calldata tokenIds,
        address[] calldata owners,
        StakedToken[] calldata stakedTokens
    ) external;

    function setDelegationRegistry(address _delegationRegistryAddress) external;

    function setRewardsAddress(address _erc20RewardsAddress) external;

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external;

    function setOperatorFilteringEnabled(
        bool _operatorFilteringEnabled
    ) external;

    function setStakeConfig(
        uint256 stakeId,
        StakeConfiguration calldata config
    ) external;

    function stakedInfoOf(
        uint256[] calldata tokenIds
    ) external view returns (bytes[] memory);
}