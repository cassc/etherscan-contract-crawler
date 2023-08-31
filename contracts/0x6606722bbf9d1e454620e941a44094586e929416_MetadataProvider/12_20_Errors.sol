// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface Errors {
    error NullAddressNotAllowed();
    error PayoutAddressNotSet();
    error AddressNotSet();

    error IERC721SupportCheckFailed();
    error IERC165SupportCheckFailed();
    error IERC20SupportCheckFailed();

    error CollectionNotFound();

    error IncorrectContractDeployer();
    error ReplicanContractAlreadyDeployed();
    error InvalidDeploymentPayment();
    error InvalidatedDeployment();
    error PaymentTokenNotSupported();
    error PaymentTokenAlreadyRegistered();
    error PaymentTokenNotRegistered();
    error InvalidSecurePayment();
    error TransferERC20Failed();
    error TransferFailed();

    error Unauthorized();
}