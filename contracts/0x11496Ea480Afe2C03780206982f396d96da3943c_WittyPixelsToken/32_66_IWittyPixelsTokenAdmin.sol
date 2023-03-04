// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC165.sol";
import "../WittyPixels.sol";

interface IWittyPixelsTokenAdmin {
    
    event Launched(uint256 tokenId, WittyPixels.ERC721TokenEvent theEvent);
    event Minting(uint256 tokenId, string baseURI, WitnetV2.RadonSLA witnetSLA);

    /// @notice Settle next token's event related metadata.
    /// @param theEvent Event metadata, including name, venut, starting and ending timestamps.
    /// @param theCharity Charity metadata, if any. Charity address and percentage > 0 must be provided.
    function launch(
            WittyPixels.ERC721TokenEvent calldata theEvent,
            WittyPixels.ERC721TokenCharity calldata theCharity
        ) external returns (uint256 tokenId);
    
    /// @notice Mint next WittyPixelsTM token: one new token id per ERC721TokenEvent where WittyPixelsTM is played.
    /// @param witnetSLA Witnessing SLA parameters of underlying data requests to be solved by the Witnet oracle.
    function mint(WitnetV2.RadonSLA calldata witnetSLA) external payable;

    /// @notice Sets collection's base URI.
    function setBaseURI(string calldata baseURI) external;

    /// @notice Sets token vault contract to be used as prototype in following mints.
    function setTokenVaultFactoryPrototype(address prototype) external;    
}