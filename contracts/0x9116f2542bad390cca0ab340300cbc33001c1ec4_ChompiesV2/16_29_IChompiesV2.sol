// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC721AUpgradeable} from "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";

interface IChompiesV2 is IERC721AUpgradeable {
    struct FRGPricing {
        uint256 og;
        uint256 molar;
        uint256 pub;
    }

    struct MintState {
        bool isPublicOpen;
        uint256 liveAt;
        uint256 expiresAt;
        uint256 maxSupply;
        uint256 totalSupply;
        uint256 ethPrice;
        FRGPricing frgPrices;
        uint256 minted;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external;

    function setOperatorFilteringEnabled(
        bool _operatorFilteringEnabled
    ) external;

    struct StakeConfiguration {
        string description;
        uint256[] og;
        uint256[] molar;
        uint256[] oneOfOne;
        uint256[] honorary;
        uint256[] bonusIntervals;
        uint256 periodDenominator;
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

    function setDelegationRegistry(address _delegationRegistryAddress) external;

    function setRewardsAddress(address _erc20RewardsAddress) external;

    function setStakeConfig(
        uint256 stakeId,
        StakeConfiguration calldata config
    ) external;

    function stakedInfoOf(
        uint256[] calldata tokenIds
    ) external view returns (bytes[] memory);

    function setOneOfOnes(uint256[] calldata _tokenIds, bool _flag) external;

    function setHonoraries(uint256[] calldata _tokenIds, bool _flag) external;
}