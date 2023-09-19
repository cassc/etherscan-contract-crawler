// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./AccessControlled.sol";
import "./Errors.sol";
import "./IPaymentTokenRegistry.sol";

contract PaymentTokenRegistry is IPaymentTokenRegistry, AccessControlled {

    struct Token {
        bool registered;
        bool supported;
        uint256 addressIndex;
    }

    mapping(address => Token) private tokens;
    mapping(address => PaymentConfig) private costConfigs;
    address[] private registeredTokens;

    constructor(address accessController_) AccessControlled(accessController_) {}

    function setCostConfig(address contract_, PaymentConfig calldata config) public onlyPaymentManager {
        if (!isTokenSupported(config.token)) revert Errors.PaymentTokenNotSupported();
        costConfigs[contract_] = config;
    }

    function registeredTokenAtIndex(uint256 index) public view returns (address) {
        return registeredTokens[index];
    }

    function numberOfRegisteredTokens() public view returns (uint256) {
        return registeredTokens.length;
    }

    function registerToken(address token) public onlyPaymentManager {
        if (token == address(0)) revert Errors.NullAddressNotAllowed();
        if (isTokenRegistered(token)) revert Errors.PaymentTokenAlreadyRegistered();

        uint256 index = registeredTokens.length;
        tokens[token] = Token({
            supported: true,
            registered: true,
            addressIndex: index
        });
        registeredTokens.push(token);
    }

    function setTokenSupported(address token, bool supported) public onlyPaymentManager {
        if (token == address(0)) revert Errors.NullAddressNotAllowed();
        if (!tokens[token].registered) revert Errors.PaymentTokenNotRegistered();

        tokens[token].supported = supported;
    }

    function isTokenSupported(address token) public override view returns (bool) {
        if (token == address(0)) return true; // represents native
        return tokens[token].supported && tokens[token].registered;
    }

    function isTokenRegistered(address token) public override view returns (bool) {
        if (token == address(0)) return true; // represents native
        return tokens[token].registered;
    }

    function costConfig(address masterCollection) external view returns (PaymentConfig memory) {
        return costConfigs[masterCollection];
    }

}