pragma solidity ^0.6.12;
// SPDX-License-Identifier: UNLICENSED

import "../HasContractURI.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155MetadataURI.sol";
import "../HasTokenURI.sol";

/**
    Note: The ERC-165 identifier for this interface is 0x0e89341c.
*/
abstract contract ERC1155Metadata_URI is IERC1155MetadataURI, HasTokenURI {

    constructor(string memory _tokenURIPrefix) HasTokenURI(_tokenURIPrefix) public {

    }

    function uri(uint256 _id) override virtual external view returns (string memory) {
        return _tokenURI(_id);
    }
}