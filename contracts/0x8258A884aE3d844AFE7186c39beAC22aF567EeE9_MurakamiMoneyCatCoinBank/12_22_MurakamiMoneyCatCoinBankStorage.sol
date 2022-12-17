// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IMurakamiFlowerCoin.sol";

library MurakamiMoneyCatCoinBankStorage {
    struct Layout {
        string baseURI;
        bool active;
        bool operatorFilteringEnabled;
        IMurakamiFlowerCoin coin;
        mapping(uint256 => uint256) catEXP;
        mapping(uint256 => uint256) coinsCount;
        mapping(uint256 => mapping(uint256 => uint256)) coinIdByIndex;
    }

    bytes32 internal constant APP_STORAGE_SLOT =
        keccak256("MURAKAMI.contracts.MurakamiMoneyCatCoinBankStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = APP_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}