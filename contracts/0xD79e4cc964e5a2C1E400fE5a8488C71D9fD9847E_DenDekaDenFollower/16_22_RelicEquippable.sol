pragma solidity ^0.8.0;

// SPDX-License-Identifier: GPL-3.0



import "./IRelicEquippable.sol";
import "./IERC721TokenOwner.sol";
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/access/Ownable.sol';


abstract contract RelicEquippable is IRelicEquippable, Ownable {
  
  using EnumerableSet for EnumerableSet.Bytes32Set;

  mapping(uint256 /* tokenId */ => EnumerableSet.Bytes32Set) relicsForTokens;

  mapping(bytes32 /* relicMappingId */ => address /* relicContract */) relicMappingIdToAddresses;
  
  mapping(bytes32 /* relicMappingId */ => uint256 /* relicId */) relicMappingIdToTokenIds;

  mapping(bytes32 /* relicMappingId */ => uint256 /* tokenId */) relicMappingToCurrentTokenId;


  // implements equipRelic
  function _equipRelic(uint256 tokenId, address relicAddress, uint256 relicTokenId) internal {
    _equipRelicCommon(msg.sender, tokenId, relicAddress, relicTokenId);
  }

  /**
   * @dev Allows owner to equip a relic to a target address
   * 
   * Used in case of airdropping relics to token owners
   */
  function equipRelicsToAddress(address[] memory targetOwners, uint256[] memory tokenIds, address[] memory relicAddresses, uint256[] memory relicTokenId) public onlyOwner {
    for(uint i = 0; i < targetOwners.length; i++) {
      _equipRelicCommon(targetOwners[i], tokenIds[i], relicAddresses[i], relicTokenId[i]);
    }
  }

  /**
   * @dev Equips a relic to a token
   * 
   * MUST own relic AND token (relic checked when removing prev relic assignment)
   */
  function _equipRelicCommon(address targetOwner, uint256 tokenId, address relicAddress, uint256 relicTokenId) internal {
    
    // ensure user owns tokenId on THIS contract
    if(!(this.ownerOf(tokenId) == targetOwner)) revert NotTokenOwner();

    // remove relic data if equipt previously
    // ensures current owner owns relic
    _removeRelic(targetOwner, relicAddress, relicTokenId);


    // set relic data
    bytes32 relicMappingId = getRelicMappingId(relicAddress, relicTokenId);

    EnumerableSet.Bytes32Set storage relicsForToken = relicsForTokens[tokenId];

    relicsForToken.add(relicMappingId);

    relicMappingIdToAddresses[relicMappingId] = relicAddress;
    relicMappingIdToTokenIds[relicMappingId] = relicTokenId; 
    relicMappingToCurrentTokenId[relicMappingId] = tokenId;
  }
  

  /**
   * @dev Batch equips relics to a token
   */
  function _equipRelics(uint256 tokenId, address[] memory relicAddresses, uint256[] memory relicTokenIds) internal {
    for(uint i = 0; i < relicAddresses.length; i++) {
      _equipRelicCommon(msg.sender, tokenId, relicAddresses[i], relicTokenIds[i]);
    }
  }


  /**
   * @dev Removes relic from a token
   * 
   * MUST own relic (no token ownership checked)
   */
  function removeRelic(address relicAddress, uint256 relicTokenId) public {
    _removeRelic(msg.sender, relicAddress, relicTokenId);
  }


  /**
   * @dev Removes relic from a token
   * 
   * MUST own relic (no token ownership checked)
   */
  function _removeRelic(address targetOwner, address relicAddress, uint256 relicTokenId) internal {

    // ensure user owns RRELIC
    if(!(IERC721TokenOwner(relicAddress).ownerOf(relicTokenId) == targetOwner)) revert NotTokenOwner();

    bytes32 relicMappingId = getRelicMappingId(relicAddress, relicTokenId);
    uint256 prevTokenId = relicMappingToCurrentTokenId[relicMappingId];
    EnumerableSet.Bytes32Set storage relics = relicsForTokens[prevTokenId];

    if(relics.contains(relicMappingId)) {
      relics.remove(relicMappingId);
    }
  }

  /**
   * @dev Get associated relics for a token
   * 
   * Returns array of relicAddresses, relicTokenIds
   */
  function getRelics(uint256 tokenId) public view returns (address[] memory, uint256[] memory) {

    EnumerableSet.Bytes32Set storage relics = relicsForTokens[tokenId];
    uint256 numRelics = relics.length();

    address[] memory ownedRelicAddresses = new address[](numRelics);
    uint256[] memory ownedRelicTokens = new uint[](numRelics);
    
    address tokenOwner = this.ownerOf(tokenId);

    uint256 ownedIdx = 0;

    for(uint i = 0; i < numRelics; i++) {
      bytes32 relicMappingId = relics.at(i);
      address addr = relicMappingIdToAddresses[relicMappingId];
      uint256 relicId = relicMappingIdToTokenIds[relicMappingId];

      // confirm ownership
      if(IERC721TokenOwner(addr).ownerOf(relicId) == tokenOwner) {
        // store valid address and token and increment idx
        ownedRelicAddresses[ownedIdx] = addr;
        ownedRelicTokens[ownedIdx++] = relicId;
      }
    }

    // trim array sizes if necessary
    // happens in case user no longer owns some of their relics
    if(ownedIdx != numRelics) {
      // might be able to do this in memory because modifies storage in view function
      // assembly {
      //   sstore(ownedRelicAddresses, ownedIdx)
      // }
      
      // naiive approach is to recopy data into new arrays
      address[] memory trimmedOwnedRelicAddresses = new address[](ownedIdx);
      uint256[] memory trimmedOwnedRelicTokens = new uint[](ownedIdx);
      for(uint i = 0; i < ownedIdx; i++) {
        trimmedOwnedRelicAddresses[i] = ownedRelicAddresses[i];
        trimmedOwnedRelicTokens[i] = ownedRelicTokens[i];
      }
      ownedRelicAddresses = trimmedOwnedRelicAddresses;
      ownedRelicTokens = trimmedOwnedRelicTokens;
    }

    return (ownedRelicAddresses, ownedRelicTokens);

  }

  /**
   * @dev Utility function to get a relic mapping id for internal mapping purposes
   */
  function getRelicMappingId(address relicAddress, uint256 relicId) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(relicAddress, relicId));
  }
  




}