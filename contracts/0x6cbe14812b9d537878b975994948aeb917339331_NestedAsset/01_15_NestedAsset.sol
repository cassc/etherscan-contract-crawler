// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./abstracts/OwnableFactoryHandler.sol";

/// @title Collection of NestedNFTs used to represent ownership of real assets stored in NestedReserves
/// @dev Only NestedFactory contracts are allowed to call functions that write to storage
contract NestedAsset is ERC721Enumerable, OwnableFactoryHandler {
    using Counters for Counters.Counter;

    /* ----------------------------- VARIABLES ----------------------------- */

    Counters.Counter private _tokenIds;

    /// @dev Base URI (API)
    string public baseUri;

    /// @dev Token URI when not revealed
    string public unrevealedTokenUri;

    /// @dev NFT contract URI
    string public contractUri;

    /// @dev Stores the original asset of each asset
    mapping(uint256 => uint256) public originalAsset;

    /// @dev Stores owners of burnt assets
    mapping(uint256 => address) public lastOwnerBeforeBurn;

    /// @dev True if revealed, false if not.
    bool public isRevealed;

    /* ---------------------------- CONSTRUCTORS --------------------------- */

    constructor() ERC721("NestedNFT", "NESTED") {}

    /* ----------------------------- MODIFIERS ----------------------------- */

    /// @dev Reverts the transaction if the address is not the token owner
    modifier onlyTokenOwner(address _address, uint256 _tokenId) {
        require(_address == ownerOf(_tokenId), "NA: FORBIDDEN_NOT_OWNER");
        _;
    }

    /* ------------------------------- VIEWS ------------------------------- */

    /// @notice Get the Uniform Resource Identifier (URI) for `tokenId` token.
    /// @param _tokenId The id of the NestedAsset
    /// @return The token Uniform Resource Identifier (URI)
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");
        if (isRevealed) {
            return super.tokenURI(_tokenId);
        } else {
            return unrevealedTokenUri;
        }
    }

    /// @inheritdoc ERC721
    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    /// @notice Returns the owner of the original token if the token was replicated
    /// If the original asset was burnt, the last owner before burn is returned
    /// @param _tokenId The asset for which we want to know the original owner
    /// @return The owner of the original asset
    function originalOwner(uint256 _tokenId) external view returns (address) {
        uint256 originalAssetId = originalAsset[_tokenId];

        if (originalAssetId != 0) {
            return _exists(originalAssetId) ? ownerOf(originalAssetId) : lastOwnerBeforeBurn[originalAssetId];
        }
        return address(0);
    }

    /* ---------------------------- ONLY FACTORY --------------------------- */

    /// @notice Mints an ERC721 token for the user and stores the original asset used to create the new asset if any
    /// @param _owner The account address that signed the transaction
    /// @param _replicatedTokenId The token id of the replicated asset, 0 if no replication
    /// @return The minted token's id
    function mint(address _owner, uint256 _replicatedTokenId) public onlyFactory returns (uint256) {
        _tokenIds.increment();

        uint256 tokenId = _tokenIds.current();
        _safeMint(_owner, tokenId);

        // Stores the first asset of the replication chain as the original
        if (_replicatedTokenId == 0) {
            return tokenId;
        }

        require(_exists(_replicatedTokenId), "NA: NON_EXISTENT_TOKEN_ID");
        require(tokenId != _replicatedTokenId, "NA: SELF_DUPLICATION");

        uint256 originalTokenId = originalAsset[_replicatedTokenId];
        originalAsset[tokenId] = originalTokenId != 0 ? originalTokenId : _replicatedTokenId;

        return tokenId;
    }

    /// @notice Burns an ERC721 token
    /// @param _owner The account address that signed the transaction
    /// @param _tokenId The id of the NestedAsset
    function burn(address _owner, uint256 _tokenId) external onlyFactory onlyTokenOwner(_owner, _tokenId) {
        lastOwnerBeforeBurn[_tokenId] = _owner;
        _burn(_tokenId);
    }

    /* ----------------------------- ONLY OWNER ---------------------------- */

    /// @notice Update isRevealed to reveal or hide the token URI
    function setIsRevealed(bool _isRevealed) external onlyOwner {
        isRevealed = _isRevealed;
    }

    /// @notice Set the base URI (once revealed)
    /// @param _baseUri The new baseURI
    function setBaseURI(string memory _baseUri) external onlyOwner {
        require(bytes(_baseUri).length != 0, "NA: EMPTY_URI");
        baseUri = _baseUri;
    }

    /// @notice Set the unrevealed token URI (fixed)
    /// @param _newUri The new unrevealed URI
    function setUnrevealedTokenURI(string memory _newUri) external onlyOwner {
        require(bytes(_newUri).length != 0, "NA: EMPTY_URI");
        unrevealedTokenUri = _newUri;
    }

    /// @notice Set the contract URI
    /// @param _newUri The new contract URI
    function setContractURI(string memory _newUri) external onlyOwner {
        contractUri = _newUri;
    }
}