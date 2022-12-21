// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface IERC721Soulbound is IERC721 {
    
    /// A guideline to standardlize burn-authorization's number coding
    enum BurnAuth {
        IssuerOnly,
        OwnerOnly,
        Both,
        Neither
    }

    /// @notice Emitted when a soulbound token is issued.
    /// @dev This emit is an add-on to nft's transfer emit in order to distinguish sbt 
    /// from vanilla nft while providing backward compatibility.
    /// @param from The issuer
    /// @param to The receiver
    /// @param tokenId The id of the issued token
    event Issued (
        address indexed from,
        address indexed to,
        uint256 indexed tokenId,
        BurnAuth burnAuth
    );

    /// @notice provides burn authorization of the token id.
    /// @dev unassigned tokenIds are invalid, and queries do throw
    /// @param tokenId The identifier for a token.
    function burnAuth(uint256 tokenId) external view returns (BurnAuth);

}