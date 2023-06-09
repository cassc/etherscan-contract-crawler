// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./IERC2981.sol";

contract RoyaltyConfig is IERC2981, ERC165 {
    event UpdatedRoyalty(uint256 indexed tokenId, address recipient, uint256 bps);

    struct RoyaltyInfo {
        uint256 bps;
        address receiver;
    }

    mapping(uint256 => RoyaltyInfo) public royalities;

    function _setRoyaltyPayoutAddressForToken(
        address royaltyReciever,
        uint256 tokenId
    ) internal virtual {
        emit UpdatedRoyalty(tokenId, royaltyReciever, royalities[tokenId].bps);
        royalities[tokenId].receiver = royaltyReciever;
    }

    function _setRoyaltyForToken(
        address royaltyReciever,
        uint256 royaltyBPS,
        uint256 tokenId
    ) internal virtual {
        emit UpdatedRoyalty(tokenId, royaltyReciever, royaltyBPS);
        royalities[tokenId] = RoyaltyInfo({
            receiver: royaltyReciever,
            bps: royaltyBPS
        });
    }

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param tokenId - the NFT asset queried for royalty information
    /// @param salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override(IERC2981)
        returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalty = royalities[tokenId];
        return (
            royalty.receiver,
            (salePrice * royalty.bps) / 10000
        );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}