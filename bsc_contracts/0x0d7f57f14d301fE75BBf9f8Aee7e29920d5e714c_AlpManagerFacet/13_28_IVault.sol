// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IVault {

    event TransferToExchangeTreasuryBNB(uint256 amount);
    event TransferToExchangeTreasury(address[] tokens, uint256[] amounts);
    event ReceiveFromExchangeTreasury(address[] tokens, uint256[] amounts);

    struct Token {
        address tokenAddress;
        uint16 weight;
        uint16 feeBasisPoints;
        uint16 taxBasisPoints;
        bool stable;
        bool dynamicFee;
    }

    struct LpItem {
        address tokenAddress;
        int256 value;
        uint8 decimals;
        int256 valueUsd; // decimals = 18
        uint16 targetWeight;
        uint16 feeBasisPoints;
        uint16 taxBasisPoints;
        bool dynamicFee;
    }

    function addToken(address tokenAddress, uint16 feeBasisPoints, uint16 taxBasisPoints, bool stable, bool dynamicFee, uint16[] memory weights) external;

    function removeToken(address tokenAddress, uint16[] memory weights) external;

    function updateToken(address tokenAddress, uint16 feeBasisPoints, uint16 taxBasisPoints, bool dynamicFee) external;

    function changeWeight(uint16[] memory weights) external;

    function tokens() external view returns (Token[] memory tokens_);

    function getTokenByAddress(address tokenAddress) external view returns (Token memory token_);

    function itemValue(address token) external view returns (LpItem memory lpItem);

    function totalValue() external view returns (LpItem[] memory lpItems);

    function transferToExchangeTreasury(address[] calldata tokens, uint256[] calldata amounts) external;

    function transferToExchangeTreasuryBNB(uint256 amount) external;

    function receiveFromExchangeTreasury(bytes[] calldata messages, bytes[] calldata signatures) external;
}