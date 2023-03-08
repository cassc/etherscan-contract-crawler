// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;
import {ApeCoinStaking} from "../../../dependencies/yoga-labs/ApeCoinStaking.sol";
import {IERC721} from "../../../dependencies/openzeppelin/contracts/IERC721.sol";
import {SafeERC20} from "../../../dependencies/openzeppelin/contracts/SafeERC20.sol";
import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import "../../../interfaces/IPool.sol";
import {DataTypes} from "../../libraries/types/DataTypes.sol";
import {PercentageMath} from "../../libraries/math/PercentageMath.sol";
import "./MintableERC721Logic.sol";
import "../../../dependencies/openzeppelin/contracts/SafeCast.sol";
import "../../../interfaces/INToken.sol";

/**
 * @title ApeStakingLogic library
 *
 * @notice Implements the base logic for ApeStaking
 */
library ApeStakingLogic {
    using SafeERC20 for IERC20;
    using PercentageMath for uint256;
    using SafeCast for uint256;

    uint256 constant BAYC_POOL_ID = 1;
    uint256 constant MAYC_POOL_ID = 2;
    uint256 constant BAKC_POOL_ID = 3;

    struct APEStakingParameter {
        uint256 unstakeIncentive;
    }
    event UnstakeApeIncentiveUpdated(uint256 oldValue, uint256 newValue);

    /**
     * @notice withdraw Ape coin staking position from ApeCoinStaking
     * @param _apeCoinStaking ApeCoinStaking contract address
     * @param poolId identify whether BAYC or MAYC paired with BAKC
     * @param _nftPairs Array of Paired BAYC/MAYC NFT's with staked amounts
     * @param _apeRecipient the receiver of ape coin
     */
    function withdrawBAKC(
        ApeCoinStaking _apeCoinStaking,
        uint256 poolId,
        ApeCoinStaking.PairNftWithdrawWithAmount[] memory _nftPairs,
        address _apeRecipient
    ) external {
        ApeCoinStaking.PairNftWithdrawWithAmount[]
            memory _otherPairs = new ApeCoinStaking.PairNftWithdrawWithAmount[](
                0
            );

        uint256 beforeBalance = _apeCoinStaking.apeCoin().balanceOf(
            address(this)
        );
        if (poolId == BAYC_POOL_ID) {
            _apeCoinStaking.withdrawBAKC(_nftPairs, _otherPairs);
        } else {
            _apeCoinStaking.withdrawBAKC(_otherPairs, _nftPairs);
        }
        uint256 afterBalance = _apeCoinStaking.apeCoin().balanceOf(
            address(this)
        );

        _apeCoinStaking.apeCoin().safeTransfer(
            _apeRecipient,
            afterBalance - beforeBalance
        );
    }

    /**
     * @notice undate incentive percentage for unstakePositionAndRepay
     * @param stakingParameter storage for Ape staking
     * @param incentive new incentive percentage
     */
    function executeSetUnstakeApeIncentive(
        APEStakingParameter storage stakingParameter,
        uint256 incentive
    ) external {
        require(
            incentive < PercentageMath.HALF_PERCENTAGE_FACTOR,
            "Value Too High"
        );
        uint256 oldValue = stakingParameter.unstakeIncentive;
        if (oldValue != incentive) {
            stakingParameter.unstakeIncentive = incentive;
            emit UnstakeApeIncentiveUpdated(oldValue, incentive);
        }
    }

    struct UnstakeAndRepayParams {
        IPool POOL;
        ApeCoinStaking _apeCoinStaking;
        address _underlyingAsset;
        uint256 poolId;
        uint256 tokenId;
        address incentiveReceiver;
        address bakcNToken;
    }

    /**
     * @notice Unstake Ape coin staking position and repay user debt
     * @param _owners The state of ownership for nToken
     * @param stakingParameter storage for Ape staking
     * @param params The additional parameters needed to execute this function
     */
    function executeUnstakePositionAndRepay(
        mapping(uint256 => address) storage _owners,
        APEStakingParameter storage stakingParameter,
        UnstakeAndRepayParams memory params
    ) external {
        if (
            IERC721(params._underlyingAsset).ownerOf(params.tokenId) !=
            address(this)
        ) {
            return;
        }
        address positionOwner = _owners[params.tokenId];
        IERC20 _apeCoin = params._apeCoinStaking.apeCoin();
        uint256 balanceBefore = _apeCoin.balanceOf(address(this));

        //1 unstake all position
        {
            //1.1 unstake Main pool position
            (uint256 stakedAmount, ) = params._apeCoinStaking.nftPosition(
                params.poolId,
                params.tokenId
            );
            if (stakedAmount > 0) {
                ApeCoinStaking.SingleNft[]
                    memory nfts = new ApeCoinStaking.SingleNft[](1);
                nfts[0].tokenId = params.tokenId.toUint32();
                nfts[0].amount = stakedAmount.toUint224();
                if (params.poolId == BAYC_POOL_ID) {
                    params._apeCoinStaking.withdrawBAYC(nfts, address(this));
                } else {
                    params._apeCoinStaking.withdrawMAYC(nfts, address(this));
                }
            }
            //1.2 unstake bakc pool position
            (uint256 bakcTokenId, bool isPaired) = params
                ._apeCoinStaking
                .mainToBakc(params.poolId, params.tokenId);
            if (isPaired) {
                (stakedAmount, ) = params._apeCoinStaking.nftPosition(
                    BAKC_POOL_ID,
                    bakcTokenId
                );
                if (stakedAmount > 0) {
                    ApeCoinStaking.PairNftWithdrawWithAmount[]
                        memory _nftPairs = new ApeCoinStaking.PairNftWithdrawWithAmount[](
                            1
                        );
                    _nftPairs[0].mainTokenId = params.tokenId.toUint32();
                    _nftPairs[0].bakcTokenId = bakcTokenId.toUint32();
                    _nftPairs[0].amount = stakedAmount.toUint184();
                    _nftPairs[0].isUncommit = true;
                    ApeCoinStaking.PairNftWithdrawWithAmount[]
                        memory _otherPairs = new ApeCoinStaking.PairNftWithdrawWithAmount[](
                            0
                        );

                    uint256 bakcBeforeBalance = _apeCoin.balanceOf(
                        params.bakcNToken
                    );
                    if (params.poolId == BAYC_POOL_ID) {
                        params._apeCoinStaking.withdrawBAKC(
                            _nftPairs,
                            _otherPairs
                        );
                    } else {
                        params._apeCoinStaking.withdrawBAKC(
                            _otherPairs,
                            _nftPairs
                        );
                    }
                    uint256 bakcAfterBalance = _apeCoin.balanceOf(
                        params.bakcNToken
                    );
                    uint256 balanceDiff = bakcAfterBalance - bakcBeforeBalance;
                    if (balanceDiff > 0) {
                        address bakcOwner = INToken(params.bakcNToken).ownerOf(
                            bakcTokenId
                        );
                        _apeCoin.safeTransferFrom(
                            params.bakcNToken,
                            bakcOwner,
                            balanceDiff
                        );
                    }
                }
            }
        }

        uint256 unstakedAmount = _apeCoin.balanceOf(address(this)) -
            balanceBefore;
        if (unstakedAmount == 0) {
            return;
        }
        //2 send incentive to caller
        if (params.incentiveReceiver != address(0)) {
            uint256 unstakeIncentive = stakingParameter.unstakeIncentive;
            if (unstakeIncentive > 0) {
                uint256 incentiveAmount = unstakedAmount.percentMul(
                    unstakeIncentive
                );
                _apeCoin.safeTransfer(
                    params.incentiveReceiver,
                    incentiveAmount
                );
                unstakedAmount = unstakedAmount - incentiveAmount;
            }
        }

        //3 repay and supply
        params.POOL.repayAndSupply(
            params._underlyingAsset,
            positionOwner,
            unstakedAmount
        );
    }

    /**
     * @notice get user total ape staking position
     * @param userState The user state of nToken
     * @param ownedTokens The ownership mapping state of nNtoken
     * @param user User address
     * @param poolId identify whether BAYC pool or MAYC pool
     * @param _apeCoinStaking ApeCoinStaking contract address
     */
    function getUserTotalStakingAmount(
        mapping(address => UserState) storage userState,
        mapping(address => mapping(uint256 => uint256)) storage ownedTokens,
        address _underlyingAsset,
        address user,
        uint256 poolId,
        ApeCoinStaking _apeCoinStaking
    ) external view returns (uint256) {
        uint256 totalBalance = uint256(userState[user].balance);
        uint256 totalAmount;
        for (uint256 index = 0; index < totalBalance; index++) {
            uint256 tokenId = ownedTokens[user][index];
            totalAmount += getTokenIdStakingAmount(
                _underlyingAsset,
                poolId,
                _apeCoinStaking,
                tokenId
            );
        }

        return totalAmount;
    }

    /**
     * @notice get ape staking position for a tokenId
     * @param poolId identify whether BAYC pool or MAYC pool
     * @param _apeCoinStaking ApeCoinStaking contract address
     * @param tokenId specified the tokenId for the position
     */
    function getTokenIdStakingAmount(
        address _underlyingAsset,
        uint256 poolId,
        ApeCoinStaking _apeCoinStaking,
        uint256 tokenId
    ) public view returns (uint256) {
        if (IERC721(_underlyingAsset).ownerOf(tokenId) != address(this)) {
            return 0;
        }
        (uint256 apeStakedAmount, ) = _apeCoinStaking.nftPosition(
            poolId,
            tokenId
        );

        uint256 apeReward = _apeCoinStaking.pendingRewards(
            poolId,
            address(this),
            tokenId
        );

        (uint256 bakcTokenId, bool isPaired) = _apeCoinStaking.mainToBakc(
            poolId,
            tokenId
        );

        if (isPaired) {
            (uint256 bakcStakedAmount, ) = _apeCoinStaking.nftPosition(
                BAKC_POOL_ID,
                bakcTokenId
            );
            apeStakedAmount += bakcStakedAmount;
        }

        return apeStakedAmount + apeReward;
    }
}