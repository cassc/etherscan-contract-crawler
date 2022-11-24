// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IMetadataRenderer} from "zora-drops-contracts/interfaces/IMetadataRenderer.sol";
import {ITokenUriMetadataRenderer} from "./interfaces/ITokenUriMetadataRenderer.sol";
import {IERC721AUpgradeable} from "ERC721A-Upgradeable/IERC721AUpgradeable.sol";
import {ERC721DropMinterInterface} from "./interfaces/ERC721DropMinterInterface.sol";
import {Ownable} from "openzeppelin-contracts/access/ownable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";

/**
 * @title TokenUriMinter
 * @notice Initializes token URIs via ITokenUriMetadataRenderer.updateTokenURI
 * @notice not audited use at own risk
 * @author Max Bochman
 * @dev can be used by any ZORA Drop Contract
 * @dev grant ERC721Drop.MINTER_ROLE() to signers AND this contract
 *
 */
contract TokenUriMinter is  
    Ownable, 
    ReentrancyGuard 
{

    // ||||||||||||||||||||||||||||||||
    // ||| ERRORS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||     

    /// @notice Action is unable to complete because msg.value is incorrect
    error WrongPrice();

    /// @notice Action is unable to complete because minter contract has not recieved minting role
    error MinterNotAuthorized();

    /// @notice Funds transfer not successful to drops contract
    error TransferNotSuccessful();

    // ||||||||||||||||||||||||||||||||
    // ||| EVENTS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice mint notice
    event Mint(address minter, address mintRecipient, uint256 tokenId, string tokenURI);
    
    /// @notice mintPrice updated notice
    event MintPriceUpdated(address sender, uint256 newMintPrice);

    /// @notice metadataRenderer updated notice
    event MetadataRendererUpdated(address sender, address newRenderer);    

    // ||||||||||||||||||||||||||||||||
    // ||| VARIABLES ||||||||||||||||||
    // ||||||||||||||||||||||||||||||||      
    
    bytes32 public immutable MINTER_ROLE = keccak256("MINTER");

    uint256 public mintPricePerToken;

    address public tokenUriMetadataRenderer;

    // ||||||||||||||||||||||||||||||||
    // ||| CONSTRUCTOR ||||||||||||||||
    // ||||||||||||||||||||||||||||||||  

    constructor(uint256 _mintPricePerToken, address _tokenUriMetadataRenderer) {
        mintPricePerToken = _mintPricePerToken;
        tokenUriMetadataRenderer = _tokenUriMetadataRenderer;
    }

    // ||||||||||||||||||||||||||||||||
    // ||| PUBLIC MINTING FUNCTION ||||
    // |||||||||||||||||||||||||||||||| 

    /// @dev calls adminMint function in ZORA Drop contract + sets tokenURI for minted tokens
    /// @param zoraDrop ZORA Drop contract to mint from
    /// @param mintRecipient address to recieve minted tokens
    /// @param tokenURIs string tokenURI to initialize token with
    function customMint(
        address zoraDrop,
        address mintRecipient,
        string[] memory tokenURIs
    ) external payable nonReentrant {
        // check if CustomPricingMinter contract has MINTER_ROLE on target ZORA Drop contract
        if (
            !ERC721DropMinterInterface(zoraDrop).hasRole(
                MINTER_ROLE,
                address(this)
            )
        ) {
            revert MinterNotAuthorized();
        }

        // check if total mint price is correct
        if (msg.value != mintPricePerToken * tokenURIs.length) {
            revert WrongPrice();
        }

        // call internal minting function
        _tokenURIMint(zoraDrop, mintRecipient, tokenURIs);

        // Transfer funds to zora drop contract
        (bool bundleSuccess, ) = zoraDrop.call{value: msg.value}("");
        if (!bundleSuccess) {
            revert TransferNotSuccessful();
        }
    }

    // ||||||||||||||||||||||||||||||||
    // ||| INTERNAL MINTING FUNCTION ||
    // ||||||||||||||||||||||||||||||||

    function _tokenURIMint(
        address zoraDrop,
        address mintRecipient,
        string[] memory tokenURIs
    ) internal {

        // calculate tokenURI array length
        uint256 tokenUriArrayLength = tokenURIs.length;

        // call admintMint function on target ZORA contract
        uint256 lastTokenIdMinted = ERC721DropMinterInterface(zoraDrop).adminMint(mintRecipient, tokenUriArrayLength);

        // for length of tokenURIs array, emit Mint event and updateTokenURI
        for (uint256 i = 0; i < tokenUriArrayLength; i++) {

            uint256 specificTokenId = lastTokenIdMinted - (tokenUriArrayLength - (i + 1));

            emit Mint(
                msg.sender,
                mintRecipient,
                specificTokenId,
                tokenURIs[i]
            );

            ITokenUriMetadataRenderer(tokenUriMetadataRenderer).updateTokenURI(
                zoraDrop,
                specificTokenId,
                tokenURIs[i]
            );
        }
    }

    // ||||||||||||||||||||||||||||||||
    // ||| ADMIN FUNCTIONS ||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @dev updates mintPricePerToken variable
    /// @param newMintPricePerToken new mintPrice value
    function setMintPrice(uint256 newMintPricePerToken) public onlyOwner {

        mintPricePerToken = newMintPricePerToken;

        emit MintPriceUpdated(msg.sender, newMintPricePerToken);
    }    

    /// @dev updates tokenUriMetadataRenderer variable
    /// @param newRenderer new tokenUriMetadataRenderer address
    function setMetadataRenderer(address newRenderer) public onlyOwner {

        tokenUriMetadataRenderer = newRenderer;

        emit MetadataRendererUpdated(msg.sender, newRenderer);
    }       
}