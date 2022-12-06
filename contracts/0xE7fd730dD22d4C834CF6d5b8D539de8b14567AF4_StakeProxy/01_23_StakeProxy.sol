// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// fix issue "@openzeppelin/contracts/utils/Address.sol:191: Use of delegatecall is not allowed"
// refer: https://forum.openzeppelin.com/t/spurious-issue-from-non-upgradeable-initializable-sol/30570/6
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import {IStakeProxy, DataTypes, IApeCoinStaking} from "./interfaces/IStakeProxy.sol";
import {IBNFT} from "./interfaces/IBNFT.sol";
import {PercentageMath} from "./libraries/PercentageMath.sol";

contract StakeProxy is IStakeProxy, Initializable, Ownable, ReentrancyGuard, ERC721Holder {
    using DataTypes for DataTypes.BakcStaked;
    using DataTypes for DataTypes.CoinStaked;
    using SafeERC20 for IERC20;
    using PercentageMath for uint256;
    using SafeCast for uint256;
    using SafeCast for int256;

    uint256 public override version;

    mapping(address => uint256) public pendingRewards;
    mapping(address => uint256) public pendingWithdraw;

    DataTypes.ApeStaked private _apeStaked;
    DataTypes.BakcStaked private _bakcStaked;
    DataTypes.CoinStaked private _coinStaked;

    bool public override unStaked;
    uint256 public override poolId;

    IERC721 public override bayc;
    IERC721 public override mayc;
    IERC721 public override bakc;
    IERC20 public override apeCoin;

    IApeCoinStaking public override apeStaking;

    modifier onlyStaker(address staker) {
        require(
            staker == _apeStaked.staker || staker == _bakcStaked.staker || staker == _coinStaked.staker,
            "StakeProxy: not valid staker"
        );
        _;
    }

    function initialize(
        address owner_,
        address bayc_,
        address mayc_,
        address bakc_,
        address apeCoin_,
        address apeCoinStaking_
    ) external override initializer {
        _transferOwnership(owner_);
        bayc = IERC721(bayc_);
        mayc = IERC721(mayc_);
        bakc = IERC721(bakc_);
        apeCoin = IERC20(apeCoin_);
        apeStaking = IApeCoinStaking(apeCoinStaking_);
        version = 1;
    }

    function apeStaked() external view returns (DataTypes.ApeStaked memory) {
        return _apeStaked;
    }

    function bakcStaked() external view returns (DataTypes.BakcStaked memory) {
        return _bakcStaked;
    }

    function coinStaked() external view returns (DataTypes.CoinStaked memory) {
        return _coinStaked;
    }

    function claimable(address staker, uint256 fee) external view override returns (uint256) {
        uint256 tokenId;
        if (poolId == DataTypes.BAKC_POOL_ID) {
            tokenId = _bakcStaked.tokenId;
        } else {
            tokenId = _apeStaked.tokenId;
        }

        uint256 rewardsToBeClaimed = apeStaking.pendingRewards(poolId, address(this), tokenId);

        (uint256 apeRewards, uint256 bakcRewards, uint256 coinRewards) = _computeRewards(rewardsToBeClaimed);

        uint256 stakerRewards = pendingRewards[staker];
        if (staker == _apeStaked.staker) {
            stakerRewards += apeRewards;
        }

        if (staker == _bakcStaked.staker) {
            stakerRewards += bakcRewards;
        }
        if (staker == _coinStaked.staker) {
            stakerRewards += coinRewards;
        }
        return stakerRewards - stakerRewards.percentMul(fee);
    }

    function withdrawable(address staker) external view override returns (uint256) {
        return pendingWithdraw[staker];
    }

    function unStake() external override onlyOwner nonReentrant {
        require(poolId != 0, "StakeProxy: no staking at all");
        require(!unStaked, "StakeProxy: already unStaked");
        require(
            IERC721(_apeStaked.collection).ownerOf(_apeStaked.tokenId) == address(this),
            "StakeProxy: not ape owner"
        );
        uint256 coinAmount = _totalStaked();
        uint256 preBalance = apeCoin.balanceOf(address(this));

        if (_isSingleBaycPool() || _isSingleMaycPool()) {
            IApeCoinStaking.SingleNft[] memory nfts = new IApeCoinStaking.SingleNft[](1);
            nfts[0] = IApeCoinStaking.SingleNft({
                tokenId: _apeStaked.tokenId.toUint32(),
                amount: coinAmount.toUint224()
            });
            if (_isSingleBaycPool()) {
                apeStaking.withdrawBAYC(nfts, address(this));
            } else {
                apeStaking.withdrawMAYC(nfts, address(this));
            }
        }

        if (_isPairedBaycPool() || _isPairedMaycPool()) {
            IApeCoinStaking.PairNftWithdrawWithAmount[] memory nfts = new IApeCoinStaking.PairNftWithdrawWithAmount[](
                1
            );
            nfts[0] = IApeCoinStaking.PairNftWithdrawWithAmount({
                mainTokenId: _apeStaked.tokenId.toUint32(),
                bakcTokenId: _bakcStaked.tokenId.toUint32(),
                amount: coinAmount.toUint184(),
                isUncommit: true
            });
            IApeCoinStaking.PairNftWithdrawWithAmount[] memory emptyNfts;
            if (_isPairedBaycPool()) {
                apeStaking.withdrawBAKC(nfts, emptyNfts);
            } else {
                apeStaking.withdrawBAKC(emptyNfts, nfts);
            }
        }

        pendingWithdraw[_apeStaked.staker] += _apeStaked.coinAmount;
        if (_bakcStaked.staker != address(0)) {
            pendingWithdraw[_bakcStaked.staker] += _bakcStaked.coinAmount;
        }
        if (_coinStaked.staker != address(0)) {
            pendingWithdraw[_coinStaked.staker] += _coinStaked.coinAmount;
        }
        // withdraw from ape staking will receive staked principal and rewards
        uint256 rewardsAmount = apeCoin.balanceOf(address(this)) - preBalance - coinAmount;
        _allocateRewards(rewardsAmount);
        unStaked = true;

        // transfer nft back to owner
        IERC721(_apeStaked.collection).safeTransferFrom(address(this), owner(), _apeStaked.tokenId);
    }

    function stake(
        DataTypes.ApeStaked memory apeStaked_,
        DataTypes.BakcStaked memory bakcStaked_,
        DataTypes.CoinStaked memory coinStaked_
    ) external override onlyOwner nonReentrant {
        require(
            apeStaked_.collection == address(bayc) || apeStaked_.collection == address(mayc),
            "StakeProxy: invalid ape collection"
        );
        require(
            IERC721(apeStaked_.collection).ownerOf(apeStaked_.tokenId) == address(this),
            "StakeProxy: not ape owner"
        );
        if (bakcStaked_.staker != address(0)) {
            require(bakc.ownerOf(bakcStaked_.tokenId) == address(this), "StakeProxy: not bakc owner");
            poolId = DataTypes.BAKC_POOL_ID;
        } else {
            if (apeStaked_.collection == address(bayc)) {
                poolId = DataTypes.BAYC_POOL_ID;
            } else {
                poolId = DataTypes.MAYC_POOL_ID;
            }
        }

        // save storage
        _apeStaked = apeStaked_;
        _bakcStaked = bakcStaked_;
        _coinStaked = coinStaked_;

        uint256 coinAmount = _totalStaked();

        // do the ape staking
        apeCoin.safeApprove(address(apeStaking), coinAmount);
        if (_isPairedBaycPool() || _isPairedMaycPool()) {
            // block partially stake from official contract
            require(
                apeStaking.nftPosition(poolId, bakcStaked_.tokenId).stakedAmount == 0,
                "StakeProxy: bakc already staked"
            );

            IApeCoinStaking.PairNftDepositWithAmount[] memory nfts = new IApeCoinStaking.PairNftDepositWithAmount[](1);
            nfts[0] = IApeCoinStaking.PairNftDepositWithAmount({
                mainTokenId: apeStaked_.tokenId.toUint32(),
                bakcTokenId: bakcStaked_.tokenId.toUint32(),
                amount: coinAmount.toUint184()
            });
            IApeCoinStaking.PairNftDepositWithAmount[] memory emptyNfts;
            if (_isPairedBaycPool()) {
                apeStaking.depositBAKC(nfts, emptyNfts);
            } else {
                apeStaking.depositBAKC(emptyNfts, nfts);
            }
        } else {
            // block partially stake from official contract
            require(
                apeStaking.nftPosition(poolId, apeStaked_.tokenId).stakedAmount == 0,
                "StakeProxy: ape already staked"
            );

            IApeCoinStaking.SingleNft[] memory nfts = new IApeCoinStaking.SingleNft[](1);
            nfts[0] = IApeCoinStaking.SingleNft({
                tokenId: apeStaked_.tokenId.toUint32(),
                amount: coinAmount.toUint224()
            });
            if (_apeStaked.collection == address(bayc)) {
                apeStaking.depositBAYC(nfts);
            } else {
                apeStaking.depositMAYC(nfts);
            }
        }
        apeCoin.safeApprove(address(apeStaking), 0);

        // transfer nft back to owner
        IERC721(apeStaked_.collection).safeTransferFrom(address(this), owner(), apeStaked_.tokenId);
    }

    function claim(
        address staker,
        uint256 fee,
        address feeRecipient
    ) external override onlyOwner onlyStaker(staker) nonReentrant returns (uint256 toStaker, uint256 toFee) {
        _claim();
        toStaker = pendingRewards[staker];
        pendingRewards[staker] = 0;
        toFee = toStaker.percentMul(fee);
        if (toFee > 0 && feeRecipient != address(0)) {
            apeCoin.safeTransfer(feeRecipient, toFee);
            toStaker -= toFee;
        }
        if (toStaker > 0) {
            apeCoin.safeTransfer(staker, toStaker);
        }
    }

    function withdraw(address staker)
        external
        override
        onlyOwner
        onlyStaker(staker)
        nonReentrant
        returns (uint256 amount)
    {
        require(unStaked, "StakeProxy: can't withdraw");

        amount = pendingWithdraw[staker];
        pendingWithdraw[staker] = 0;
        apeCoin.safeTransfer(staker, amount);

        if (
            poolId == DataTypes.BAKC_POOL_ID && // must be bakc pool
            staker == _bakcStaked.staker && // staker must be bakc staker
            bakc.ownerOf(_bakcStaked.tokenId) == address(this) // bakc must not withdrawn
        ) {
            bakc.safeTransferFrom(address(this), _bakcStaked.staker, _bakcStaked.tokenId);
        }
    }

    function migrateERC20(
        address token,
        address to,
        uint256 amount
    ) external override onlyOwner nonReentrant {
        IERC20(token).safeTransfer(to, amount);
    }

    function migrateERC721(
        address token,
        address to,
        uint256 tokenId
    ) external override onlyOwner nonReentrant {
        IERC721(token).safeTransferFrom(address(this), to, tokenId);
    }

    function _allocateRewards(uint256 rewardsAmount) internal {
        (uint256 apeRewards, uint256 bakcRewards, uint256 coinRewards) = _computeRewards(rewardsAmount);
        pendingRewards[_apeStaked.staker] += apeRewards;
        pendingRewards[_bakcStaked.staker] += bakcRewards;
        pendingRewards[_coinStaked.staker] += coinRewards;
    }

    function _computeRewards(uint256 rewardsAmount)
        internal
        view
        returns (
            uint256 apeRewards,
            uint256 bakcRewards,
            uint256 coinRewards
        )
    {
        if (rewardsAmount > 0) {
            apeRewards = rewardsAmount.percentMul(_apeStaked.share);
            bakcRewards = rewardsAmount.percentMul(_bakcStaked.share);
            coinRewards = rewardsAmount - apeRewards - bakcRewards;
        }
    }

    function _claim() internal {
        if (!unStaked) {
            require(
                IERC721(_apeStaked.collection).ownerOf(_apeStaked.tokenId) == address(this),
                "StakeProxy: not ape owner"
            );
            uint256 preBalance = apeCoin.balanceOf(address(this));
            if (_isSingleBaycPool() || _isSingleMaycPool()) {
                uint256[] memory nfts = new uint256[](1);
                nfts[0] = _apeStaked.tokenId;
                if (_isSingleBaycPool()) {
                    apeStaking.claimBAYC(nfts, address(this));
                } else {
                    apeStaking.claimMAYC(nfts, address(this));
                }
            }

            if (_isPairedBaycPool() || _isPairedMaycPool()) {
                require(bakc.ownerOf(_bakcStaked.tokenId) == address(this), "StakeProxy: not bakc owner");
                IApeCoinStaking.PairNft[] memory nfts = new IApeCoinStaking.PairNft[](1);
                nfts[0] = IApeCoinStaking.PairNft({
                    mainTokenId: _apeStaked.tokenId.toUint128(),
                    bakcTokenId: _bakcStaked.tokenId.toUint128()
                });
                IApeCoinStaking.PairNft[] memory emptyNfts;
                if (_isPairedBaycPool()) {
                    apeStaking.claimBAKC(nfts, emptyNfts, address(this));
                } else {
                    apeStaking.claimBAKC(emptyNfts, nfts, address(this));
                }
            }
            uint256 rewardsAmount = apeCoin.balanceOf(address(this)) - preBalance;
            _allocateRewards(rewardsAmount);

            // transfer nft back to owner
            IERC721(_apeStaked.collection).safeTransferFrom(address(this), owner(), _apeStaked.tokenId);
        }
    }

    function totalStaked() external view returns (uint256 coinAmount) {
        return _totalStaked();
    }

    function _isSingleBaycPool() internal view returns (bool) {
        return poolId == 1;
    }

    function _isSingleMaycPool() internal view returns (bool) {
        return poolId == 2;
    }

    function _isPairedBaycPool() internal view returns (bool) {
        return poolId == 3 && _apeStaked.collection == address(bayc);
    }

    function _isPairedMaycPool() internal view returns (bool) {
        return poolId == 3 && _apeStaked.collection == address(mayc);
    }

    function _totalStaked() internal view returns (uint256 coinAmount) {
        coinAmount = _apeStaked.coinAmount + _bakcStaked.coinAmount + _coinStaked.coinAmount;
    }
}