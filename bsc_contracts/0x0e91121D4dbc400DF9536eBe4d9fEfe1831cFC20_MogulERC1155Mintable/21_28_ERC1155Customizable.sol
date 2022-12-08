// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./Priceable.sol";

abstract contract ERC1155Customizable is Priceable, IERC1155 {
    using SafeMath for uint256;
    //==================================================
    // BASIC Data and functions
    //==================================================
    // Provides a default base from which URIs could be extracted
    string public baseURI;
    // Provides extenion of related to baseURI
    string public baseExtension;

    // Provides a specific URI mapping per NFT given
    mapping(uint256 => string) tokenURIs;

    // hiddenMetaData
    bool public revealed = false;
    string public hiddenMetadataUri = ""; //changed to public from private for testing

    event Revealed(bool revealed);

    function setHiddenMetadata(string memory _hiddenMetadataUri)
        external
        onlyAdmin
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setRevealed(bool _state) external onlyAdmin {
        revealed = _state;
        emit Revealed(revealed);
    }

    // Set Uri
    function setBaseUri(string calldata _newUri) external onlyAdmin {
        if (bytes(_newUri).length == 0) revert InvalidAction("Invalid BaseURI");
        baseURI = _newUri;
    }

    function setBaseExtension(string calldata _extension) external onlyAdmin {
        if (bytes(_extension).length == 0)
            revert InvalidAction("Invalid BaseExtension");
        baseExtension = _extension;
    }

    function setTokenUris(
        uint256[] calldata _tokenIds,
        string[] calldata _tokenURIs
    ) external onlyAdmin {
        if (_tokenIds.length != _tokenURIs.length)
            revert InvalidAction("TokenIds and tokenURIs must equal length");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            tokenURIs[_tokenIds[i]] = _tokenURIs[i];
            if (bytes(_tokenURIs[i]).length == 0) {
                delete tokenURIs[_tokenIds[i]];
            }
            emit URI(_tokenURIs[i], _tokenIds[i]);
        }
    }

    //==================================================
    // SUPPLY related Information and functions
    //==================================================
    // Max the tokenId could go up to
    uint256 public maxSupply;

    // Max quantity for each tokenId - Global
    uint256 public maxQuantityGlobal;

    uint256 public maxMintsPerTxGlobal;
    mapping(uint256 => uint256) public maxMintPerTx;

    // Max quantity for each individual nft is configuration exists
    mapping(uint256 => uint256) public maxQuantity;
    // Total Supply of tokens based on tokenId to satisfy with ERC1155 standard
    mapping(uint256 => uint256) public totalSupply;

    // Keeps track of the highest tokenId that has been minted
    uint256 public currentMaxTokenId;

    // Returns all mapped values in totalSupply mapping of requested ids along with max minted id
    function getTotalSupplies(uint256 from, uint256 to)
        external
        view
        returns (uint256[] memory, uint256)
    {
        uint256[] memory breakdown = new uint256[]((to - from) + 1);

        for (uint256 i = from; i <= to; i++) {
            breakdown[i - from] = totalSupply[i];
        }

        return (breakdown, currentMaxTokenId);
    }

    // Update maxSupply
    function setMaxSupply(uint256 _newSupply) external onlyAdmin {
        if (_newSupply < currentMaxTokenId) {
            revert InvalidAction(
                "New max supply cannot be lower than highest mint"
            );
        }
        maxSupply = _newSupply;
    }

    function setMaxQuantityGlobal(uint256 _newQuantity) external onlyAdmin {
        maxQuantityGlobal = _newQuantity;
    }

    function setMaxQuantity(
        uint256[] calldata _tokenIds,
        uint256[] calldata _newQuantities
    ) external onlyAdmin {
        if (_tokenIds.length != _newQuantities.length)
            revert InvalidAction("TokenIds and tokenURIs must equal length");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            maxQuantity[_tokenIds[i]] = _newQuantities[i];
        }
    }

    function setMaxMintsPerTxGlobal(uint256 _newMaxMint) external onlyAdmin {
        maxMintsPerTxGlobal = _newMaxMint;
    }
}