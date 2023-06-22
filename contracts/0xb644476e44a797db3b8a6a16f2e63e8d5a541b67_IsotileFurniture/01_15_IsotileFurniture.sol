// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./ITiles.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract IsotileFurniture is ERC1155, ERC1155Pausable, Ownable {
  using Counters for Counters.Counter;

  Counters.Counter private _furnitureIds;
  ITiles private tilesInstance;
  
  // Event on create furnitures
  event FurnitureAdded(uint256 indexed id);
  
  // Mapping from address to count of furnitures bought
  mapping (address => uint256) private _furnituresBought;

  struct Furniture {
    string uri;
    uint256 maxSupply;
    bool isPaidWithEther;
    uint256 price;
    uint256 totalSupply;
    uint256 saveFirstBuyerMaxTimestampAllowed;
  }

  // Mapping from furniture ID to furnitures
  mapping (uint256 => Furniture) private _furnitures;
  

  constructor() ERC1155("") {}

  // Get total furnitures added to isotile contract
  function getTotalFurnitures() public view returns (uint256){
    return _furnitureIds.current();
  }

  // Get total furnitures added to isotile contract
  function getCountOfFurnituresBought(address account) public view returns (uint256){
    return _furnituresBought[account];
  }

  // Override get uri for a furniture ID
  function uri(uint256 id) public view override returns (string memory) {
    return _furnitures[id].uri;
  }

  // Get max supply for a furniture ID
  function getMaxSupply(uint256 id) public view returns (uint256){
    return _furnitures[id].maxSupply;
  }

  // Get if a furniture is paid on tiles
  function isPaidWithEther(uint256 id) public view returns (bool){
    return _furnitures[id].isPaidWithEther;
  }

  // Get price in weis of furniture ID
  function getPrice(uint256 id) public view returns (uint256){
    return _furnitures[id].price;
  }

  // Get count of furnitures minted for a furniture ID
  function getTotalSupply(uint256 id) public view returns (uint256){
    return _furnitures[id].totalSupply;
  }

  // Mint one furniture
  function mintFurniture(uint256 id, uint256 amount) public payable {
    require(amount > 0, "amount cannot be 0");

    require(_furnitures[id].totalSupply + amount <= _furnitures[id].maxSupply, "Exceeds MAX_SUPPLY");
    _furnitures[id].totalSupply += amount;

    uint256 paymentRequired = _furnitures[id].price * amount;
    if(_furnitures[id].isPaidWithEther){
      require(msg.value == paymentRequired, "Ether value sent is not correct");
    }else{
      require(msg.value == 0, "Ether not accepted for this furniture");
      require(tilesInstance.balanceOf(msg.sender) >= paymentRequired, "Not enough tiles");

      tilesInstance.spend(msg.sender, paymentRequired);
    }

    if(_furnitures[id].saveFirstBuyerMaxTimestampAllowed > 0 && block.timestamp < _furnitures[id].saveFirstBuyerMaxTimestampAllowed){
      _furnituresBought[msg.sender] += amount;
    }

    _mint(msg.sender, id, amount, "");
  }

  // Mint batch furnitures
  function mintBatchFurnitures(uint256[] memory ids, uint256[] memory amounts) public payable {
    require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

    uint256 totalAmounts = 0;
    uint256 paymentRequiredOnEther = 0;
    uint256 paymentRequiredOnTiles = 0;

    for (uint i = 0; i < ids.length; i++) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];

      require(amount > 0, "amount cannot be 0");

      if(_furnitures[id].saveFirstBuyerMaxTimestampAllowed > 0 && block.timestamp < _furnitures[id].saveFirstBuyerMaxTimestampAllowed){
        totalAmounts += amount;
      }

      require(_furnitures[id].totalSupply + amount <= _furnitures[id].maxSupply, "Exceeds MAX_SUPPLY");
      _furnitures[id].totalSupply += amount;

      if(_furnitures[id].isPaidWithEther){
        paymentRequiredOnEther += _furnitures[id].price * amount;
      }else{
        paymentRequiredOnTiles += _furnitures[id].price * amount;
      }
    }

    require(msg.value == paymentRequiredOnEther, "Ether value sent is not correct");

    if(paymentRequiredOnTiles > 0){
      require(tilesInstance.balanceOf(msg.sender) >= paymentRequiredOnTiles, "Not enough tiles");

      tilesInstance.spend(msg.sender, paymentRequiredOnTiles);
    }

    if(totalAmounts > 0){
      _furnituresBought[msg.sender] += totalAmounts;
    }

    _mintBatch(msg.sender, ids, amounts, "");
  }
  
  function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override(ERC1155, ERC1155Pausable) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  // Create a furniture
  function addFurniture(string memory _furnitureUri, uint256 _maxSupply, bool _isPaidWithEther, uint256 _price, uint256 _saveFirstBuyerMaxTimestampAllowed) onlyOwner public {
    uint256 newFurnitureId = _furnitureIds.current();

    _furnitures[newFurnitureId] = Furniture({
      uri: _furnitureUri,
      maxSupply: _maxSupply,
      isPaidWithEther: _isPaidWithEther,
      price: _price,
      totalSupply: 0,
      saveFirstBuyerMaxTimestampAllowed: _saveFirstBuyerMaxTimestampAllowed
    });
    
    emit FurnitureAdded(newFurnitureId);

    _furnitureIds.increment();
  }

  function setTilesInstance(address tilesAddress) onlyOwner public {
    tilesInstance = ITiles(tilesAddress);
  }
  
  function pause() onlyOwner public {
      _pause();
  }
  
  function unpause() onlyOwner public {
      _unpause();
  }

  function withdraw() onlyOwner public {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

}