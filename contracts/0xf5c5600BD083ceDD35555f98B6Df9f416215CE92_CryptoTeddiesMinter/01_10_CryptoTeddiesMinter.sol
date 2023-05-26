// SPDX-License-Identifier: AGPL-3.0-only
// @author creco.xyz 🐊 2022 

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

interface OSS {
  function balanceOf(address _user, uint256 _tokenId) external view returns (uint256);
  function ownerOf(address _tokenId) external returns(bool);
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount,
    bytes calldata _data
  ) external;
}

interface Shelf {
  function unlock(uint256 _tokenId, address _user) external;
}

interface CryptoTeddiesERC721 {
  function mintTokenId(address _to, uint256 _tokenId) external returns(uint256);
  function setDNA(uint256[] memory _tokenIds, uint256[] memory _dnaArr) external;
  function mintWithDNA(address _to, uint256 _dna) external returns(uint256);
  function transferFrom(address _from, address _to,uint256 _tokenId) external;
  function burn(uint256 _tokenId) external;
  function ownerOf(uint _tokenId) external returns (address);
  function getDNA(uint256 _tokenId) external returns(uint256);
  function LAST_MIGRATION_INDEX() external returns(uint256);
}

interface CryptoTeddiesERC1155 { 
  function setDNA(uint256[] memory _tokenIds, uint256[] memory _dnaArr) external;
  function mintWithDNA(address _to, uint _amount, uint256 _dna) external returns(uint256);
  function mintTo(address _to, uint256 _quantity, uint256 _tokenId) external returns(uint256);
  function balanceOf(address, uint256) external view returns (uint256);
  function LAST_MIGRATION_INDEX() external returns(uint256);
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount,
    bytes calldata _data
  ) external;
  function burn(address _from, uint256 _tokenId, uint256 _amount) external;
}

interface IMetadata {
  struct AttributeInfo {
    uint256 trait_type_index;
    string trait_type;
    uint256 trait_value_index;
    string trait_value;
  }
  function traitValues(uint256 trait_type_index, uint256 trait_value_index) external view returns (string memory);
  function setNames(uint[] memory dna, string[] memory _names) external;
  function setDescriptions(uint[] memory dna, string[] memory _descriptions) external;
  function writeTraitTypes(string[] memory trait_types) external;
  function extendMetadata(AttributeInfo[] calldata traits) external;
}

