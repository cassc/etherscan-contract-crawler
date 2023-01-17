//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface INarfexOracle {

    struct Token {
        bool isFiat;
        bool isCustomCommission; // Use default commission on false
        bool isCustomReward; // Use defalt referral percent on false
        uint price; // USD price only for fiats
        uint reward; // Referral percent only for fiats
        int commission; // Commission percent. Can be lower than zero
        uint transferFee; // Token transfer fee with 1000 decimals precision (20 for NRFX is 2%)
    }

    /// Calculated Token data
    struct TokenData {
        bool isFiat;
        int commission;
        uint price;
        uint reward;
        uint transferFee;
    }

    function defaultFiatCommission() external pure returns (int);
    function defaultCryptoCommission() external pure returns (int);
    function defaultReward() external pure returns (uint);
    function tokens(address _address) external returns (Token memory);

    function getPrice(address _address) external view returns (uint);
    function getIsFiat(address _address) external view returns (bool);
    function getCommission(address _address) external view returns (int);
    function getReferralPercent(address _address) external view returns (uint);
    function getTokenTransferFee(address _address) external view returns (uint);

    function getTokenData(address _address, bool _skipCoinPrice) external view returns (TokenData memory tokenData);
    function getTokensData(address[] calldata _tokens, bool _skipCoinPrice) external view returns (TokenData[] memory);
}