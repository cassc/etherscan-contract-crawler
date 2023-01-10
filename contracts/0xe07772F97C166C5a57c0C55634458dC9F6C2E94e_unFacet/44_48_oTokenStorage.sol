// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library oTokenStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("untrading.unDiamond.NFT.facet.otokens.storage");

    struct oToken {
        uint256 ORatio; // The percentage of the profit
        uint256 rewardRatio; // The percentage of profit allocated to both FR and OR
        address[] holders; // The addresses receiving the oToken cut of profit
        mapping(address => uint256) amount; // The amount of tokens each holder has
    }

    struct Layout {
        mapping(uint256 => oToken) _oTokens; // Mapping that represents the oToken information for a given tokenId

        mapping(address => uint256) _allottedOR; // Mapping that represents the OR (in Ether) allotted for a given address
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}