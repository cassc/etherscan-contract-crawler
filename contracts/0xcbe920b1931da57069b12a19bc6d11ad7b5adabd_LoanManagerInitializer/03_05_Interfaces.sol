// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IERC20Like {

    function balanceOf(address account_) external view returns (uint256 balance_);

    function decimals() external view returns (uint8 decimals_);

}

interface ILiquidatorLike {

    function collateralRemaining() external view returns (uint256 collateralRemaining_);

    function pullFunds(address token_, address destination_, uint256 amount_) external;

    function setCollateralRemaining(uint256 collateralAmount_) external;

}

interface ILoanFactoryLike {

    function isLoan(address loan_) external view returns (bool isLoan_);

}

interface IMapleGlobalsLike {

    function getLatestPrice(address asset_) external view returns (uint256 price_);

    function governor() external view returns (address governor_);

    function isBorrower(address borrower_) external view returns (bool isBorrower_);

    function isFunctionPaused(bytes4 sig_) external view returns (bool isFunctionPaused_);

    function isInstanceOf(bytes32 instanceId, address instance_) external view returns (bool isInstance_);

    function isPoolDeployer(address poolDeployer_) external view returns (bool isPoolDeployer_);

    function isValidScheduledCall(address caller_, address contract_, bytes32 functionId_, bytes calldata callData_)
        external view returns (bool isValid_);

    function mapleTreasury() external view returns (address mapleTreasury_);

    function platformManagementFeeRate(address poolManager_) external view returns (uint256 platformManagementFeeRate_);

    function securityAdmin() external view returns (address securityAdmin_);

    function unscheduleCall(address caller_, bytes32 functionId_, bytes calldata callData_) external;

}

interface IMapleLoanLike {

    function acceptLender() external;

    function acceptNewTerms(
        address          refinancer_,
        uint256          deadline_,
        bytes[] calldata calls_
    ) external returns (bytes32 refinanceCommitment_);

    function borrower() external view returns (address borrower_);

    function collateralAsset() external view returns(address asset_);

    function factory() external view returns (address factory_);

    function fundLoan() external returns (uint256 fundsLent_);

    function getNextPaymentDetailedBreakdown() external view returns (
        uint256           principal_,
        uint256[3] memory interest_,
        uint256[2] memory fees_
    );

    function getUnaccountedAmount(address asset_) external returns (uint256 unaccountedAmount_);

    function impairLoan() external;

    function isImpaired() external view returns (bool isImpaired_);

    function nextPaymentDueDate() external view returns (uint256 nextPaymentDueDate_);

    function originalNextPaymentDueDate() external view returns (uint256 originalNextPaymentDueDate_);

    function paymentsRemaining() external view returns (uint256 paymentsRemaining_);

    function principal() external view returns (uint256 principal_);

    function principalRequested() external view returns (uint256 principal_);

    function rejectNewTerms(
        address          refinancer_,
        uint256          deadline_,
        bytes[] calldata calls_
    ) external returns (bytes32 refinanceCommitment_);

    function removeLoanImpairment() external;

    function repossess(address destination_) external returns (uint256 collateralRepossessed_, uint256 fundsRepossessed_);

    function skim(address token_, address destination_) external returns (uint256 skimmed_);

}

interface IMapleProxyFactoryLike {

    function createInstance(bytes calldata arguments_, bytes32 salt_) external returns (address instance_);

    function mapleGlobals() external view returns (address mapleGlobals_);

    function upgradeInstance(uint256 toVersion_, bytes calldata arguments_) external;

}

interface IPoolManagerLike {

    function asset() external view returns (address asset_);

    function delegateManagementFeeRate() external view returns (uint256 delegateManagementFeeRate_);

    function factory() external view returns (address factory_);

    function hasSufficientCover() external view returns (bool hasSufficientCover_);

    function pool() external view returns (address pool_);

    function poolDelegate() external view returns (address poolDelegate_);

    function requestFunds(address destination_, uint256 principal_) external;

}