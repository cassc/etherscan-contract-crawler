// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "../interfaces/IMint.sol";

/// @notice This contract is intended to be used with ERC721Handler contract.

contract ERC721Safe {
    /// @notice Used to gain custoday of deposited token.
    ///
    /// @param tokenAddress Address of ERC721 to transfer.
    /// @param owner Address of current token owner.
    /// @param recipient Address to transfer token to.
    /// @param tokenID ID of token to transfer.
    function lockERC721(
        address tokenAddress,
        address owner,
        address recipient,
        uint256 tokenID
    ) internal {
        IERC721 erc721 = IERC721(tokenAddress);
        erc721.transferFrom(owner, recipient, tokenID);
    }

    /// @notice Transfers custody of token to recipient.
    ///
    /// @param tokenAddress Address of ERC721 to transfer.
    /// @param owner Address of current token owner.
    /// @param recipient Address to transfer token to.
    /// @param tokenID ID of token to transfer.
    // slither-disable-next-line calls-loop
    function releaseERC721(
        address tokenAddress,
        address owner,
        address recipient,
        uint256 tokenID
    ) internal {
        IERC721 erc721 = IERC721(tokenAddress);
        erc721.transferFrom(owner, recipient, tokenID);
    }

    /// @notice Used to create new ERC721s.
    ///
    /// @param tokenAddress Address of ERC721 to mint.
    /// @param recipient Address to mint token to.
    /// @param tokenID ID of token to mint.
    /// @param data Optional data to send along with mint call.
    // slither-disable-next-line calls-loop
    function mintERC721(
        address tokenAddress,
        address recipient,
        uint256 tokenID,
        bytes memory data
    ) internal {
        IMint erc721 = IMint(tokenAddress);
        erc721.mint(recipient, tokenID, string(data));
    }

    /// @notice Used to burn ERC721s.
    ///
    /// @param tokenAddress Address of ERC721 to burn.
    /// @param tokenID ID of token to burn.
    function burnERC721(
        address tokenAddress,
        address owner,
        uint256 tokenID
    ) internal {
        ERC721Burnable erc721 = ERC721Burnable(tokenAddress);
        require(erc721.ownerOf(tokenID) == owner, "not the owner");
        erc721.burn(tokenID);
    }
}