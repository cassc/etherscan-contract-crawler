// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {EnumerableSetUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {SafeCastUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";

import {IApeCoinStaking} from "../interfaces/IApeCoinStaking.sol";
import {INftVault} from "../interfaces/INftVault.sol";

import {ApeStakingLib} from "../libraries/ApeStakingLib.sol";

library VaultLogic {
    event SingleNftUnstaked(address indexed nft, address indexed staker, IApeCoinStaking.SingleNft[] nfts);
    event PairedNftUnstaked(
        address indexed staker,
        IApeCoinStaking.PairNftWithdrawWithAmount[] baycPairs,
        IApeCoinStaking.PairNftWithdrawWithAmount[] maycPairs
    );
    using SafeCastUpgradeable for uint256;
    using SafeCastUpgradeable for uint248;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using ApeStakingLib for IApeCoinStaking;

    function _stakerOf(
        INftVault.VaultStorage storage _vaultStorage,
        address nft_,
        uint256 tokenId_
    ) internal view returns (address) {
        return _vaultStorage.nfts[nft_][tokenId_].staker;
    }

    function _ownerOf(
        INftVault.VaultStorage storage _vaultStorage,
        address nft_,
        uint256 tokenId_
    ) internal view returns (address) {
        return _vaultStorage.nfts[nft_][tokenId_].owner;
    }

    function _increasePosition(
        INftVault.VaultStorage storage _vaultStorage,
        address nft_,
        address staker_,
        uint256 stakedAmount_
    ) internal {
        INftVault.Position storage position_ = _vaultStorage.positions[nft_][staker_];
        position_.stakedAmount += stakedAmount_;
        position_.rewardsDebt += int256(
            stakedAmount_ * _vaultStorage.apeCoinStaking.getNftPool(nft_).accumulatedRewardsPerShare
        );
    }

    function _decreasePosition(
        INftVault.VaultStorage storage _vaultStorage,
        address nft_,
        address staker_,
        uint256 stakedAmount_
    ) internal {
        INftVault.Position storage position_ = _vaultStorage.positions[nft_][staker_];
        position_.stakedAmount -= stakedAmount_;
        position_.rewardsDebt -= int256(
            stakedAmount_ * _vaultStorage.apeCoinStaking.getNftPool(nft_).accumulatedRewardsPerShare
        );
    }

    function _updateRewardsDebt(
        INftVault.VaultStorage storage _vaultStorage,
        address nft_,
        address staker_,
        uint256 claimedRewardsAmount_
    ) internal {
        INftVault.Position storage position_ = _vaultStorage.positions[nft_][staker_];
        position_.rewardsDebt += int256(claimedRewardsAmount_ * ApeStakingLib.APE_COIN_PRECISION);
    }

    struct RefundSinglePoolVars {
        uint256 poolId;
        uint256 cachedBalance;
        uint256 tokenId;
        uint256 bakcTokenId;
        uint256 stakedAmount;
        // refunds
        address staker;
        uint256 totalPrincipal;
        uint256 totalReward;
        uint256 totalPairingPrincipal;
        uint256 totalPairingReward;
        // array
        uint256 singleNftIndex;
        uint256 singleNftSize;
        uint256 pairingNftIndex;
        uint256 pairingNftSize;
    }

    function _refundSinglePool(
        INftVault.VaultStorage storage _vaultStorage,
        address nft_,
        uint256[] calldata tokenIds_
    ) external {
        require(nft_ == _vaultStorage.bayc || nft_ == _vaultStorage.mayc, "nftVault: not bayc or mayc");
        require(tokenIds_.length > 0, "nftVault: invalid tokenIds");

        RefundSinglePoolVars memory vars;
        IApeCoinStaking.PairingStatus memory pairingStatus;
        INftVault.Refund storage refund;

        vars.poolId = ApeStakingLib.BAYC_POOL_ID;
        if (nft_ == _vaultStorage.mayc) {
            vars.poolId = ApeStakingLib.MAYC_POOL_ID;
        }
        vars.cachedBalance = _vaultStorage.apeCoin.balanceOf(address(this));
        vars.staker = _stakerOf(_vaultStorage, nft_, tokenIds_[0]);
        require(vars.staker != address(0), "nftVault: invalid staker");

        // Calculate the nft array size
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            vars.tokenId = tokenIds_[i];
            require(msg.sender == _ownerOf(_vaultStorage, nft_, vars.tokenId), "nftVault: caller must be nft owner");
            // make sure the bayc/mayc locked in valult
            require(address(this) == IERC721Upgradeable(nft_).ownerOf(vars.tokenId), "nftVault: invalid token id");
            require(vars.staker == _stakerOf(_vaultStorage, nft_, vars.tokenId), "nftVault: staker must be same");
            vars.stakedAmount = _vaultStorage.apeCoinStaking.nftPosition(vars.poolId, vars.tokenId).stakedAmount;

            // Still have ape coin staking in single pool
            if (vars.stakedAmount > 0) {
                vars.singleNftSize += 1;
            }

            pairingStatus = _vaultStorage.apeCoinStaking.mainToBakc(vars.poolId, vars.tokenId);
            vars.bakcTokenId = pairingStatus.tokenId;
            vars.stakedAmount = _vaultStorage
                .apeCoinStaking
                .nftPosition(ApeStakingLib.BAKC_POOL_ID, vars.bakcTokenId)
                .stakedAmount;

            //  Still have ape coin staking in pairing pool
            if (
                pairingStatus.isPaired &&
                // make sure the bakc locked in valult
                IERC721Upgradeable(_vaultStorage.bakc).ownerOf(vars.bakcTokenId) == address(this) &&
                vars.stakedAmount > 0
            ) {
                vars.pairingNftSize += 1;
            }
        }

        if (vars.singleNftSize > 0) {
            IApeCoinStaking.SingleNft[] memory singleNfts_ = new IApeCoinStaking.SingleNft[](vars.singleNftSize);
            for (uint256 i = 0; i < tokenIds_.length; i++) {
                vars.tokenId = tokenIds_[i];
                vars.stakedAmount = _vaultStorage.apeCoinStaking.nftPosition(vars.poolId, vars.tokenId).stakedAmount;
                if (vars.stakedAmount > 0) {
                    vars.totalPrincipal += vars.stakedAmount;
                    singleNfts_[vars.singleNftIndex] = IApeCoinStaking.SingleNft({
                        tokenId: vars.tokenId.toUint32(),
                        amount: vars.stakedAmount.toUint224()
                    });
                    vars.singleNftIndex += 1;
                    _vaultStorage.stakingTokenIds[nft_][vars.staker].remove(vars.tokenId);
                }
            }
            if (nft_ == _vaultStorage.bayc) {
                _vaultStorage.apeCoinStaking.withdrawBAYC(singleNfts_, address(this));
            } else {
                _vaultStorage.apeCoinStaking.withdrawMAYC(singleNfts_, address(this));
            }
            vars.totalReward =
                _vaultStorage.apeCoin.balanceOf(address(this)) -
                vars.cachedBalance -
                vars.totalPrincipal;
            // refund ape coin for single nft
            refund = _vaultStorage.refunds[nft_][vars.staker];
            refund.principal += vars.totalPrincipal;
            refund.reward += vars.totalReward;

            // update bayc&mayc position and debt
            if (vars.totalReward > 0) {
                _updateRewardsDebt(_vaultStorage, nft_, vars.staker, vars.totalReward);
            }
            _decreasePosition(_vaultStorage, nft_, vars.staker, vars.totalPrincipal);
            emit SingleNftUnstaked(nft_, vars.staker, singleNfts_);
        }

        if (vars.pairingNftSize > 0) {
            IApeCoinStaking.PairNftWithdrawWithAmount[]
                memory pairingNfts = new IApeCoinStaking.PairNftWithdrawWithAmount[](vars.pairingNftSize);
            IApeCoinStaking.PairNftWithdrawWithAmount[] memory emptyNfts;

            for (uint256 i = 0; i < tokenIds_.length; i++) {
                vars.tokenId = tokenIds_[i];

                pairingStatus = _vaultStorage.apeCoinStaking.mainToBakc(vars.poolId, vars.tokenId);
                vars.bakcTokenId = pairingStatus.tokenId;
                vars.stakedAmount = _vaultStorage
                    .apeCoinStaking
                    .nftPosition(ApeStakingLib.BAKC_POOL_ID, vars.bakcTokenId)
                    .stakedAmount;
                if (
                    pairingStatus.isPaired &&
                    // make sure the bakc locked in valult
                    IERC721Upgradeable(_vaultStorage.bakc).ownerOf(vars.bakcTokenId) == address(this) &&
                    vars.stakedAmount > 0
                ) {
                    vars.totalPairingPrincipal += vars.stakedAmount;
                    pairingNfts[vars.pairingNftIndex] = IApeCoinStaking.PairNftWithdrawWithAmount({
                        mainTokenId: vars.tokenId.toUint32(),
                        bakcTokenId: vars.bakcTokenId.toUint32(),
                        amount: vars.stakedAmount.toUint184(),
                        isUncommit: true
                    });
                    vars.pairingNftIndex += 1;
                    _vaultStorage.stakingTokenIds[_vaultStorage.bakc][vars.staker].remove(vars.bakcTokenId);
                }
            }
            vars.cachedBalance = _vaultStorage.apeCoin.balanceOf(address(this));

            if (nft_ == _vaultStorage.bayc) {
                _vaultStorage.apeCoinStaking.withdrawBAKC(pairingNfts, emptyNfts);
                emit PairedNftUnstaked(vars.staker, pairingNfts, emptyNfts);
            } else {
                _vaultStorage.apeCoinStaking.withdrawBAKC(emptyNfts, pairingNfts);
                emit PairedNftUnstaked(vars.staker, emptyNfts, pairingNfts);
            }
            vars.totalPairingReward =
                _vaultStorage.apeCoin.balanceOf(address(this)) -
                vars.cachedBalance -
                vars.totalPairingPrincipal;

            // refund ape coin for paring nft
            refund = _vaultStorage.refunds[_vaultStorage.bakc][vars.staker];
            refund.principal += vars.totalPairingPrincipal;
            refund.reward += vars.totalPairingReward;

            // update bakc position and debt
            if (vars.totalPairingReward > 0) {
                _updateRewardsDebt(_vaultStorage, _vaultStorage.bakc, vars.staker, vars.totalPairingReward);
            }
            _decreasePosition(_vaultStorage, _vaultStorage.bakc, vars.staker, vars.totalPairingPrincipal);
        }
    }

    struct RefundPairingPoolVars {
        uint256 cachedBalance;
        uint256 tokenId;
        uint256 stakedAmount;
        // refund
        address staker;
        uint256 totalPrincipal;
        uint256 totalReward;
        // array
        uint256 baycIndex;
        uint256 baycSize;
        uint256 maycIndex;
        uint256 maycSize;
    }

    function _refundPairingPool(INftVault.VaultStorage storage _vaultStorage, uint256[] calldata tokenIds_) external {
        require(tokenIds_.length > 0, "nftVault: invalid tokenIds");
        RefundPairingPoolVars memory vars;
        IApeCoinStaking.PairingStatus memory pairingStatus;

        vars.staker = _stakerOf(_vaultStorage, _vaultStorage.bakc, tokenIds_[0]);
        require(vars.staker != address(0), "nftVault: invalid staker");
        vars.cachedBalance = _vaultStorage.apeCoin.balanceOf(address(this));

        // Calculate the nft array size
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            vars.tokenId = tokenIds_[i];
            require(
                msg.sender == _ownerOf(_vaultStorage, _vaultStorage.bakc, vars.tokenId),
                "nftVault: caller must be nft owner"
            );
            // make sure the bakc locked in valult
            require(
                address(this) == IERC721Upgradeable(_vaultStorage.bakc).ownerOf(vars.tokenId),
                "nftVault: invalid token id"
            );
            require(
                vars.staker == _stakerOf(_vaultStorage, _vaultStorage.bakc, vars.tokenId),
                "nftVault: staker must be same"
            );

            vars.stakedAmount = _vaultStorage
                .apeCoinStaking
                .nftPosition(ApeStakingLib.BAKC_POOL_ID, vars.tokenId)
                .stakedAmount;
            if (vars.stakedAmount > 0) {
                pairingStatus = _vaultStorage.apeCoinStaking.bakcToMain(vars.tokenId, ApeStakingLib.BAYC_POOL_ID);

                // make sure the bayc locked in valult
                if (
                    pairingStatus.isPaired &&
                    IERC721Upgradeable(_vaultStorage.bayc).ownerOf(pairingStatus.tokenId) == address(this)
                ) {
                    vars.baycSize += 1;
                } else {
                    pairingStatus = _vaultStorage.apeCoinStaking.bakcToMain(vars.tokenId, ApeStakingLib.MAYC_POOL_ID);
                    // make sure the mayc locked in valult
                    if (
                        pairingStatus.isPaired &&
                        IERC721Upgradeable(_vaultStorage.mayc).ownerOf(pairingStatus.tokenId) == address(this)
                    ) {
                        vars.maycSize += 1;
                    }
                }
            }
        }

        if (vars.baycSize > 0 || vars.maycSize > 0) {
            IApeCoinStaking.PairNftWithdrawWithAmount[]
                memory baycNfts_ = new IApeCoinStaking.PairNftWithdrawWithAmount[](vars.baycSize);
            IApeCoinStaking.PairNftWithdrawWithAmount[]
                memory maycNfts_ = new IApeCoinStaking.PairNftWithdrawWithAmount[](vars.maycSize);
            for (uint256 i = 0; i < tokenIds_.length; i++) {
                vars.tokenId = tokenIds_[i];
                vars.stakedAmount = _vaultStorage
                    .apeCoinStaking
                    .nftPosition(ApeStakingLib.BAKC_POOL_ID, vars.tokenId)
                    .stakedAmount;
                if (vars.stakedAmount > 0) {
                    pairingStatus = _vaultStorage.apeCoinStaking.bakcToMain(vars.tokenId, ApeStakingLib.BAYC_POOL_ID);
                    // make sure the bayc locked in valult
                    if (
                        pairingStatus.isPaired &&
                        IERC721Upgradeable(_vaultStorage.bayc).ownerOf(pairingStatus.tokenId) == address(this)
                    ) {
                        vars.totalPrincipal += vars.stakedAmount;
                        baycNfts_[vars.baycIndex] = IApeCoinStaking.PairNftWithdrawWithAmount({
                            mainTokenId: pairingStatus.tokenId.toUint32(),
                            bakcTokenId: vars.tokenId.toUint32(),
                            amount: vars.stakedAmount.toUint184(),
                            isUncommit: true
                        });
                        vars.baycIndex += 1;
                        _vaultStorage.stakingTokenIds[_vaultStorage.bakc][vars.staker].remove(vars.tokenId);
                    } else {
                        pairingStatus = _vaultStorage.apeCoinStaking.bakcToMain(
                            vars.tokenId,
                            ApeStakingLib.MAYC_POOL_ID
                        );
                        // make sure the mayc locked in valult
                        if (
                            pairingStatus.isPaired &&
                            IERC721Upgradeable(_vaultStorage.mayc).ownerOf(pairingStatus.tokenId) == address(this)
                        ) {
                            vars.totalPrincipal += vars.stakedAmount;
                            maycNfts_[vars.maycIndex] = IApeCoinStaking.PairNftWithdrawWithAmount({
                                mainTokenId: pairingStatus.tokenId.toUint32(),
                                bakcTokenId: vars.tokenId.toUint32(),
                                amount: vars.stakedAmount.toUint184(),
                                isUncommit: true
                            });
                            vars.maycIndex += 1;
                            _vaultStorage.stakingTokenIds[_vaultStorage.bakc][vars.staker].remove(vars.tokenId);
                        }
                    }
                }
            }

            _vaultStorage.apeCoinStaking.withdrawBAKC(baycNfts_, maycNfts_);
            vars.totalReward =
                _vaultStorage.apeCoin.balanceOf(address(this)) -
                vars.cachedBalance -
                vars.totalPrincipal;
            // refund ape coin for bakc
            INftVault.Refund storage _refund = _vaultStorage.refunds[_vaultStorage.bakc][vars.staker];
            _refund.principal += vars.totalPrincipal;
            _refund.reward += vars.totalReward;

            // update bakc position and debt
            if (vars.totalReward > 0) {
                _updateRewardsDebt(_vaultStorage, _vaultStorage.bakc, vars.staker, vars.totalReward);
            }
            _decreasePosition(_vaultStorage, _vaultStorage.bakc, vars.staker, vars.totalPrincipal);
            emit PairedNftUnstaked(vars.staker, baycNfts_, maycNfts_);
        }
    }
}