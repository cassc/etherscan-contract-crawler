// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./SoulboundBurnable.sol";

/// @custom:security-contact [email protected]
contract LayerID_V1_1 is Pausable, Ownable, SoulboundBurnable {
    /**
     * Use for tracking users/tokens
     */
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string private _rootURI =
        "https://app.staging.layer.com/api/layer-id/metadata/";

    // Events and errors
    event NewHolderRegistered(uint256 id, address indexed owner);

    event HolderTokenBurned(uint256 id, address indexed owner);

    error HolderAlreadyExists(address holder);

    constructor() ERC721("Layer ID", "LAYER") {}

    /**
     * Base URI to be used on NFT metadata
     */
    function _baseURI() internal view override returns (string memory) {
        return _rootURI;
    }

    /**
     *  Owner function for setting the rootURI
     *
     *  @param rootURI – Root URI to set
     */
    function setRootURI(string memory rootURI) external onlyOwner {
        _rootURI = rootURI;
    }

    /**
     * Pause contract
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * Unpause contract
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
    * Registers new Layer ID, containing basic information about the holder later on minting the NFT.

    * @param holder – address
    * @param uri – CDI hash referencing the NFT metadata
    * @return _tokenId
    */
    function registerLayerIDHolder(
        address holder,
        string memory uri
    ) public onlyOwner whenNotPaused returns (uint256) {
        // Only allow one token per address
        if (balanceOf(holder) > 0) {
            revert HolderAlreadyExists(holder);
        }

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        emit NewHolderRegistered(tokenId, holder);

        _safeMint(holder, tokenId);
        _setTokenURI(tokenId, uri);

        return tokenId;
    }

    /**
     * Allow burning of tokens by owner
     */
    function burnToken(uint256 tokenId) external onlyOwner {
        emit HolderTokenBurned(tokenId, ownerOf(tokenId));
        _burn(tokenId);
    }
}