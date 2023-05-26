// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./ERC721.sol";
import "./mixin/MixinOwnable.sol";
import "./HashBaseV2.sol";
import "./HashRegistryV2.sol";
import "./ERC1155Mintable.sol";

contract HashV2 is HashBaseV2 {
    uint256 constant internal TYPE_MASK = uint256(uint128(~0)) << 128;
    
    HashRegistryV2 public hashRegistry;
    ERC1155Mintable public immutable originalHash;

    mapping(uint => uint) public tokenTypeToSupply;
    mapping(uint => uint) public tokenTypeToMaxSupply;
    mapping(address => bool) public minters;

    constructor (
      string memory name_,
      string memory symbol_,
      address originalHash_
    ) HashBaseV2(name_, symbol_) {
      originalHash = ERC1155Mintable(originalHash_);
    }

  modifier onlyMinter() {
    require(minters[msg.sender] == true, "msg.sender is not minter");
    _;
  }

  function _getNonFungibleBaseType(uint256 id) pure internal returns (uint256) {
    return id & TYPE_MASK;
  }

  modifier onlyUnderMaxSupply(uint tokenType, uint mintAmount) {
    require(tokenTypeToSupply[tokenType] + mintAmount <= tokenTypeToMaxSupply[tokenType], 'max supply minted');
    _;
  }

  function setHashRegistry(address _hashRegistry) public onlyOwner {
    hashRegistry = HashRegistryV2(_hashRegistry);
  }
  
  function setMinterStatus(address _minter, bool status) public onlyOwner {
    minters[_minter] = status;
  }

  function createNewSeason(uint _tokenType, uint maxSupply) public onlyOwner {
    require(tokenTypeToMaxSupply[_tokenType] == 0, "can't modify already created season");
    tokenTypeToMaxSupply[_tokenType] = maxSupply;
  }

  function mintAndApprove(address to, uint tokenType, uint[] calldata txHashes, address[] calldata operators) public onlyMinter onlyUnderMaxSupply(tokenType, txHashes.length) {
    uint256[] memory tokenIds = new uint256[](txHashes.length);
    for (uint256 i = 0; i < txHashes.length; ++i) {
      uint256 index = tokenTypeToSupply[tokenType] + 1 + i;
      uint256 tokenId  = tokenType | index;
      tokenIds[i] = tokenId;
      _safeMint(to, tokenId);
    }
    hashRegistry.writeToRegistry(tokenIds, txHashes);
    tokenTypeToSupply[tokenType] = tokenTypeToSupply[tokenType] + txHashes.length;
    for (uint i = 0; i < operators.length; ++i) {
      _setApprovalForAll(to, operators[i], true);
    }
  }

  function migrateAndApprove(address to, uint[] calldata ids, address[] calldata operators) public {
    for (uint i = 0; i < ids.length; ++i) {
      // burn original hash erc1155
      originalHash.safeTransferFrom(to, address(0xdead), ids[i], 1, "");
      _safeMint(to, ids[i]);
    }
    for (uint i = 0; i < operators.length; ++i) {
      _setApprovalForAll(to, operators[i], true);
    }
  }
}