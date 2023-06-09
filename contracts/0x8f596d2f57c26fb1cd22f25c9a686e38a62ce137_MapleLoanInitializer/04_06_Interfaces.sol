// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IGlobalsLike {

    function governor() external view returns (address governor_);

    function isBorrower(address account_) external view returns (bool isBorrower_);

    function isCollateralAsset(address collateralAsset_) external view returns (bool isCollateralAsset_);

    function isFunctionPaused(bytes4 sig_) external view returns (bool isFunctionPaused_);

    function isInstanceOf(bytes32 instanceId_, address instance_) external view returns (bool isInstance_);

    function isPoolAsset(address poolAsset_) external view returns (bool isValid_);

    function mapleTreasury() external view returns (address governor_);

    function platformOriginationFeeRate(address pool_) external view returns (uint256 platformOriginationFeeRate_);

    function platformServiceFeeRate(address pool_) external view returns (uint256 platformFee_);

    function securityAdmin() external view returns (address securityAdmin_);

}

interface ILenderLike {

    function claim(uint256 principal_, uint256 interest_, uint256 previousPaymentDueDate_, uint256 nextPaymentDueDate_) external;

    function factory() external view returns (address factory_);

    function fundsAsset() external view returns (address fundsAsset_);

}

interface ILoanLike {

    function factory() external view returns (address factory_);

    function fundsAsset() external view returns (address asset_);

    function lender() external view returns (address lender_);

    function paymentInterval() external view returns (uint256 paymentInterval_);

    function paymentsRemaining() external view returns (uint256 paymentsRemaining_);

    function principal() external view returns (uint256 principal_);

    function principalRequested() external view returns (uint256 principalRequested_);

}

interface ILoanManagerLike {

    function owner() external view returns (address owner_);

    function poolManager() external view returns (address poolManager_);

}

interface IMapleProxyFactoryLike {

    function isInstance(address instance_) external view returns (bool isInstance_);

    function mapleGlobals() external view returns (address mapleGlobals_);

}

interface IPoolManagerLike {

    function poolDelegate() external view returns (address poolDelegate_);

}