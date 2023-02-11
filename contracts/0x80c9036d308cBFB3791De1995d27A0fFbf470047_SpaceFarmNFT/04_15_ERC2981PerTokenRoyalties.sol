// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

import './ERC2981Base.sol';

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
abstract contract ERC2981PerTokenRoyalties is ERC2981Base {
    mapping(uint256 => address) internal _royaltyReceivers;

    /// @dev Sets token royalties
    /// @param tokenId the token id for which we register the royalties
    /// @param recipient recipient of the royalties
    function _setTokenRoyalty(
        uint256 tokenId,
        address recipient
    ) internal {
        _royaltyReceivers[tokenId] = recipient;
    }

    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = _royaltyReceivers[tokenId];
        royaltyAmount = value / 10;
    }
}