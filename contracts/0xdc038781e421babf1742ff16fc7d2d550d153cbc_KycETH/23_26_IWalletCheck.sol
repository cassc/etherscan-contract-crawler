// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

interface IWalletCheck {

    event Deployed(
        address indexed admin, 
        address trustedForwarder,
        address policyManager,
        uint256 maximumConsentPeriod,
        string uri);

    event UpdateUri(address indexed admin, string uri);
    
    event SetWalletCheck(address indexed admin, address indexed wallet, bool isWhitelisted);

    function ROLE_WALLETCHECK_LIST_ADMIN() external view returns (bytes32);

    function ROLE_WALLETCHECK_META_ADMIN() external view returns (bytes32);

    function updateUri(string calldata uri_) external;

    function setWalletCheck(address wallet, bool whitelisted, uint256 timestamp) external;

    function checkWallet(
        address observer, 
        address wallet,
        uint32 admissionPolicyId
    ) external returns (bool passed);
}