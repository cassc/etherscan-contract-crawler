// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol';

contract YRewards is OwnableUpgradeable {
   struct Collection {
      address scAddress;
      uint256 reward;
      string collType;
   }

   struct User {
      uint256 reward;
      uint256 burnedNFTs;
   }

   mapping(string => Collection) public collectionData;
   mapping(address => User) public userData;

   address public deadAddress;
   address public operator;
   uint256 public totalPoints;

   modifier onlyOperator() {
      require(msg.sender == operator, "You're not operator!");
      _;
   }

   function initialize() external initializer {
      __Ownable_init();

      deadAddress = 0x000000000000000000000000000000000000dEaD;
   }

   /**
    * Main Functions
    */

   function burn721(string memory _collection, uint256[] memory _ids) external {
      require(_ids.length <= 20, "YREWARDS :: Too many, please reduce to max 20");

      IERC721Upgradeable collection = IERC721Upgradeable(collectionData[_collection].scAddress);

      uint256 idLength = _ids.length;

      for(uint256 index = 0; index < idLength; index++){
         collection.safeTransferFrom(msg.sender, deadAddress, _ids[index]);
      }

      uint256 totalReward = collectionData[_collection].reward * idLength;
      userData[msg.sender].reward += totalReward;
      totalPoints += totalReward;
   }

   function burn1155(string memory _collection, uint256[] memory _ids, uint256[] memory _qty) external {
      require(_ids.length <= 20, "YREWARDS :: Too many, please reduce to max 20");
      require(_ids.length == _qty.length, "YREWARDS :: Not equal ids and length");

      IERC1155Upgradeable collection = IERC1155Upgradeable(collectionData[_collection].scAddress);

      uint256 qty;

      for(uint256 index = 0; index < _qty.length; index++) {
         qty += _qty[index];
      }

      collection.safeBatchTransferFrom(msg.sender, deadAddress, _ids, _qty, "");

      uint256 totalReward = collectionData[_collection].reward * qty;
      userData[msg.sender].reward += totalReward;
      userData[msg.sender].burnedNFTs += qty;
      totalPoints += totalReward;
   }

   function usePoints(uint256 _amount) external onlyOperator {
      userData[msg.sender].reward -= _amount;
   }

   /**
    * Admin Functions
    */

   function setDeadAddress(address _deadAddress) external onlyOwner{
      deadAddress = _deadAddress;
   }

   function setCollectionAddress(string memory _collection, address _collectionAddress) external onlyOwner{
      collectionData[_collection].scAddress = _collectionAddress;
   }

   function setCollectionReward(string memory _collection, uint256 _reward) external onlyOwner{
      collectionData[_collection].reward = _reward;
   }

   function setCollectionType(string memory _collection, string memory _collType) external onlyOwner {
      collectionData[_collection].collType = _collType;
   }

   function setOperator(address _operator) external onlyOwner{
      operator = _operator;
   }
}