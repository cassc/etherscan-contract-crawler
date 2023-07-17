// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { ERC721AUpgradeableInternal } from "./../ERC721AUpgradeableContracts/ERC721AUpgradeableInternal.sol";

contract DescriptorFacet is ERC721AUpgradeableInternal {
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        if (!_exists(tokenId)) _revert(URIQueryForNonexistentToken.selector);

        return string("");
    }
}