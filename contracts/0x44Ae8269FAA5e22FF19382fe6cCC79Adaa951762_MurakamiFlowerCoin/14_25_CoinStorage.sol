// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IMurakamiMoneyCatCoinBank.sol";
import "../interfaces/IMurakamiLuckyCatCoinBank.sol";
import "../interfaces/IMurakamiFlowerCoin.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

library CoinStorage {
    struct Layout {
        string baseURI;
        bool active;
        bool operatorFilteringEnabled;
        IMurakamiLuckyCatCoinBank luckyCatCoinBank;
        IMurakamiMoneyCatCoinBank moneyCatCoinBank;
        mapping(uint256 => uint256) coinEXP;
    }

    bytes32 internal constant APP_STORAGE_SLOT =
        keccak256("MURAKAMI.contracts.CoinStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = APP_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}