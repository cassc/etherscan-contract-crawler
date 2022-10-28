// SPDX-License-Identifier: MIT

/// @title Halloween in Brooklyn: Trick-or-Treat
/// @author transientlabs.xyz

pragma solidity 0.8.14;

import "ERC1155TLCore.sol";

contract TrickOrTreat is ERC1155TLCore {

    address public externalMinter;

    constructor(address minter, address admin, address payout)
    ERC1155TLCore(admin, payout, "Halloween in Brooklyn: Trick-or-Treat")
    {
        externalMinter = minter;
    }

    /// @notice function to set external minter address
    /// @dev requires admin or owner
    function setExternalMinter(address newMinter) external adminOrOwner {
        externalMinter = newMinter;
    }


    /// @notice function to ovverride standard mint function
    function mint(uint256 tokenId, uint16 numToMint, bytes32[] calldata merkleProof) external override payable nonReentrant {
        revert("disabled");
    }

    /// @notice function to mint token from trusted sender
    /// @dev token must be created and mint must be open
    function mintExternal(uint256 tokenId, uint256 numToMint, address recipient) external nonReentrant {
        TokenDetails storage token = _tokenDetails[tokenId];
        require(token.created, "Token ID not valid");
        require(token.mintStatus, "Mint not open");
        require(msg.sender == externalMinter, "Cannot mint from non trusted address");

        _mint(recipient, tokenId, numToMint, "");
    }

}