// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {IERC721MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import { IERC5192 } from "./IERC5192.sol";

/// @author [email protected]
/// @notice Base non-transferrable optimized nft contract
/// @notice Modified for base class usage and supports EIP-5192
abstract contract CuratorSkeletonNFT is
    IERC165Upgradeable,
    IERC721Upgradeable,
    IERC721MetadataUpgradeable,
    IERC5192
{
    /// @notice modifier signifying contract function is not supported
    modifier notSupported() {
        revert("Fn not supported: nontransferrable NFT");
        _;
    }

    /**
        Common NFT functions
     */

    /// @notice NFT Metadata Name
    function name() virtual external view returns (string memory);

    /// @notice NFT Metadata Symbol
    function symbol() virtual external view returns (string memory);

    /*
     *  EIP-5192 Functions
     */
    function locked(uint256) external pure returns (bool) {
      return true;
    }


    /*
     *  NFT Functions
     */

    /// @notice blanaceOf getter for NFT compat
    function balanceOf(address user) public virtual view returns (uint256);

    /// @notice ownerOf getter, checks if token exists
    function ownerOf(uint256 id) public virtual view returns (address);

    /// @notice approvals not supported
    function getApproved(uint256) public pure returns (address) {
        return address(0x0);
    }

    /// @notice tokenURI method
    function tokenURI(uint256 tokenId) external virtual view returns (string memory);

    /// @notice contractURI method
    function contractURI() external virtual view returns (string memory);

    /// @notice approvals not supported
    function isApprovedForAll(address, address) public pure returns (bool) {
        return false;
    }

    /// @notice approvals not supported
    function approve(address, uint256) public notSupported {}

    /// @notice approvals not supported
    function setApprovalForAll(address, bool) public notSupported {}

    /// @notice internal safemint function
    function _mint(address to, uint256 id) internal {
        require(
            to != address(0x0),
            "Mint: cannot mint to 0x0"
        );
        emit Locked(id);
        _transferFrom(address(0x0), to, id);
    }

    /// @notice intenral safeBurn function
    function _burn(uint256 id) internal {
      _transferFrom(ownerOf(id), address(0x0), id);
    }

    /// @notice transfer function to be overridden
    function transferFrom(
        address from,
        address to,
        uint256 checkTokenId
    ) external virtual {}

    /// @notice not supported
    function safeTransferFrom(
        address,
        address,
        uint256
    ) public notSupported {
        // no impl
    }

    /// @notice not supported
    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) public notSupported {
        // no impl
    }

    /// @notice internal transfer function for virtual nfts
    /// @param from address to move from
    /// @param to address to move to
    /// @param id id of nft to move
    /// @dev no storage used in this function
    function _transferFrom(
        address from,
        address to,
        uint256 id
    ) internal {
        emit Transfer(from, to, id);
    }

    /// @notice erc721 enumerable partial impl
    function totalSupply() public virtual view returns (uint256);

    /// @notice Supports ERC721, ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC165Upgradeable).interfaceId ||
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            interfaceId == type(IERC5192).interfaceId;
    }

    /// @notice internal exists fn for a given token id
    function _exists(uint256 id) internal virtual view returns (bool);
}