// FIXME minter can not be paused
contract CryptoTeddiesMinter is AccessControlEnumerable {

  OSS storeFront = OSS(0x495f947276749Ce646f68AC8c248420045cb7b5e);
  Shelf shelf;
  CryptoTeddiesERC721 teddies;
  CryptoTeddiesERC1155 teddiesEditions;
  IMetadata metadata;


  // strofront id -> ERC721 tokenID (tokenID can be 0)
  mapping(uint256 => uint256) public wrapmap721;
  // token id -> storeFrontid
  mapping(uint256 => uint256) public unwrapmap721;
  // strofront id -> ERC1155 tokenID (tokenID can not be 0)
  mapping(uint256 => uint256) public wrapmap1155;
  // token id -> storeFrontid
  mapping(uint256 => uint256) public unwrapmap1155;

  modifier onlyAdmin {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "CryptoTeddies Minter: must have Admin role");
    _;
  } 

  constructor(address _shelf, address _teddies, address _teddiesEditions, address _metadata) { 
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender()); // set admin permissions
    shelf = Shelf(_shelf);
    teddies = CryptoTeddiesERC721(_teddies); // ERC721 Cryptoteddies contract
    teddiesEditions = CryptoTeddiesERC1155(_teddiesEditions); // ERC1155 Cryptoteddies contract
    metadata = IMetadata(_metadata);
  }

  function setMetadataContract(address _contractAddress) onlyAdmin public {
    metadata = IMetadata(_contractAddress);
  }

  /** @dev init ERC721 DNA for wrapping
   */
  function initERC721DNA(uint256[] calldata _storeFrontIds, uint256[] calldata _tokenIds, uint256[] calldata _dna) onlyAdmin external {
    require(_tokenIds.length == _storeFrontIds.length, "CryptoTeddies Minter - data missing");
    require(_tokenIds.length == _dna.length, "CryptoTeddies Minter - data missing");
    uint items = _storeFrontIds.length;
    for (uint i = 0; i < items; i++) {
      uint storeFrontId = _storeFrontIds[i];
      uint tokenId = _tokenIds[i];
      wrapmap721[storeFrontId] = tokenId;
      unwrapmap721[tokenId] = storeFrontId;
    }
    teddies.setDNA(_tokenIds, _dna);
  }
   
  /** @dev init ERC1155 DNA for wrapping
   */
  function initERC1155DNA(uint256[] calldata _storeFrontIds, uint256[] calldata _tokenIds, uint256[] calldata _dna) onlyAdmin external { 
    require(_tokenIds.length == _storeFrontIds.length, "CryptoTeddies Minter - data missing");
    require(_tokenIds.length == _dna.length, "CryptoTeddies Minter - data missing"); 
    uint items = _storeFrontIds.length;
    for (uint i = 0; i < items; i++) {
      uint storeFrontId = _storeFrontIds[i];
      uint tokenId = _tokenIds[i];
      wrapmap1155[storeFrontId] = tokenId;
      unwrapmap1155[tokenId] = storeFrontId;
    }
    teddiesEditions.setDNA(_tokenIds, _dna);
  }

  /** @dev wrap OpenSea teddy to standalone contract
   */
  function wrap(uint _storeFrontId) public {
     uint tokenId = wrapmap1155[_storeFrontId];
     if(tokenId == 0) {
      wrapERC721(_storeFrontId);
     } else {
      wrapERC1155(_storeFrontId);
     }
  }

  /** @dev unwrap teddy from standalone contract to OpenSea
   */
  function unwrap(uint _tokenId) public {
     uint storeFrontId = unwrapmap1155[_tokenId];
     if(storeFrontId == 0) {
      unwrapERC721(_tokenId);
     } else {
      unwrapERC1155(_tokenId);
     }
  }

  /** @dev wrap ERC1155 teddy
   */
  function wrapERC1155(uint _storeFrontId) internal {
    // make sure user owner of NFT
    require((storeFront.balanceOf(msg.sender, _storeFrontId) >= 1), "CryptoTeddies Minter: user not token owner");
    uint tokenId = wrapmap1155[_storeFrontId];
    require((tokenId != 0), "CryptoTeddies Minter: token not CryptoTeddies edition");
    // lock storeFront teddy in shelf 
    storeFront.safeTransferFrom(msg.sender, address(shelf), _storeFrontId, 1, "");
    teddiesEditions.mintTo(msg.sender, 1, tokenId);
  }

   /** @dev unwrap ERC1155 teddy
   */
  function unwrapERC1155(uint _tokenId) internal {
    require((teddiesEditions.balanceOf(msg.sender, _tokenId) >= 1), "CryptoTeddies Minter: user not token owner");
    require(_tokenId <= teddiesEditions.LAST_MIGRATION_INDEX()); // can not unwrap unmigrated tokens
    uint storeFrontId = unwrapmap1155[_tokenId];
    require((storeFront.balanceOf(address(shelf), storeFrontId) >= 1), "CryptoTeddies Minter: token not part of CryptoTeddies Collection");
    // transfer ERC1155 teddy from user and burn -> user has to approve
    teddiesEditions.burn(msg.sender, _tokenId, 1);
    // unlock storefront teddy from shelf and send back to user
    shelf.unlock(storeFrontId, msg.sender);
  }

   /** @dev wrap ERC721 teddy
   */
  function wrapERC721(uint _storeFrontId) internal {
    // make sure user owner of NFT
    require((storeFront.balanceOf(msg.sender, _storeFrontId) >= 1), "CryptoTeddies Minter: user not token owner");
    uint tokenId = wrapmap721[_storeFrontId];
    uint reverseId = unwrapmap721[tokenId];
    // check for edge case tokenId 0, since 0 is the default uint value. Make sure that the tokenId 0 matches to exact the same storefront token. 
    require((_storeFrontId == reverseId), "CryptoTeddies Minter: token not from CryptoTeddies collection");
    storeFront.safeTransferFrom(msg.sender, address(shelf), _storeFrontId, 1, "");
    teddies.mintTokenId(msg.sender, tokenId);
  }
   
   /** @dev unwrap ERC721 teddy
   */
  function unwrapERC721(uint _tokenId) internal {
    // make sure user owner of NFT
    require(teddies.ownerOf(_tokenId) == msg.sender, "CryptoTeddies Minter: user not token owner");
    require(_tokenId <= teddies.LAST_MIGRATION_INDEX()); // can not unwrap unmigrated tokens
    uint storeFrontId = unwrapmap721[_tokenId];
    require((storeFront.balanceOf(address(shelf), storeFrontId) >= 1), "CryptoTeddies Minter: token not part of CryptoTeddies Collection");
    // transfer ERC721 teddy from user and burn -> user has to approve
    teddies.transferFrom(msg.sender, address(this), _tokenId);
    teddies.burn(_tokenId);
    // unlock storefront teddy from shelf and send back to user
    shelf.unlock(storeFrontId, msg.sender);
  }


  function _compareStrings(string memory a, string memory b) internal pure returns (bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
  }

  function traitToIndex(uint trait_type_idx, string calldata trait_value) public view returns (uint) {
    uint idx = 0;
    while(true) {
      if(_compareStrings(trait_value, metadata.traitValues(trait_type_idx, idx))) {
        return idx;
      }
      // end reached
      if(_compareStrings("", metadata.traitValues(trait_type_idx, idx))) {
        return idx + 1; // return insert pos
      }
      idx++;
    }
  }

  function extendTraits(string[] calldata trait_values) public view returns(uint[] memory) {
    uint trait_count = trait_values.length;
    uint[] memory indices = new uint[](trait_count);
    for (uint index = 0; index < trait_count; index++) {
      indices[index] = traitToIndex(index, trait_values[index]);
    }
    return indices;
  }

  /** @dev mint new ERC721 teddy
   */
  function mintERC721(address _to, uint _dna, string calldata name, string calldata description, IMetadata.AttributeInfo[] calldata traits) onlyAdmin public {
    
    teddies.mintWithDNA(_to, _dna);

    uint[] memory dna = new uint[](1);
    dna[0] = _dna;
    string[] memory names = new string[](1);
    names[0] = name;
    metadata.setNames(dna, names);
    string[] memory descriptions = new string[](1);
    descriptions[0] = description;
    metadata.setDescriptions(dna, descriptions);

    metadata.extendMetadata(traits);
  }
  
  /** @dev mint new ERC1155 teddy edition
   */ 
  function mintERC1155(address _to, uint _amount, uint _dna, string calldata name, string calldata description, IMetadata.AttributeInfo[] calldata traits) onlyAdmin public {
    
    teddiesEditions.mintWithDNA(_to, _amount, _dna);

    uint[] memory dna = new uint[](1);
    dna[0] = _dna;
    string[] memory names = new string[](1);
    names[0] = name;
    metadata.setNames(dna, names);
    string[] memory descriptions = new string[](1);
    descriptions[0] = description;
    metadata.setDescriptions(dna, descriptions);

    metadata.extendMetadata(traits);
  }

}