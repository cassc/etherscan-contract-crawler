// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;
import {IGarden} from './IGarden.sol';

/**
 * @title IHeart
 * @author Babylon Finance
 *
 * Interface for interacting with the Heart
 */
interface IHeart {
    // View functions

    function getVotedGardens() external view returns (address[] memory);

    function heartGarden() external view returns (IGarden);

    function getGardenWeights() external view returns (uint256[] memory);

    function minAmounts(address _reserve) external view returns (uint256);

    function assetToCToken(address _asset) external view returns (address);

    function bondAssets(address _asset) external view returns (uint256);

    function assetToLend() external view returns (address);

    function assetForPurchases() external view returns (address);

    function lastPumpAt() external view returns (uint256);

    function lastVotesAt() external view returns (uint256);

    function tradeSlippage() external view returns (uint256);

    function weeklyRewardAmount() external view returns (uint256);

    function bablRewardLeft() external view returns (uint256);

    function getFeeDistributionWeights() external view returns (uint256[] memory);

    function getTotalStats() external view returns (uint256[] memory);

    function votedGardens(uint256 _index) external view returns (address);

    function gardenWeights(uint256 _index) external view returns (uint256);

    function feeDistributionWeights(uint256 _index) external view returns (uint256);

    function totalStats(uint256 _index) external view returns (uint256);

    // Non-view

    function pump(uint256 _bablMinAmountOut) external;

    function voteProposal(uint256 _proposalId, bool _isApprove) external;

    function resolveGardenVotesAndPump(
        address[] memory _gardens,
        uint256[] memory _weights,
        uint256 _bablMinAmountOut
    ) external;

    function resolveGardenVotes(address[] memory _gardens, uint256[] memory _weights) external;

    function updateMarkets() external;

    function setHeartGardenAddress(address _heartGarden) external;

    function updateFeeWeights(uint256[] calldata _feeWeights) external;

    function updateAssetToLend(address _assetToLend) external;

    function updateAssetToPurchase(address _purchaseAsset) external;

    function updateBond(address _assetToBond, uint256 _bondDiscount) external;

    function transferToken(
        address _token,
        address _to,
        uint256 _amount
    ) external;

    // function lendFusePool(address _assetToLend, uint256 _lendAmount) external;
    //
    // function borrowFusePool(address _assetToBorrow, uint256 _borrowAmount) external;
    //
    // function repayFusePool(address _borrowedAsset, uint256 _amountToRepay) external;

    function protectBABL(
        uint256 _bablPriceProtectionAt,
        uint256 _bablPrice,
        uint256 _pricePurchasingAsset,
        uint256 _slippage,
        address _hopToken
    ) external;

    function trade(
        address _fromAsset,
        address _toAsset,
        uint256 _fromAmount,
        uint256 _minAmount
    ) external;

    function sellWantedAssetToHeart(address _assetToSell, uint256 _amountToSell) external;

    function addReward(uint256 _bablAmount, uint256 _weeklyRate) external;

    function setHeartConfigParam(
        uint8 _index,
        uint256 _param,
        address _addressParam
    ) external;

    function bondAsset(
        address _assetToBond,
        uint256 _amountToBond,
        uint256 _minAmountOut,
        address _referrer,
        uint256 _userLock
    ) external;

    function bondAssetBySig(
        address _assetToBond,
        uint256 _amountToBond,
        uint256 _amountIn,
        uint256 _minAmountOut,
        uint256 _nonce,
        uint256 _maxFee,
        uint256 _priceInBABL,
        uint256 _pricePerShare,
        uint256[2] calldata _feeAndLock,
        address _contributor,
        address _referrer,
        bytes memory _signature
    ) external;
}