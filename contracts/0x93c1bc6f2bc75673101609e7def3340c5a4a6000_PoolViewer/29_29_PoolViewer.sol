// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {IApeCoinStaking} from "../interfaces/IApeCoinStaking.sol";
import {INftVault} from "../interfaces/INftVault.sol";
import {ICoinPool} from "../interfaces/ICoinPool.sol";
import {INftPool, IStakedNft} from "../interfaces/INftPool.sol";
import {IStakeManager} from "../interfaces/IStakeManager.sol";
import {IWithdrawStrategy} from "../interfaces/IWithdrawStrategy.sol";
import {IBNFTRegistry} from "../interfaces/IBNFTRegistry.sol";

import {ApeStakingLib} from "../libraries/ApeStakingLib.sol";

contract PoolViewer {
    using ApeStakingLib for IApeCoinStaking;
    using Math for uint256;
    struct PoolState {
        uint256 coinPoolPendingApeCoin;
        uint256 coinPoolPendingRewards;
        uint256 coinPoolStakedAmount;
        uint256 baycPoolMaxCap;
        uint256 maycPoolMaxCap;
        uint256 bakcPoolMaxCap;
    }

    struct PendingRewards {
        uint256 coinPoolRewards;
        uint256 baycPoolRewards;
        uint256 maycPoolRewards;
        uint256 bakcPoolRewards;
    }

    IApeCoinStaking public immutable apeCoinStaking;
    IStakeManager public immutable staker;
    ICoinPool public immutable coinPool;
    IBNFTRegistry public immutable bnftRegistry;

    address public immutable bayc;
    address public immutable mayc;
    address public immutable bakc;

    constructor(
        IApeCoinStaking apeCoinStaking_,
        ICoinPool coinPool_,
        IStakeManager staker_,
        IBNFTRegistry bnftRegistry_
    ) {
        apeCoinStaking = apeCoinStaking_;
        coinPool = coinPool_;
        staker = staker_;
        bnftRegistry = bnftRegistry_;

        bayc = address(apeCoinStaking.bayc());
        mayc = address(apeCoinStaking.mayc());
        bakc = address(apeCoinStaking.bakc());
    }

    function viewPool() external view returns (PoolState memory poolState) {
        poolState.coinPoolPendingApeCoin = coinPool.pendingApeCoin();
        poolState.coinPoolPendingRewards = staker.pendingRewards(0);
        poolState.coinPoolStakedAmount = staker.stakedApeCoin(0);
        poolState.baycPoolMaxCap = apeCoinStaking.getCurrentTimeRange(ApeStakingLib.BAYC_POOL_ID).capPerPosition;
        poolState.maycPoolMaxCap = apeCoinStaking.getCurrentTimeRange(ApeStakingLib.MAYC_POOL_ID).capPerPosition;
        poolState.bakcPoolMaxCap = apeCoinStaking.getCurrentTimeRange(ApeStakingLib.BAKC_POOL_ID).capPerPosition;
    }

    function viewNftPoolPendingRewards(
        address nft_,
        uint256[] calldata tokenIds_
    ) external view returns (uint256 rewards) {
        uint256 poolId = apeCoinStaking.getNftPoolId(nft_);
        uint256 reward;
        for (uint256 i; i < tokenIds_.length; i++) {
            reward = apeCoinStaking.pendingRewards(poolId, address(0), tokenIds_[i]);
            rewards += reward;
        }
        rewards -= staker.calculateFee(rewards);
    }

    function viewBakcPairingStatus(
        uint256[] calldata baycTokenIds_,
        uint256[] calldata maycTokenIds_
    ) external view returns (bool[] memory baycPairs, bool[] memory maycPairs) {
        baycPairs = new bool[](baycTokenIds_.length);
        maycPairs = new bool[](maycTokenIds_.length);
        uint256 tokenId_;
        for (uint256 i = 0; i < baycTokenIds_.length; i++) {
            tokenId_ = baycTokenIds_[i];
            baycPairs[i] = apeCoinStaking.mainToBakc(ApeStakingLib.BAYC_POOL_ID, tokenId_).isPaired;
        }
        for (uint256 i = 0; i < maycTokenIds_.length; i++) {
            tokenId_ = maycTokenIds_[i];
            maycPairs[i] = apeCoinStaking.mainToBakc(ApeStakingLib.MAYC_POOL_ID, tokenId_).isPaired;
        }
    }

    function viewPoolPendingRewards() external view returns (PendingRewards memory rewards) {
        rewards.coinPoolRewards = staker.pendingRewards(ApeStakingLib.APE_COIN_POOL_ID);
        rewards.baycPoolRewards = staker.pendingRewards(ApeStakingLib.BAYC_POOL_ID);
        rewards.maycPoolRewards = staker.pendingRewards(ApeStakingLib.MAYC_POOL_ID);
        rewards.bakcPoolRewards = staker.pendingRewards(ApeStakingLib.BAKC_POOL_ID);
    }

    function viewUserPendingRewards(address userAddr_) external view returns (PendingRewards memory rewards) {
        rewards.coinPoolRewards = staker.pendingRewards(ApeStakingLib.APE_COIN_POOL_ID).mulDiv(
            coinPool.balanceOf(userAddr_),
            coinPool.totalSupply(),
            Math.Rounding.Down
        );

        rewards.baycPoolRewards = staker.pendingRewards(ApeStakingLib.BAYC_POOL_ID).mulDiv(
            getStakedNftCount(staker.stBayc(), userAddr_),
            staker.stBayc().totalStaked(address(staker)),
            Math.Rounding.Down
        );

        rewards.maycPoolRewards = staker.pendingRewards(ApeStakingLib.MAYC_POOL_ID).mulDiv(
            getStakedNftCount(staker.stMayc(), userAddr_),
            staker.stMayc().totalStaked(address(staker)),
            Math.Rounding.Down
        );

        rewards.bakcPoolRewards = staker.pendingRewards(ApeStakingLib.BAKC_POOL_ID).mulDiv(
            getStakedNftCount(staker.stBakc(), userAddr_),
            staker.stBakc().totalStaked(address(staker)),
            Math.Rounding.Down
        );
    }

    function getStakedNftCount(IStakedNft nft_, address userAddr_) public view returns (uint256 count) {
        for (uint256 i = 0; i < nft_.balanceOf(userAddr_); i++) {
            if (nft_.stakerOf(nft_.tokenOfOwnerByIndex(userAddr_, i)) == address(staker)) {
                count += 1;
            }
        }
        (address bnftProxy, ) = bnftRegistry.getBNFTAddresses(address(nft_));
        if (bnftProxy != address(0)) {
            IERC721Enumerable bnft = IERC721Enumerable(bnftProxy);
            for (uint256 i = 0; i < bnft.balanceOf(userAddr_); i++) {
                if (nft_.stakerOf(bnft.tokenOfOwnerByIndex(userAddr_, i)) == address(staker)) {
                    count += 1;
                }
            }
        }
    }
}