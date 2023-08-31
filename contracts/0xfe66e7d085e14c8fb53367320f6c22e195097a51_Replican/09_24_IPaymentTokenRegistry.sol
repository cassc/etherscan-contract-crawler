// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

struct PaymentConfig {
    address token;
    uint256 cost;
    address payout;
}

interface IPaymentTokenRegistry {
    function costConfig(address masterCollection) external view returns (PaymentConfig memory);
    function setCostConfig(address masterCollection, PaymentConfig calldata config) external;

    function isTokenSupported(address contract_) external view returns (bool);
    function isTokenRegistered(address token) external view returns (bool);
    function registeredTokenAtIndex(uint256 index) external view returns (address);
    function numberOfRegisteredTokens() external view returns (uint256);

    function registerToken(address token) external;
    function setTokenSupported(address token, bool enabled) external;
}