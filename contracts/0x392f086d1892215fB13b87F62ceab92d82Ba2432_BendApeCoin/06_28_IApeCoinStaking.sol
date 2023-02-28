// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

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

    function getCurrentTimeRangeIndex(Pool memory pool) external view returns (uint256);

    function getTimeRangeBy(uint256 _poolId, uint256 _index) external view returns (TimeRange memory);

    function getPoolsUI()
        external
        view
        returns (
            PoolUI memory,
            PoolUI memory,
            PoolUI memory,
            PoolUI memory
        );

    function getSplitStakes(address _address) external view returns (DashboardStake[] memory);

    function stakedTotal(address _addr) external view returns (uint256);

    function pools(uint256 poolId) external view returns (Pool memory);

    function nftPosition(uint256 poolId, uint256 tokenId) external view returns (Position memory);

    function addressPosition(address addr) external view returns (Position memory);

    function pendingRewards(
        uint256 _poolId,
        address _address,
        uint256 _tokenId
    ) external view returns (uint256);

    function depositBAYC(SingleNft[] calldata _nfts) external;

    function depositMAYC(SingleNft[] calldata _nfts) external;

    function depositBAKC(PairNftDepositWithAmount[] calldata _baycPairs, PairNftDepositWithAmount[] calldata _maycPairs)
        external;

    function depositSelfApeCoin(uint256 _amount) external;

    function claimSelfApeCoin() external;

    function claimBAYC(uint256[] calldata _nfts, address _recipient) external;

    function claimMAYC(uint256[] calldata _nfts, address _recipient) external;

    function claimBAKC(
        PairNft[] calldata _baycPairs,
        PairNft[] calldata _maycPairs,
        address _recipient
    ) external;

    function withdrawBAYC(SingleNft[] calldata _nfts, address _recipient) external;

    function withdrawMAYC(SingleNft[] calldata _nfts, address _recipient) external;

    function withdrawBAKC(
        PairNftWithdrawWithAmount[] calldata _baycPairs,
        PairNftWithdrawWithAmount[] calldata _maycPairs
    ) external;

    function withdrawSelfApeCoin(uint256 _amount) external;
}