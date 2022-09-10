// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/ERC721Royalty.sol)

pragma solidity ^0.8.0;

import "../abstracts/ERC2981.sol";
import {AccessControl} from "../abstracts/AccessControl.sol";

/**
 * @dev Modification of the OpenZeppeling ERC721Royalty contract to be diamond compliant.
 * @author https://github.com/lively
 */
contract RoyaltyFacet is ERC2981 {
    /**
     * @dev This clears the royalty information for the token.
     */
    function royaltyBurn(uint256 tokenId) public onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    /** @dev return contractURI for opensea */
    function contractURI() public view returns (string memory) {
        return s.contractURI;
    }

    /** Set secondary sale royalties */
    function setRoyalties(address recipient, uint96 feeNumerator)
        public
        onlyOwner
    {
        require(
            feeNumerator >= 0 && feeNumerator <= 10000,
            "Royalties value must be between 0 and 10000"
        );
        _setDefaultRoyalty(recipient, feeNumerator);
    }
}