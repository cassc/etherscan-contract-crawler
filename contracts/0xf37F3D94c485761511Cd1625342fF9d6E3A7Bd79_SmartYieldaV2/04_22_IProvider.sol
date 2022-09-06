// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.10;
pragma abicoder v2;
import "../external/IPool.sol";
import "../external/DataTypes.sol";

interface IProvider {
    function cToken() external view returns (address);

    function smartYield() external view returns (address);

    function initialize(address aToken_, address smartYield_) external;

    // deposit underlyingAmount_ into provider, add takeFees_ to fees
    function _depositProvider(uint256 underlyingAmount_) external;

    // withdraw underlyingAmount_ from provider, add takeFees_ to fees
    function _withdrawProvider(uint256 underlyingAmount_) external;

    function _takeUnderlying(address from_, uint256 amount_) external;

    function _sendUnderlying(address to_, uint256 amount_) external;

    // current total underlying balance as measured by the provider pool, without fees
    function underlyingBalance() external view returns (uint256);

    // function claimRewardsTo(address[] calldata assets, address to)
    //     external
    //     returns (address[] memory rewardsList, uint256[] memory claimedAmounts);

    function claimRewardsTo(address[] calldata assets, address to) external returns (uint256);

    function _borrowProvider(address borrowAsset, uint256 amount) external;

    function _repayProvider(address borrowAsset, uint256 amount) external payable;

    function _getUserAccountDataProvider(address _user)
        external
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function _getReserveDataProvider(address _reserve) external view returns (DataTypes.ReserveData memory reserveData);

    function enableBorrowAsset(address asset) external;

    function disableBorrowAsset(address asset) external;

    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

    function totalUnRedeemed() external view returns (uint256);

    function addTotalUnRedeemed(uint256 amount) external;
}