// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

interface IProofFactory {
    struct ProofToken {
        bool status;
        address pair;
        address owner;
        uint256 unlockTime;
        uint256 lockId;
    }

    struct WhitelistAdd_ {
        address[] whitelists;
    }

    struct TokenParam {
        string tokenName;
        string tokenSymbol;
        uint256 initialSupply;
        uint256 percentToLP;
        address reflectionToken;
        address devWallet;
        uint256 initialReflectionFee;
        uint256 initialReflectionFeeOnSell;
        uint256 initialLpFee;
        uint256 initialLpFeeOnSell;
        uint256 initialDevFee;
        uint256 initialDevFeeOnSell;
        uint256 unlockTime;
        uint256 whitelistPeriod;
        address[] whitelists;
    }

    event TokenCreated(address _address);

    function createToken(TokenParam memory _tokenParam) external payable;
    function addmoreWhitelist(address tokenAddress, WhitelistAdd_ memory _WhitelistAdd) external;
    function finalizeToken(address tokenAddress) external payable;
}