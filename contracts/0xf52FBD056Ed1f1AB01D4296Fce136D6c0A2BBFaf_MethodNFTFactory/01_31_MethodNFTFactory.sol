// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IFactory} from "../factory/IFactory.sol";
import {IInstanceRegistry} from "../factory/InstanceRegistry.sol";
import {ProxyFactory} from "../factory/ProxyFactory.sol";

import {IUniversalVault} from "./MethodVault.sol";

/// @title MethodNFTFactory
contract MethodNFTFactory is Ownable, IFactory, IInstanceRegistry, ERC721 {
    using SafeMath for uint256;

    bytes32[] public names;
    mapping(bytes32=>address) public templates;
    bytes32 public activeTemplate;

    uint256 public tokenSerialNumber;
    mapping(uint256=>uint256) public serialNumberToTokenId;
    mapping(uint256=>uint256) public tokenIdToSerialNumber;

    mapping(address=>address[]) private ownerToVaultsMap;
    
    event TemplateAdded(bytes32 indexed name, address indexed template);
    event TemplateActive(bytes32 indexed name, address indexed template);

    constructor() ERC721("MethodNFT", "MTHDNFT") {
        ERC721._setBaseURI("https://api.methodfi.co/nft/");
    }

    function addTemplate(bytes32 name, address template) public onlyOwner {
        require(templates[name] == address(0), "Template already exists");
        templates[name] = template;
        if(names.length == 0) {
          activeTemplate = name; 
          emit TemplateActive(name, template);
        }
        names.push(name);
        emit TemplateAdded(name, template);
    }

    function setActive(bytes32 name) public onlyOwner {
      require(templates[name] != address(0), "Template does not exist");
      activeTemplate = name;
      emit TemplateActive(name, templates[name]);
    }

    /* registry functions */

    function isInstance(address instance) external view override returns (bool validity) {
        return ERC721._exists(uint256(instance));
    }

    function instanceCount() external view override returns (uint256 count) {
        return ERC721.totalSupply();
    }

    function instanceAt(uint256 index) external view override returns (address instance) {
        return address(ERC721.tokenByIndex(index));
    }

    /* factory functions */

    function create(bytes calldata) external override returns (address vault) {
        return createSelected(activeTemplate);
    }

    function create2(bytes calldata, bytes32 salt) external override returns (address vault) {
        return createSelected2(activeTemplate, salt);
    }

    function create() public returns (address vault) {
        return createSelected(activeTemplate);
    }

    function create2(bytes32 salt) public returns (address vault) {
        return createSelected2(activeTemplate, salt);
    }

    function createSelected(bytes32 name) public returns (address vault) {
        // create clone and initialize
        vault = ProxyFactory._create(
            templates[name],
            abi.encodeWithSelector(IUniversalVault.initialize.selector)
        );

        // mint nft to caller
        uint256 tokenId = uint256(vault);
        ERC721._safeMint(msg.sender, tokenId);
        // push vault to owner's map
        ownerToVaultsMap[msg.sender].push(vault);
        // update serial number
        tokenSerialNumber = tokenSerialNumber.add(1);
        serialNumberToTokenId[tokenSerialNumber] = tokenId;
        tokenIdToSerialNumber[tokenId] = tokenSerialNumber;

        // emit event
        emit InstanceAdded(vault);

        // explicit return
        return vault;
    }

    function createSelected2(bytes32 name, bytes32 salt) public returns (address vault) {
        // create clone and initialize
        vault = ProxyFactory._create2(
            templates[name],
            abi.encodeWithSelector(IUniversalVault.initialize.selector),
            salt
        );

        // mint nft to caller
        uint256 tokenId = uint256(vault);
        ERC721._safeMint(msg.sender, tokenId);
        // push vault to owner's map
        ownerToVaultsMap[msg.sender].push(vault);
        // update serial number
        tokenSerialNumber = tokenSerialNumber.add(1);
        serialNumberToTokenId[tokenSerialNumber] = tokenId;
        tokenIdToSerialNumber[tokenId] = tokenSerialNumber;

        // emit event
        emit InstanceAdded(vault);

        // explicit return
        return vault;
    }

    /* getter functions */

    function nameCount() public view returns(uint256) {
        return names.length;
    }

    function vaultCount(address owner) public view returns(uint256) {
        return ownerToVaultsMap[owner].length;
    }

    function getVault(address owner, uint256 index) public view returns (address) {
        return ownerToVaultsMap[owner][index];
    }

    function getAllVaults(address owner) public view returns (address [] memory) {
        return ownerToVaultsMap[owner];
    }

    function getTemplate() external view returns (address) {
        return templates[activeTemplate];
    }

    function getVaultOfNFT(uint256 nftId) public pure returns (address) {
        return address(nftId);
    }

    function getNFTOfVault(address vault) public pure returns (uint256) {
        return uint256(vault);
    }

}