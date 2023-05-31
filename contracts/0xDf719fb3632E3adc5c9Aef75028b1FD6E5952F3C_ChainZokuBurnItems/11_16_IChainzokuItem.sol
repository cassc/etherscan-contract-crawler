// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @author: miinded.com

interface IChainzokuItem {

    enum Action {Mint, Transfer, Burn}

    struct CollectionItems {
        address collection;
        Action action;
        uint256[] ids;
        uint256[] counts;
        uint256[] internalIds;
    }

    event FlagItems(uint256[] internalIds, uint8 action, uint256 zokuTokenId);

}