// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IGlobalsLike {

    function canDeploy(address caller_) external view returns (bool canDeploy_);

    function governor() external view returns (address governor_);

    function isBorrower(address borrower_) external view returns (bool isBorrower_);

    function isFunctionPaused(bytes4 sig_) external view returns (bool isFunctionPaused_);

    function isInstanceOf(bytes32 instanceId, address instance_) external view returns (bool isInstance_);

    function isValidScheduledCall(address caller_, address contract_, bytes32 functionId_, bytes calldata callData_)
        external view returns (bool isValid_);

    function mapleTreasury() external view returns (address mapleTreasury_);

    function platformManagementFeeRate(address poolManager_) external view returns (uint256 platformManagementFeeRate_);

    function securityAdmin() external view returns (address securityAdmin_);

    function unscheduleCall(address caller_, bytes32 functionId_, bytes calldata callData_) external;

}

interface IMapleProxyFactoryLike {

    function isInstance(address instance_) external returns (bool isInstance_);

    function mapleGlobals() external returns (address globals_);

}

interface ILoanFactoryLike {

    function isLoan(address loan_) external view returns (bool isLoan_);

}

interface ILoanLike {

    function borrower() external view returns (address borrower_);

    function callPrincipal(uint256 principalToReturn_) external returns (uint40 paymentDueDate_, uint40 defaultDate_);

    function factory() external view returns (address factory_);

    function fund() external returns (uint256 fundsLent_, uint40 paymentDueDate_, uint40 defaultDate_);

    function impair() external returns (uint40 paymentDueDate_, uint40 defaultDate_);

    function paymentDueDate() external view returns (uint40 paymentDueDate_);

    function getPaymentBreakdown(uint256 paymentTimestamp_)
        external view
        returns (
            uint256 principal_,
            uint256 interest_,
            uint256 lateInterest_,
            uint256 delegateServiceFee_,
            uint256 platformServiceFee_
        );

    function principal() external view returns (uint256 principal_);

    function proposeNewTerms(
        address refinancer_,
        uint256 deadline_,
        bytes[] calldata calls_
    ) external returns (bytes32 refinanceCommitment_);

    function rejectNewTerms(
        address refinancer_,
        uint256 deadline_,
        bytes[] calldata calls_
    ) external returns (bytes32 refinanceCommitment_);

    function removeCall() external returns (uint40 paymentDueDate_, uint40 defaultDate_);

    function removeImpairment() external returns (uint40 paymentDueDate_, uint40 defaultDate_);

    function repossess(address destination_) external returns (uint256 fundsRepossessed_);

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