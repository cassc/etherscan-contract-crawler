// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title ApeCoin Staking Contract interface
interface IApeCoinStaking {
    struct SingleNft {
        uint32 tokenId;
        uint224 amount;
    }
    struct PairNftDepositWithAmount {
        uint32 mainTokenId;
        uint32 bakcTokenId;
        uint184 amount;
    }
    struct PairNft {
        uint128 mainTokenId;
        uint128 bakcTokenId;
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
    }

    struct TimeRange {
        uint48 startTimestampHour;
        uint48 endTimestampHour;
        uint96 rewardsPerHour;
        uint96 capPerPosition;
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

    function pools(uint256) external view returns (Pool memory);

    function bakcToMain(uint256, uint256) external view returns (PairingStatus memory);

    function nftPosition(uint256, uint256) external view returns (Position memory);

    function getPoolsUI()
        external
        view
        returns (
            PoolUI memory,
            PoolUI memory,
            PoolUI memory,
            PoolUI memory
        );

    function pendingRewards(
        uint256 _poolId,
        address _address,
        uint256 _tokenId
    ) external view returns (uint256);

    function getApeCoinStake(address _address) external view returns (DashboardStake memory);

    function getTimeRangeBy(uint256 _poolId, uint256 _index) external view returns (TimeRange memory);

    function depositApeCoin(uint256 _amount, address _recipient) external;

    function depositSelfApeCoin(uint256 _amount) external;

    function depositBAYC(SingleNft[] calldata _nfts) external;

    function depositMAYC(SingleNft[] calldata _nfts) external;

    function depositBAKC(PairNftDepositWithAmount[] calldata _baycPairs, PairNftDepositWithAmount[] calldata _maycPairs)
        external;

    function claimApeCoin(address _recipient) external;

    function claimSelfApeCoin() external;

    function claimBAYC(uint256[] calldata _nfts, address _recipient) external;

    function claimSelfBAYC(uint256[] calldata _nfts) external;

    function claimMAYC(uint256[] calldata _nfts, address _recipient) external;

    function claimSelfMAYC(uint256[] calldata _nfts) external;

    function claimBAKC(
        PairNft[] calldata _baycPairs,
        PairNft[] calldata _maycPairs,
        address _recipient
    ) external;

    function claimSelfBAKC(PairNft[] calldata _baycPairs, PairNft[] calldata _maycPairs) external;

    function withdrawApeCoin(uint256 _amount, address _recipient) external;

    function withdrawSelfApeCoin(uint256 _amount) external;

    function withdrawBAYC(SingleNft[] calldata _nfts, address _recipient) external;

    function withdrawSelfBAYC(SingleNft[] calldata _nfts) external;

    function withdrawMAYC(SingleNft[] calldata _nfts, address _recipient) external;

    function withdrawSelfMAYC(SingleNft[] calldata _nfts) external;

    function withdrawBAKC(
        PairNftWithdrawWithAmount[] calldata _baycPairs,
        PairNftWithdrawWithAmount[] calldata _maycPairs
    ) external;
}