// SPDX-License-Identifier: MIT
//
// Derived from Kredeum NFTs
// https://github.com/Kredeum/kredeum
//
//       ___           ___         ___           ___              ___           ___                     ___
//      /  /\         /  /\       /  /\         /__/\            /__/\         /  /\        ___        /  /\
//     /  /::\       /  /::\     /  /:/_        \  \:\           \  \:\       /  /:/_      /  /\      /  /:/_
//    /  /:/\:\     /  /:/\:\   /  /:/ /\        \  \:\           \  \:\     /  /:/ /\    /  /:/     /  /:/ /\
//   /  /:/  \:\   /  /:/~/:/  /  /:/ /:/_   _____\__\:\      _____\__\:\   /  /:/ /:/   /  /:/     /  /:/ /::\
//  /__/:/ \__\:\ /__/:/ /:/  /__/:/ /:/ /\ /__/::::::::\    /__/::::::::\ /__/:/ /:/   /  /::\    /__/:/ /:/\:\
//  \  \:\ /  /:/ \  \:\/:/   \  \:\/:/ /:/ \  \:\~~\~~\/    \  \:\~~\~~\/ \  \:\/:/   /__/:/\:\   \  \:\/:/~/:/
//   \  \:\  /:/   \  \::/     \  \::/ /:/   \  \:\  ~~~      \  \:\  ~~~   \  \::/    \__\/  \:\   \  \::/ /:/
//    \  \:\/:/     \  \:\      \  \:\/:/     \  \:\           \  \:\        \  \:\         \  \:\   \__\/ /:/
//     \  \::/       \  \:\      \  \::/       \  \:\           \  \:\        \  \:\         \__\/     /__/:/
//      \__\/         \__\/       \__\/         \__\/            \__\/         \__\/                   \__\/
//
//   OpenERC165
//   (supports)
//       |
//       ——————————————————————————————————————————————————————————————————————
//       |                                       |             |              |
//   OpenERC721                            OpenERC2981    OpenERC173    OpenCloneable
//     (NFT)                              (RoyaltyInfo)    (ownable)          |
//       |                                        |            |              |
//       ——————————————————————————————————————   |     ————————              |
//       |                        |           |   |     |      |              |
//  OpenERC721Metadata  OpenERC721Enumerable  |   ———————      |              |
//       |                        |           |   |            |              |
//       |                        |      OpenMarketable   OpenPauseable       |
//       |                        |             |              |              |
//       ——————————————————————————————————————————————————————————————————————
//       |
//    OpenNFTs —— IOpenNFTs
//
pragma solidity 0.8.9;

import "OpenNFTs/contracts/interfaces/IERC165.sol";

import "OpenNFTs/contracts/interfaces/IOpenNFTs.sol";
import "OpenNFTs/contracts/OpenERC/OpenERC721Metadata.sol";
import "OpenNFTs/contracts/OpenERC/OpenERC721Enumerable.sol";
import "OpenNFTs/contracts/OpenNFTs/OpenMarketable.sol";
import "OpenNFTs/contracts/OpenNFTs/OpenPauseable.sol";
import "OpenNFTs/contracts/OpenCloner/OpenCloneable.sol";

/// @title OpenNFTs smartcontract
abstract contract OpenNFTs is
    IOpenNFTs,
    OpenERC721Metadata,
    OpenERC721Enumerable,
    OpenMarketable,
    OpenPauseable,
    OpenCloneable
{
    /// @notice tokenID of next minted NFT
    uint256 public tokenIdNext;

    /// @notice onlyMinter, by default only owner can mint, can be overriden
    modifier onlyMinter() virtual {
        require(msg.sender == owner(), "Not minter");
        _;
    }

    /// @notice burn NFT
    /// @param tokenID tokenID of NFT to burn
    function burn(uint256 tokenID)
        external
        override (IOpenNFTs)
        onlyTokenOwnerOrApproved(tokenID)
    {
        _burn(tokenID);
    }

    function mint(address minter, string memory tokenURI)
        public
        override (IOpenNFTs)
        onlyMinter
        returns (uint256 tokenID)
    {
        tokenID = tokenIdNext++;
        _mint(minter, tokenURI, tokenID);
    }

    /// @notice test if this interface is supported
    /// @param interfaceId interfaceId to test
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (
            OpenMarketable, OpenERC721Metadata, OpenERC721Enumerable, OpenCloneable, OpenPauseable
        )
        returns (bool)
    {
        return interfaceId == type(IOpenNFTs).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice _initialize
    /// @param name_ name of the NFT Collection
    /// @param symbol_ symbol of the NFT Collection
    /// @param owner_ owner of the NFT Collection
    // solhint-disable-next-line comprehensive-interface
    function _initialize(
        string memory name_,
        string memory symbol_,
        address owner_,
        uint256 mintPrice_,
        address receiver_,
        uint96 fee_,
        address treasury_,
        uint96 treasuryFee_,
        bool minimal_
    ) internal {
        tokenIdNext = 1;

        OpenCloneable._initialize("OpenNFTs", 4);
        OpenERC721Metadata._initialize(name_, symbol_);
        OpenERC173._initialize(owner_);
        OpenMarketable._initialize(mintPrice_, receiver_, fee_, treasury_, treasuryFee_, minimal_);
    }

    /// @notice _mint
    /// @param minter minter address
    /// @param tokenURI token metdata URI
    /// @param tokenID token ID
    function _mint(address minter, string memory tokenURI, uint256 tokenID)
        internal
        override (OpenERC721Enumerable, OpenERC721Metadata, OpenMarketable)
    {
        super._mint(minter, tokenURI, tokenID);
    }

    function _burn(uint256 tokenID)
        internal
        override (OpenERC721Enumerable, OpenERC721Metadata, OpenMarketable)
    {
        super._burn(tokenID);
    }

    function _transferFromBefore(address from, address to, uint256 tokenID)
        internal
        override (OpenERC721, OpenMarketable, OpenERC721Enumerable)
    {
        super._transferFromBefore(from, to, tokenID);
    }
}