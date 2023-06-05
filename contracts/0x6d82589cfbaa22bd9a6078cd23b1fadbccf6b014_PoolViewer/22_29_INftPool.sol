// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;
import {IApeCoinStaking} from "./IApeCoinStaking.sol";
import {IStakeManager} from "./IStakeManager.sol";
import {IStakedNft} from "./IStakedNft.sol";

interface INftPool {
    event NftRewardDistributed(address indexed nft, uint256 rewardAmount);

    event NftRewardClaimed(
        address indexed nft,
        uint256[] tokenIds,
        address indexed receiver,
        uint256 amount,
        uint256 rewardsDebt
    );

    event NftDeposited(address indexed nft, uint256[] tokenIds, address indexed owner);

    event NftWithdrawn(address indexed nft, uint256[] tokenIds, address indexed owner);

    struct PoolState {
        IStakedNft stakedNft;
        uint256 accumulatedRewardsPerNft;
        mapping(uint256 => uint256) rewardsDebt;
        uint256 pendingApeCoin;
    }

    struct PoolUI {
        uint256 totalStakedNft;
        uint256 accumulatedRewardsPerNft;
        uint256 pendingApeCoin;
    }

    function claimable(address[] calldata nfts_, uint256[][] calldata tokenIds_) external view returns (uint256);

    function staker() external view returns (IStakeManager);

    function deposit(address[] calldata nfts_, uint256[][] calldata tokenIds_) external;

    function withdraw(address[] calldata nfts_, uint256[][] calldata tokenIds_) external;

    function claim(address[] calldata nfts_, uint256[][] calldata tokenIds_) external;

    function receiveApeCoin(address nft_, uint256 rewardsAmount_) external;

    function compoundApeCoin(address nft_) external;

    function pendingApeCoin(address nft_) external view returns (uint256);

    function getPoolStateUI(address nft_) external view returns (PoolUI memory);

    function getNftStateUI(address nft_, uint256 tokenId) external view returns (uint256 rewardsDebt);
}