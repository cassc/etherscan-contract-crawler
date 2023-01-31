// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IMintPass.sol";

contract Patchworks is ERC721A, Ownable, ReentrancyGuard {
    // Maximum number of tokens to be minted per piece of artwork.
    uint8 private constant MAX_TOKENS_PER_ARTWORK = 30;

    // Patchworks mint pass contract address.
    address private constant MINT_PASS_CONTRACT_ADDRESS =
        0x1278fb63B150E1c9cC478824e589045729321c54;

    // Patchworks mint pass contract.
    IMintPass mintPassContract;

    // Number of tokens claimed for each piece of artwork.
    mapping(uint8 => uint8) private artworkClaimed;

    // Artwork id for each token.
    mapping(uint256 => uint8) private tokenArtworkId;

    // Whether the mint is currently active.
    bool private mintActive = false;

    // Base token uri.
    string private baseURI;

    constructor() ERC721A("Patchworks", "PWRKS") {
        mintPassContract = IMintPass(MINT_PASS_CONTRACT_ADDRESS);
    }

    /**
     * @notice Burn mint pass and mint new token.
     * @param _artworkId Artwork id to mint.
     * @param _mintPassTokenId Mint pass token id to burn.
     */
    function mint(uint8 _artworkId, uint256 _mintPassTokenId)
        external
        nonReentrant
    {
        // Check mint is active.
        if (!mintActive) {
            revert MintInactive();
        }
        // Check mint pass token owned by msg.sender.
        if (mintPassContract.ownerOf(_mintPassTokenId) != msg.sender) {
            revert TokenNotOwnedBySender();
        }
        // Check artworkId can be minted.
        if (artworkClaimed[_artworkId] == MAX_TOKENS_PER_ARTWORK) {
            revert InsufficientRemainingTokensForArtwork();
        }
        // Increment artworkClaimed entry.
        artworkClaimed[_artworkId]++;
        // Set artworkId for new token. Avoiding `_setExtraData` as all token indices may not be initialized.
        tokenArtworkId[_nextTokenId()] = _artworkId;
        // Burn token
        mintPassContract.burn(_mintPassTokenId);
        // Mint new token
        _mint(msg.sender, 1);
    }

    /**
     * @notice Burn mint passes and mint new tokens.
     * @notice Array arguments must have same length.
     * @param _artworkIds Array of artwork ids to mint.
     * @param _mintPassTokenIds Array of mint pass token ids to burn.
     */
    function mint(
        uint8[] calldata _artworkIds,
        uint256[] calldata _mintPassTokenIds
    ) external nonReentrant {
        // Check mint is active.
        if (!mintActive) {
            revert MintInactive();
        }
        // Check array arguments have same length.
        if (_artworkIds.length != _mintPassTokenIds.length) {
            revert MismatchedArrayArgumentLengths();
        }
        for (uint256 i = 0; i < _mintPassTokenIds.length; i++) {
            // Check mint pass token owned by msg.sender.
            if (mintPassContract.ownerOf(_mintPassTokenIds[i]) != msg.sender) {
                revert TokenNotOwnedBySender();
            }
            // Check artworkId can be minted.
            if (artworkClaimed[_artworkIds[i]] == MAX_TOKENS_PER_ARTWORK) {
                revert InsufficientRemainingTokensForArtwork();
            }
            // Increment artworkClaimed entry.
            artworkClaimed[_artworkIds[i]]++;
            // Set artworkId for new token. Avoiding `_setExtraData` as all token indices may not be initialized.
            tokenArtworkId[_nextTokenId() + i] = _artworkIds[i];
            // Burn token
            mintPassContract.burn(_mintPassTokenIds[i]);
        }
        // Mint new token(s).
        _mint(msg.sender, _artworkIds.length);
    }

    /**
     * @notice Set the `mintActive` state flag.
     * @param _mintActive New `mintActive` value.
     */
    function setMintActive(bool _mintActive) external onlyOwner {
        mintActive = _mintActive;
    }

    /**
     * @notice Set the base token uri.
     * @notice Use restricted to contract owner.
     * @param _baseTokenURI New `baseURI` value.
     */
    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseURI = _baseTokenURI;
    }

    /**
     * @notice Returns artwork id for a token.
     * @param _tokenId Token id to check.
     */
    function getArtworkIdForTokenId(uint256 _tokenId)
        public
        view
        returns (uint8)
    {
        if (!_exists(_tokenId)) {
            revert NonExistentToken();
        }
        return tokenArtworkId[_tokenId];
    }

    /**
     * @notice Returns number of tokens minted for artwork ids.
     * @param _artworkIds[] Array of artwork ids to check.
     */
    function getTotalSuppliesForArtworkIds(uint8[] calldata _artworkIds)
        public
        view
        returns (uint8[] memory)
    {
        uint8[] memory totalSupplies = new uint8[](_artworkIds.length);
        for (uint256 i = 0; i < _artworkIds.length; i++) {
            totalSupplies[i] = artworkClaimed[_artworkIds[i]];
        }
        return totalSupplies;
    }

    /**
     * @notice Returns `mintActive`.
     */
    function getIsMintActive() public view returns (bool) {
        return mintActive;
    }

    /**
     * @notice Returns `baseURI`.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice Returns the first token id.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     * @notice Withdraw all funds to the contract owners address
     * @notice Use restricted to contract owner
     * @dev `transfer` and `send` assume constant gas prices. This function
     * is onlyOwner, so we accept the reentrancy risk that `.call.value` carries.
     */
    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        if (!success) {
            revert WithdrawFailed();
        }
    }

    /**
     * @notice Prevent accidental ETH transfer
     */
    fallback() external payable {
        revert NotImplemented();
    }

    /**
     * @notice Prevent accidental ETH transfer
     */
    receive() external payable {
        revert NotImplemented();
    }
}

/**
 * Withdraw failed
 */
error WithdrawFailed();

/**
 * Function not implemented
 */
error NotImplemented();

/**
 * Mismatched array argument lengths
 */
error MismatchedArrayArgumentLengths();

/**
 * Mint is not active
 */
error MintInactive();

/**
 * Token not owned by msg.sender
 */
error TokenNotOwnedBySender();

/**
 * Artwork id is sold out
 */
error InsufficientRemainingTokensForArtwork();

/**
 * Non-existent token
 */
error NonExistentToken();