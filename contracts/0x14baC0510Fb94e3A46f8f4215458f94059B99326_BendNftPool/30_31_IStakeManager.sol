// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;
import {IApeCoinStaking} from "./IApeCoinStaking.sol";
import {IRewardsStrategy} from "./IRewardsStrategy.sol";
import {IWithdrawStrategy} from "./IWithdrawStrategy.sol";
import {IStakedNft} from "./IStakedNft.sol";

interface IStakeManager {
    event FeeRatioChanged(uint256 newRatio);
    event FeeRecipientChanged(address newRecipient);
    event BotAdminChanged(address newAdmin);
    event RewardsStrategyChanged(address nft, address newStrategy);
    event WithdrawStrategyChanged(address newStrategy);
    event Compounded(bool isClaimCoinPool, uint256 claimedNfts);

    function stBayc() external view returns (IStakedNft);

    function stMayc() external view returns (IStakedNft);

    function stBakc() external view returns (IStakedNft);

    function totalStakedApeCoin() external view returns (uint256);

    function totalPendingRewards() external view returns (uint256);

    function totalRefund() external view returns (uint256 principal, uint256 reward);

    function refundOf(address nft_) external view returns (uint256 principal, uint256 reward);

    function stakedApeCoin(uint256 poolId_) external view returns (uint256);

    function pendingRewards(uint256 poolId_) external view returns (uint256);

    function pendingFeeAmount() external view returns (uint256);

    function fee() external view returns (uint256);

    function feeRecipient() external view returns (address);

    function updateFee(uint256 fee_) external;

    function updateFeeRecipient(address recipient_) external;

    // bot
    function updateBotAdmin(address bot_) external;

    // strategy
    function updateRewardsStrategy(address nft_, IRewardsStrategy rewardsStrategy_) external;

    function updateWithdrawStrategy(IWithdrawStrategy withdrawStrategy_) external;

    function withdrawApeCoin(uint256 required) external returns (uint256);

    function mintStNft(IStakedNft stNft_, address to_, uint256[] calldata tokenIds_) external;

    // staking
    function calculateFee(uint256 rewardsAmount_) external view returns (uint256 feeAmount);

    function stakeApeCoin(uint256 amount_) external;

    function unstakeApeCoin(uint256 amount_) external;

    function claimApeCoin() external;

    function stakeBayc(uint256[] calldata tokenIds_) external;

    function unstakeBayc(uint256[] calldata tokenIds_) external;

    function claimBayc(uint256[] calldata tokenIds_) external;

    function stakeMayc(uint256[] calldata tokenIds_) external;

    function unstakeMayc(uint256[] calldata tokenIds_) external;

    function claimMayc(uint256[] calldata tokenIds_) external;

    function stakeBakc(
        IApeCoinStaking.PairNft[] calldata baycPairs_,
        IApeCoinStaking.PairNft[] calldata maycPairs_
    ) external;

    function unstakeBakc(
        IApeCoinStaking.PairNft[] calldata baycPairs_,
        IApeCoinStaking.PairNft[] calldata maycPairs_
    ) external;

    function claimBakc(
        IApeCoinStaking.PairNft[] calldata baycPairs_,
        IApeCoinStaking.PairNft[] calldata maycPairs_
    ) external;

    function withdrawRefund(address nft_) external;

    function withdrawTotalRefund() external;

    struct NftArgs {
        uint256[] bayc;
        uint256[] mayc;
        IApeCoinStaking.PairNft[] baycPairs;
        IApeCoinStaking.PairNft[] maycPairs;
    }

    struct CompoundArgs {
        bool claimCoinPool;
        NftArgs claim;
        NftArgs unstake;
        NftArgs stake;
        uint256 coinStakeThreshold;
    }

    function compound(CompoundArgs calldata args_) external;
}