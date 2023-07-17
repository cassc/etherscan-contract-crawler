// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract HungryPanda is Ownable, ERC721Enumerable {

  uint public constant MAX_SUPPLY = 10000;
  uint public MINTED_SUPPLY = 0;
  string public baseTokenURI;
  bool public saleActive;
  bool public sealedTokenURI;
  uint public bambooBasePrice;

  constructor(string memory _baseTokenURI) ERC721("HungryPandas", "PANDAS")  {
    bambooBasePrice = 100000000000000; // 0.0001 ETH
    sealedTokenURI = false;
    saleActive = false;
    setBaseTokenURI(_baseTokenURI);
  }

  function flipActiveSwitch() external onlyOwner {
    saleActive = !saleActive;
  }

  function sealTokenURI() external onlyOwner {
    sealedTokenURI = true;
  }

  function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
    require(!sealedTokenURI, "baseURI is sealed");
    baseTokenURI = _baseTokenURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

    // maps panda tokenId to the bamboo owned
  mapping (uint => uint) public pandaBambooCount;

  function price(uint _pandaAmount, uint _bambooPerPanda) public view returns (uint) {
    // 0.03 ETH per panda + bamboo costs
    uint _price = (30000000000000000 + (_bambooPerPanda * bambooBasePrice))  * _pandaAmount;
    return _price;
  }

  function mintPandas(address _to, uint _amount, uint _bambooPerPanda) public payable {
    if (msg.sender != owner()) {
        require(saleActive, "Sale not active");
    }
    require(msg.value >= price(_amount, _bambooPerPanda), "Not enough ETH sent");
    require(MINTED_SUPPLY < MAX_SUPPLY, "Max supply reached");
    require(MINTED_SUPPLY + _amount <= MAX_SUPPLY, "Exceeds max supply");
    require(_amount <= 20, "Max 20 per txn");

    for (uint i = 0; i < _amount; i++) {
      pandaBambooCount[MINTED_SUPPLY] = _bambooPerPanda;
      _safeMint(_to, MINTED_SUPPLY);
      MINTED_SUPPLY++;
    }
  }

  function changeBambooBasePrice(uint _newPrice) external onlyOwner {
    bambooBasePrice = _newPrice;
  }

  function burnForBamboo(uint _burnThisPanda, uint _bambooReceiver) external {
    require(_exists(_burnThisPanda) && _exists(_bambooReceiver), "Panda does not exist");
    require(
      ownerOf(_burnThisPanda) == _msgSender() &&
      ownerOf(_bambooReceiver) == _msgSender(),
      "Must be owner of both pandas"
    );
    _burn(_burnThisPanda);
    pandaBambooCount[_bambooReceiver] += 300 + pandaBambooCount[_burnThisPanda];
    pandaBambooCount[_burnThisPanda] = 0;
  }

  function withdraw() external onlyOwner {
      payable(owner()).transfer(address(this).balance);
  }

  function pandasByOwner(address _owner) external view returns(uint256[] memory) {
      uint tokenBalance = balanceOf(_owner);

      uint256[] memory tokenIds = new uint256[](tokenBalance);
      for(uint i = 0; i < tokenBalance; i++){
          tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
      }

      return tokenIds;
  }


}