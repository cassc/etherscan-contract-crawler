// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./ICreatorProvenance.sol";

abstract contract CreatorProvenance is ICreatorProvenance {
    struct Creator {
        address creator;
        bool isVerified;
    }

    mapping(uint256 => Creator) private _tokenCreators;

    function provenanceTokenInfo(
        uint256 tokenId
    ) public view returns (address, bool) {
        Creator memory creator = _tokenCreators[tokenId];
        return (creator.creator, creator.isVerified);
    }

    function verifyTokenProvenance(uint256 tokenId) public {
        require(
            msg.sender == _tokenCreators[tokenId].creator,
            "CreatorProvenance: not creator"
        );
        _tokenCreators[tokenId].isVerified = true;
    }

    /**
     * @dev Sets the creator information for a specific token id.
     *
     * Requirements:
     *
     * - `creators` cannot include a zero address.
     */
    function _setTokenCreator(
        uint256 tokenId,
        address creator
    ) internal virtual {
        require(creator != address(0), "CreatorProvenance: invalid creator");

        _tokenCreators[tokenId] = Creator(creator, false);
    }

    /**
     * @dev Deletes creator information for the specified token.
     */
    function _deleteTokenProvenance(uint256 tokenId) internal virtual {
        delete _tokenCreators[tokenId];
    }
}