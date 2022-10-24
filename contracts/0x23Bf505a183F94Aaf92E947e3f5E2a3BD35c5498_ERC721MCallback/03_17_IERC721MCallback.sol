//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721M.sol";

interface IERC721MCallback is IERC721M {
    struct CallbackInfo {
        address callbackContract;
        bytes4 callbackFunction;
    }

    error CallbackFailed(address callbackContract, bytes4 callbackFunction);
    error InvalidCallbackDatasLength(uint256 expected, uint256 actual);
}