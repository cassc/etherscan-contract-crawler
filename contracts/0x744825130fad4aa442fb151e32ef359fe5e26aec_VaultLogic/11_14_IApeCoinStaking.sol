// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

interface IApeCoinStaking {
    struct SingleNft {
        uint32 tokenId;
        uint224 amount;
    }

    struct PairNft {
        uint128 mainTokenId;
        uint128 bakcTokenId;
    }

    struct PairNftDepositWithAmount {
        uint32 mainTokenId;
        uint32 bakcTokenId;
        uint184 amount;
    }
    struct PairNftWithdrawWithAmount {
        uint32 mainTokenId;
        uint32 bakcTokenId;
        uint184 amount;
        bool isUncommit;
    }
    struct Position {
        uint256 stakedAmount;
        int256 rewardsDebt;
    }

    struct Pool {
        uint48 lastRewardedTimestampHour;
        uint16 lastRewardsRangeIndex;
        uint96 stakedAmount;
        uint96 accumulatedRewardsPerShare;
        TimeRange[] timeRanges;
    }

    struct TimeRange {
        uint48 startTimestampHour;
        uint48 endTimestampHour;
        uint96 rewardsPerHour;
        uint96 capPerPosition;
    }

    struct PoolWithoutTimeRange {
        uint48 lastRewardedTimestampHour;
        uint16 lastRewardsRangeIndex;
        uint96 stakedAmount;
        uint96 accumulatedRewardsPerShare;
    }

    struct DashboardStake {
        uint256 poolId;
        uint256 tokenId;
        uint256 deposited;
        uint256 unclaimed;
        uint256 rewards24hr;
        DashboardPair pair;
    }

    struct DashboardPair {
        uint256 mainTokenId;
        uint256 mainTypePoolId;
    }

    struct PoolUI {
        uint256 poolId;
        uint256 stakedAmount;
        TimeRange currentTimeRange;
    }

    struct PairingStatus {
        uint248 tokenId;
        bool isPaired;
    }

    function mainToBakc(uint256 poolId_, uint256 mainTokenId_) external view returns (PairingStatus memory);

    function bakcToMain(uint256 poolId_, uint256 bakcTokenId_) external view returns (PairingStatus memory);

    function nftContracts(uint256 poolId_) external view returns (address);

    function rewardsBy(uint256 poolId_, uint256 from_, uint256 to_) external view returns (uint256, uint256);

    function apeCoin() external view returns (address);

    function getCurrentTimeRangeIndex(Pool memory pool_) external view returns (uint256);

    function getTimeRangeBy(uint256 poolId_, uint256 index_) external view returns (TimeRange memory);

    function getPoolsUI() external view returns (PoolUI memory, PoolUI memory, PoolUI memory, PoolUI memory);

    function getSplitStakes(address address_) external view returns (DashboardStake[] memory);

    function stakedTotal(address addr_) external view returns (uint256);

    function pools(uint256 poolId_) external view returns (PoolWithoutTimeRange memory);

    function nftPosition(uint256 poolId_, uint256 tokenId_) external view returns (Position memory);

    function addressPosition(address addr_) external view returns (Position memory);

    function pendingRewards(uint256 poolId_, address address_, uint256 tokenId_) external view returns (uint256);

    function depositBAYC(SingleNft[] calldata nfts_) external;

    function depositMAYC(SingleNft[] calldata nfts_) external;

    function depositBAKC(
        PairNftDepositWithAmount[] calldata baycPairs_,
        PairNftDepositWithAmount[] calldata maycPairs_
    ) external;

    function depositSelfApeCoin(uint256 amount_) external;

    function claimSelfApeCoin() external;

    function claimBAYC(uint256[] calldata nfts_, address recipient_) external;

    function claimMAYC(uint256[] calldata nfts_, address recipient_) external;

    function claimBAKC(PairNft[] calldata baycPairs_, PairNft[] calldata maycPairs_, address recipient_) external;

    function withdrawBAYC(SingleNft[] calldata nfts_, address recipient_) external;

    function withdrawMAYC(SingleNft[] calldata nfts_, address recipient_) external;

    function withdrawBAKC(
        PairNftWithdrawWithAmount[] calldata baycPairs_,
        PairNftWithdrawWithAmount[] calldata maycPairs_
    ) external;

    function withdrawSelfApeCoin(uint256 amount_) external;
}