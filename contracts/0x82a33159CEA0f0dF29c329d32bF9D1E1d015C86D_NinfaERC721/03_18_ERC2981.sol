// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

/**
    ███    ██ ██ ███    ██ ███████  █████  
    ████   ██ ██ ████   ██ ██      ██   ██ 
    ██ ██  ██ ██ ██ ██  ██ █████   ███████ 
    ██  ██ ██ ██ ██  ██ ██ ██      ██   ██ 
    ██   ████ ██ ██   ████ ██      ██   ██                                                                               
 */

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
/// @dev This implementation has the same royalties for each and every tokens

abstract contract ERC2981 is IERC2981, ERC165 {
    /**
     * "For precision purposes, it's better to express the royalty percentage as "basis points" (points per 10_000, e.g., 10% = 1000 bps) and compute the amount is `(royaltyBps[_tokenId] * _salePrice) / 10000`" - https://forum.openzeppelin.com/t/setting-erc2981/16065/2
     */
    uint24 private constant ARTISTS_ROYALTIES = 1000; // 10% fixed royalties
    /**
     * "artists" maps token ID to original artist, used for sending royalties to artists on all secondary sales.
     * "If you plan on having a contract where NFTs are created by multiple authors AND they can update royalty details after minting, you will need to record the original author of each token." - https://forum.openzeppelin.com/t/setting-erc2981/16065/2
     */
    mapping(uint256 => address payable) internal artists;

    /// @inheritdoc	IERC2981
    function royaltyInfo(uint256 _tokenId, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = artists[_tokenId];
        royaltyAmount = (value * ARTISTS_ROYALTIES) / 10000;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC165)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId); // bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    }

}