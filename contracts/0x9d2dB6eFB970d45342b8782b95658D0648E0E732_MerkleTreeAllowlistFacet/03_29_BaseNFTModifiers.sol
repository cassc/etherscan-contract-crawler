// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {BaseNFTLib} from "./BaseNFTLib.sol";

// sale states
// 0 - closed
// 1 - public sale
// 2 - allow list sale

error IncorrectSaleState();

abstract contract SaleStateModifiers {
    modifier onlyAtSaleState(uint256 _gatedSaleState) {
        if (_gatedSaleState != BaseNFTLib.saleState()) {
            revert IncorrectSaleState();
        }
        _;
    }

    modifier onlyAtOneOfSaleStates(uint256[] calldata _gatedSaleStates) {
        uint256 currState = BaseNFTLib.saleState();
        for (uint256 i; i < _gatedSaleStates.length; i++) {
            if (_gatedSaleStates[i] == currState) {
                _;
                return;
            }
        }

        revert IncorrectSaleState();
    }
}