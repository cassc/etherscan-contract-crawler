// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "openzeppelin-upgradable/access/OwnableUpgradeable.sol";
import "./ERC721.sol";
import "./DefaultOperatorFiltererUpgradeable.sol";
import {SharedStructs as SSt} from "./sharedStructs.sol";
import "openzeppelin-upgradable/proxy/utils/UUPSUpgradeable.sol";
import "forge-std/console.sol";

interface IRender {
    function tokenURI(uint256 tokenId, SSt.LayerStruct[7] memory layerIds, SSt.CollectionInfo[7] memory _collections) external view returns (string memory); 
    function previewCollage(SSt.LayerStruct[7] memory layerIds) external view returns(string memory);
}

/// @title CCOX - A CCO Crossover Experiment
/// @author OxDala
/// @notice The ERC721 contract allows you to mint custom on-chain NFTs combined from different collections
contract Mash is ERC721, OwnableUpgradeable, DefaultOperatorFiltererUpgradeable, UUPSUpgradeable {
    
    /// @dev EIP-4096 Event, only emited during update not during minting
    event MetadataUpdate(uint256 _tokenId);

    /// @dev Event emmited when a contract is added, used for indexing of traits with the graph
    event ContractAdded(uint256 indexed contractNr, address indexed contractAddress, uint16 maxSupply);
    
    // Errors
    error MaxSupplyReached();
    error AlreadyMintedFromThisCollection();
    error NoMoreLayersToBeMinted();
    error notTokenOwner();
    error payRightAmount();
    error mintNotStarted();
    error changeNotActive();
    error tokenDoesNotExist();

    // Variables / Constants
    IRender public render;
    uint256 public MINT_PRICE;
    uint256 public constant MAX_SUPPLY = 3_333; 
    uint256 private nextCollection;
    uint256 public mintableCollection;
    bool public mintActive;
    bool public changeActive;
    bool public mashActive; 

    // mappings
    mapping(uint256 => SSt.CollectionInfo) private collections; 
    mapping(uint256 => string[]) private layerNames;
    mapping(uint256 => uint256) public addedCollection;

    ////////////////////////  Initializer  /////////////////////////////////

    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("CC0 Mash", "CC0M", 1);
        __Ownable_init();
        __DefaultOperatorFilterer_init();
        __UUPSUpgradeable_init();
        MINT_PRICE = 0.005 ether;
        nextCollection = 1; 
        mintActive = false;
        mintableCollection = 99; 
        changeActive = false;
    }

    ////////////////////////  User Functions  /////////////////////////////////

    function changeLayer(uint256 tokenId, bytes6 layerInfo, uint256 layer, uint256 collection) external {
        if(!changeActive) revert changeNotActive();
        if(msg.sender != _ownerOf[tokenId].owner) revert notTokenOwner();
        if(addedCollection[collection] > 0) revert AlreadyMintedFromThisCollection();
        
        if( layer == 0 ) _ownerOf[tokenId].layer1 = layerInfo;
        if( layer == 1 ) _ownerOf[tokenId].layer2 = layerInfo;
        if( layer > 1 ) _ownerOf[tokenId].layers[layer - 2] = layerInfo;

        addedCollection[collection] = 1;
        emit MetadataUpdate(tokenId);
    }

    //function mash(uint256 tokenId1, uint256 tokenId2, bool burn, bytes4[MAX_LAYERS] tokenLayers1, bytes4[MAX_LAYERS] tokenLayers2) {}

    function mintAndBuy(bytes6[MAX_LAYERS] calldata layerInfo) external payable {
        if(!mintActive) revert mintNotStarted();
        if(totalSupply() + 1 > MAX_SUPPLY) revert MaxSupplyReached();
        if(msg.value < MINT_PRICE) revert payRightAmount();
        _mintAndSet(msg.sender, layerInfo);
    }

    ////////////////////////  Management functions  /////////////////////////////////

    function addCollection(CollectionInfo memory _newCollection, string[] memory _layersNames) public onlyOwner {
        uint256 collectionNr = nextCollection;
        collections[collectionNr] = _newCollection;
        layerNames[collectionNr] = _layersNames;
        emit ContractAdded(collectionNr, _newCollection.collection, _newCollection.maxSupply);
        ++nextCollection;
    }

    function replaceCollection(CollectionInfo memory _newCollection, string[] memory _layersNames, uint256 collectionNr) public onlyOwner {
        collections[collectionNr] = _newCollection;
        layerNames[collectionNr] = _layersNames;
        emit ContractAdded(collectionNr, _newCollection.collection, _newCollection.maxSupply);
    }

    function getCollection(uint256 _collectionNr) public view returns(CollectionInfo memory) {
        return collections[_collectionNr];
    }

    function setMintActive() external onlyOwner {
        mintActive = true;
    }

    function setMintableCollection(uint256 _newValue) external onlyOwner {
        mintableCollection = _newValue;
    }

    function setRender( address _newRender) public onlyOwner {
        render = IRender(_newRender);
    }

    function toggleOperatorFilter() external onlyOwner {
        isOperatorFilterEnabled = !isOperatorFilterEnabled;
    }

    ////////////////////////  TokenURI /////////////////////////////////

    function tokenURI(uint256 tokenId) override public view returns (string memory) { 
        if(tokenId > totalSupply()) revert tokenDoesNotExist();
        LayerStruct[MAX_LAYERS] memory layerIds;
        CollectionInfo[MAX_LAYERS] memory _collections;
        for(uint256 i; i < MAX_LAYERS; ++i) {
            if( i == 0 ) layerIds[i] = decodeLayer(_ownerOf[tokenId].layer1);
            if( i == 1 ) layerIds[i] = decodeLayer(_ownerOf[tokenId].layer2);
            if( i > 1 ) layerIds[i] = decodeLayer(_ownerOf[tokenId].layers[i-2]);
            if(layerIds[i].collection == 0) continue;
            _collections[i] = getCollection(layerIds[i].collection);
        }
        return render.tokenURI(tokenId, layerIds, _collections);
    }

    ////////////////////////  Helper Function  /////////////////////////////////

    function getLayerNames(uint256 collectionNr) external view returns(string[] memory) {
        return layerNames[collectionNr];
    }

    function previewTokenCollage(uint256 tokenId, uint256 layerNr, LayerStruct memory _newLayer) external view returns (string memory) { 
        LayerStruct[MAX_LAYERS] memory _tokenLayers;
        for(uint256 i; i < MAX_LAYERS; ++i) {
            _tokenLayers[i] = decodeLayer(_ownerOf[tokenId].layers[i]);
        }
        _tokenLayers[layerNr] = _newLayer;
        return render.previewCollage(_tokenLayers);
    }

    function previewCollage(bytes6[MAX_LAYERS] calldata layerInfo) external view returns (string memory) { 
        LayerStruct[MAX_LAYERS] memory _tokenLayers;
        for(uint256 i; i < MAX_LAYERS; ++i) {
            _tokenLayers[i] = decodeLayer(layerInfo[i]);
        }
        return render.previewCollage(_tokenLayers);
    }

    function decodeLayer(bytes6 array) public pure returns (LayerStruct memory) {
        uint8 contractId = decodeContract(array);
        uint8 layerId = uint8(array[1]);
        uint8 traitId = uint8(array[2]);
        bool pfpRender = uint8(array[3] >> 7) == 1 ? true : false;
        uint8 background = uint8(array[3] & 0x70) >> 4;
        uint8 scale = uint8(array[3] & 0x0f);
        int8 xOffset = int8(uint8(array[4]));
        int8 yOffset = int8(uint8(array[5]));
        return LayerStruct(contractId, layerId, traitId, pfpRender, background, scale, xOffset, yOffset);
    }

    function decodeContract(bytes6 array) public pure returns (uint8) {
        return uint8(array[0]);
    }

    //////////////////////// Withdraw ////////////////////////

    function withdraw() payable public onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    //////////////////////// Operatorfilter overrides ////////////////////////

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from,
        address to,
        uint256 id) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, id);
    }

    function safeTransferFrom( address from,
        address to,
        uint256 id,
        bytes calldata data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, id, data);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}