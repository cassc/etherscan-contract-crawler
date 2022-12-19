// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "base64-sol/base64.sol";
import "./lib/ERC721Queryable.sol";

/**
 * @title Chatcasso NFT
 * @dev A NFT contract following ERC721 standard with following variations
 *   - Initializable to be compatible with the proxy pattern
 *   - Implemented with Queryable instead of Enumerable to save gas in most cases (for fewer than 10k editions)
 *   - On-chain meta data with Base64 JSON encoding
 *   - Minting / Burning features, with the minting cost transferred to the creator
 */
contract ChatcassoNFT is ERC721Queryable, Ownable {
    using Strings for uint256;
    using Strings for address;

    error ChatcassoNFT__NotFound();
    error ChatcassoNFT__AlreadyInitalized();
    error ChatcassoNFT__InvalidMintingCost(uint256 expected, uint256 actual);
    error ChatcassoNFT__MaximumMinted();
    error ChatcassoNFT__MintingCostTransferFailed();
    error ChatcassoNFT__NotApproved();
    error ChatcassoNFT__DescriptionTooLong();

    struct MetaData {
        uint40 initializedAt;
        uint32 maxSupply;
        uint184 mintingCost;
        string description;
    }
    MetaData private _metaData;
    string[] private _imageCIDs;

    event Mint(address indexed to, uint256 indexed tokenId);
    event Burn(uint256 indexed tokenId);

    modifier checkTokenExists(uint256 tokenId) {
        if (!_exists(tokenId)) revert ChatcassoNFT__NotFound();
        _;
    }

    function init(
        address owner_,
        string calldata name_,
        string calldata symbol_,
        string calldata description_,
        uint32 maxSupply_,
        uint184 mintingCost_,
        string calldata imageCID_
    ) external {
        if(_metaData.initializedAt != 0) revert ChatcassoNFT__AlreadyInitalized();

        // ERC721 attributes
        _name = name_;
        _symbol = symbol_;

        // Custom attributes
        _metaData = MetaData(uint40(block.timestamp), maxSupply_, mintingCost_, description_);

        // Transfer ownership so they can edit info on marketplaces like OpenSea
        _transferOwnership(owner_);

        // Mint edition #0 to the creator
        _mintNewEdition(owner_, imageCID_);
    }

    function mint(address to, string calldata imageCID_) external payable {
        uint256 mintingCost = uint256(_metaData.mintingCost);
        if(msg.value != mintingCost) revert ChatcassoNFT__InvalidMintingCost(mintingCost, msg.value);
        if(nextTokenId() >= _metaData.maxSupply) revert ChatcassoNFT__MaximumMinted();

        if (mintingCost > 0) {
            (bool sent, ) = (owner()).call{ value: mintingCost }("");
            if (!sent) revert ChatcassoNFT__MintingCostTransferFailed();
        }

        _mintNewEdition(to, imageCID_);
    }

    function _mintNewEdition(address to, string calldata imageCID_) private {
        uint256 nextId = nextTokenId();

        _imageCIDs.push(imageCID_);
        assert(nextId == _imageCIDs.length - 1);

        _safeMint(to, nextId);

        emit Mint(to, nextId);
    }

    function burn(uint256 tokenId) external {
        if(!_isApprovedOrOwner(msg.sender, tokenId)) revert ChatcassoNFT__NotApproved(); // This will check existence of token

        delete _imageCIDs[tokenId];
        _burn(tokenId);

        emit Burn(tokenId);
    }

    // MARK: - Update metadata

    function updateMintingCost(uint184 mintingCost) external onlyOwner {
        _metaData.mintingCost = mintingCost;
    }

    function updateDescription(string calldata description) external onlyOwner {
        if (bytes(description).length > 1000) revert ChatcassoNFT__DescriptionTooLong(); // ~900 gas per character

        _metaData.description = description;
    }

    // MARK: - On-chain meta data

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(tokenJSON(tokenId)))));
    }

    // @dev Contract-level metadata for Opeansea
    // REF: https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(contractJSON()))));
    }


    function tokenJSON(uint256 tokenId) public view checkTokenExists(tokenId) returns (string memory) {
        return string(abi.encodePacked(
            '{"name":"',
            _name, ' #', tokenId.toString(),
            '","description":"',
            _metaData.description,
            '","image":"',
            'ipfs://', _imageCIDs[tokenId],
            '"}'
        ));
    }

    function contractJSON() public view returns (string memory) {
        return string(abi.encodePacked(
            '{"name":"',
            _name,
            '","description":"',
            _metaData.description,
            '","image":"',
            'ipfs://', _imageCIDs[0],
            '","external_link":"https://chatcasso.com/collection/',
            block.chainid.toString(), '/', address(this).toHexString(),
            '"}'
        ));
    }

    // MARK: - External utility functions

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function metaData() external view returns (
        address owner_,
        string memory name_,
        uint40 initializedAt_,
        uint32 maxSupply_,
        uint184 mintingCost_,
        string memory description_,
        uint256 nextTokenId_,
        uint256 totalSupply_,
        string memory genesisImage_
    ) {
        owner_ = owner();
        name_ = _name;
        initializedAt_ = _metaData.initializedAt;
        maxSupply_ = _metaData.maxSupply;
        mintingCost_ = _metaData.mintingCost;
        description_ = _metaData.description;
        nextTokenId_ = nextTokenId();
        totalSupply_ = totalSupply();
        genesisImage_ = _imageCIDs[0];
    }

    function imageCID(uint256 tokenId) external view checkTokenExists(tokenId) returns (string memory) {
        return _imageCIDs[tokenId];
    }

    // @dev NFT implementation version for front-end compatibility during upgrade
    function version() external pure virtual returns (uint16) {
        return 1;
    }
}