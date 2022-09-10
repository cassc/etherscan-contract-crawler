// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/ERC721Royalty.sol)

pragma solidity ^0.8.9;

import {Modifiers} from "../libraries/Modifiers.sol";

/**
 * @dev Allow list Facet for updating AllowList Merkle Tree
 * @author https://github.com/lively
 */
contract AllowListFacet is Modifiers {
    function updateAllowList(bytes32 allowListRoot) public onlyOwner {
        s.allowListRoot = allowListRoot;
    }

    function allowListEnabled() public view returns (bool) {
        return s.allowListEnabled;
    }

    function enableAllowList() public onlyOwner {
        require(!s.allowListEnabled, "AllowList is already enabled");
        s.allowListEnabled = true;
    }

    function disableAllowList() public onlyOwner {
        require(s.allowListEnabled, "AllowList is already disabled");
        s.allowListEnabled = false;
    }
}