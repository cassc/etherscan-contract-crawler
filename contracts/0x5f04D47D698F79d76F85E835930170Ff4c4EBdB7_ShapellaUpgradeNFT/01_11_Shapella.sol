/**********************************************************************************************************
  ____|  |    |                                             ____|              |                   | 
  __|    __|  __ \    _ \   __|  _ \  |   |  __ `__ \       __| \ \   /  _ \   | \ \   /  _ \   _` | 
  |      |    | | |   __/  |     __/  |   |  |   |   |      |    \ \ /  (   |  |  \ \ /   __/  (   | 
 _____| \__| _| |_| \___| _|   \___| \__,_| _|  _|  _|     _____| \_/  \___/  _|   \_/  \___| \__,_| 


      ___           ___           ___           ___           ___           ___       ___       ___     
     /\  \         /\__\         /\  \         /\  \         /\  \         /\__\     /\__\     /\  \    
    /::\  \       /:/  /        /::\  \       /::\  \       /::\  \       /:/  /    /:/  /    /::\  \   
   /:/\ \  \     /:/__/        /:/\:\  \     /:/\:\  \     /:/\:\  \     /:/  /    /:/  /    /:/\:\  \  
  _\:\~\ \  \   /::\  \ ___   /::\~\:\  \   /::\~\:\  \   /::\~\:\  \   /:/  /    /:/  /    /::\~\:\  \ 
 /\ \:\ \ \__\ /:/\:\  /\__\ /:/\:\ \:\__\ /:/\:\ \:\__\ /:/\:\ \:\__\ /:/__/    /:/__/    /:/\:\ \:\__\
 \:\ \:\ \/__/ \/__\:\/:/  / \/__\:\/:/  / \/__\:\/:/  / \:\~\:\ \/__/ \:\  \    \:\  \    \/__\:\/:/  /
  \:\ \:\__\        \::/  /       \::/  /       \::/  /   \:\ \:\__\    \:\  \    \:\  \        \::/  / 
   \:\/:/  /        /:/  /        /:/  /         \/__/     \:\ \/__/     \:\  \    \:\  \       /:/  /  
    \::/  /        /:/  /        /:/  /                     \:\__\        \:\__\    \:\__\     /:/  /   
     \/__/         \/__/         \/__/                       \/__/         \/__/     \/__/     \/__/   


**********************************************************************************************************/

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Revert with an error when the mint is not active
 */
error MintNotActive();

/**
 * @dev Revert with an error mint to recipients count does not match supply
 */
error RecipientLengthDoesNotMatchSupply();

/**
 * @dev Revert with an error when trying to set the mint active when it was already set active
 */
error AlreadySetActive();

/**
 * @dev Revert with an error when trying to mint an invalid token
 */
error InvalidToken();

/**
 * @dev Revert if we've minted all the tokens
 */
error SoldOut();

/**
 * @dev Revert if we have frozen setting URIs
 */
error TokenUrisFrozen();

contract ShapellaUpgradeNFT is ERC721, Ownable {
    string private CONTRIBUTOR_TOKEN_URI;
    string private OPEN_EDITION_TOKEN_URI;

    uint128 private constant CONTRIBUTOR_SUPPLY = 128;
    uint128 private constant CONTRIBUTOR_STARTING_TOKEN_ID = 1;

    uint128 private constant OPEN_EDITION_STARTING_TOKEN_ID = CONTRIBUTOR_SUPPLY + CONTRIBUTOR_STARTING_TOKEN_ID;

    uint64 private constant OPEN_EDITION_LENGTH = 3 days;
    uint128 private nextTokenId = OPEN_EDITION_STARTING_TOKEN_ID;

    uint64 public mintOpenUntil;

    // Until true, admins can set token URIs
    bool public isFrozen = false;

    constructor(
        string memory contributorTokenUri,
        string memory openEditionTokenUri
    ) ERC721("ShapellaUpgrade", "SHAPELLA") {
        CONTRIBUTOR_TOKEN_URI = contributorTokenUri;
        OPEN_EDITION_TOKEN_URI = openEditionTokenUri;
    }

    /**
     * @notice Mint an open edition NFT - restricted to a specific time window
     */
    function publicMint() external {
        if (block.timestamp > mintOpenUntil) {
            revert MintNotActive();
        }
        if (nextTokenId == type(uint128).max) {
            revert SoldOut();
        }
        _mint(_msgSender(), nextTokenId++);
    }

    /**
     * @notice See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (tokenId < OPEN_EDITION_STARTING_TOKEN_ID) {
            return CONTRIBUTOR_TOKEN_URI;
        }

        _requireMinted(tokenId);
        return OPEN_EDITION_TOKEN_URI;
    }

    /**
     * @notice Set the open edition mint to active
     * @dev Restricted to admins. Cannot set active more than once.
     */
    function setActive() external {
        if (mintOpenUntil != 0) {
            revert AlreadySetActive();
        }

        mintOpenUntil = uint64(block.timestamp) + OPEN_EDITION_LENGTH;
    }

    /**
     * @notice Mint a token
     * @dev Restricted to admins.
     * @param tokenId The token to mint
     * @param recipient The address to mint the token to
     */
    function adminMintTo(uint256 tokenId, address recipient) external onlyOwner {
        if (tokenId >= OPEN_EDITION_STARTING_TOKEN_ID) {
            revert InvalidToken();
        }
        _mint(recipient, tokenId);
    }

    /**
     * @notice Mint contributor NFTs
     * @dev Restricted to admins
     * @param recipients The recipient addresses to mint the tokens to
     */
    function adminMintContributorNfts(address[] memory recipients) external onlyOwner {
        if (recipients.length != CONTRIBUTOR_SUPPLY) {
            revert RecipientLengthDoesNotMatchSupply();
        }

        for (uint256 i = 0; i < CONTRIBUTOR_SUPPLY; i++) {
            _mint(recipients[i], CONTRIBUTOR_STARTING_TOKEN_ID + i);
        }
    }

    /**
     * @notice Set token URIs
     * @dev Restricted to admins
     * @param contributorTokenUri CONTRIBUTOR_TOKEN_URI value
     * @param openEditionTokenUri OPEN_EDITION_TOKEN_URI value
     */
    function adminSetTokenUris(
        string memory contributorTokenUri,
        string memory openEditionTokenUri
    ) external onlyOwner {
        if (isFrozen == true) {
            revert TokenUrisFrozen();
        }
        CONTRIBUTOR_TOKEN_URI = contributorTokenUri;
        OPEN_EDITION_TOKEN_URI = openEditionTokenUri;
    }

    /**
     * @notice Sets isFrozen flag to true
     * @dev Restricted to admins; cannot be undone
     */
    function adminSetFrozen() external onlyOwner {
        isFrozen = true;
    }
}