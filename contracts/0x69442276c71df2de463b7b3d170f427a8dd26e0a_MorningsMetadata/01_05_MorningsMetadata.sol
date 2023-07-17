// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "solmate/auth/Owned.sol";
import "openzeppelin/utils/Strings.sol";
import "./interfaces/IMetadata.sol";

/**
 * @author Fount Gallery
 * @title  Mornings Metadata
 * @notice Simple off-chain metadata storage using a single base URI
 */
contract MorningsMetadata is IMetadata, Owned {
    using Strings for uint256;

    string public baseURI;

    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    constructor(address owner_, string memory baseURI_) Owned(owner_) {
        baseURI = baseURI_;
    }

    /* ------------------------------------------------------------------------
       A D M I N
    ------------------------------------------------------------------------ */

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /* ------------------------------------------------------------------------
       R E N D E R
    ------------------------------------------------------------------------ */

    function tokenURI(uint256 id) public view override returns (string memory) {
        return string.concat(baseURI, id.toString());
    }
}