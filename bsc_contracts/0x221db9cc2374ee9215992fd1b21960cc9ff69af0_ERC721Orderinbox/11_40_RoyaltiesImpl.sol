// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./AbstractRoyalties.sol";
import "../IRoyalties.sol";
import "../IManifoldRoyalties.sol";
import "../IRaribleRoyalties.sol";

contract RoyaltiesImpl is AbstractRoyalties, IRoyalties, IManifoldRoyalties, IRaribleV2Royalties {
    function getOrderinboxRoyalties(uint256 tokenId) override external view returns (LibPart.Part[] memory) {
        return royalties[tokenId];
    }

    function _onRoyaltiesSet(uint256 id, LibPart.Part[] memory _royalties) override internal {
        emit RoyaltiesSet(id, _royalties);
    }

    /**
     * @dev
     * This is added so that we support Rarible Royalties spec so that our royalties can be recognized by the royalties engine implementations
     */
    function getRaribleV2Royalties(uint256 tokenId) override external view returns (Part[] memory parts) {
        parts = new Part[](royalties[tokenId].length);

        for (uint i = 0; i < royalties[tokenId].length; i++) {
            parts[i].account = royalties[tokenId][i].account;
            parts[i].value = royalties[tokenId][i].value;
        }
    }

    /**
     * @dev
     * This is added so that we support Manifold.xyz Royalties spec so that our royalties can be recognized by the royalties engine implementation
     */
    function getRoyalties(uint256 tokenId) override external view returns (address payable[] memory recipients, uint256[] memory bps)
    {
        recipients = new address payable[](royalties[tokenId].length);
        bps = new uint256[](royalties[tokenId].length);

        for (uint i = 0; i < royalties[tokenId].length; i++) {
            recipients[i] = royalties[tokenId][i].account;
            bps[i] = royalties[tokenId][i].value;
        }
    }
}