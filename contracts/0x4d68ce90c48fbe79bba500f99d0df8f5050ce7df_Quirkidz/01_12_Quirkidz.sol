// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";

contract Quirkidz is ERC721A, Ownable {
  using Strings for uint256;

  string public uriPrefix = "ipfs://QmamkWbtNq1Rhv5xstWwVZX3WL7uc8qnT8Ebkj8ntbxtU4/";
  string public uriSuffix = ".json";
  uint256 public cost = 0.019 ether;
  uint256 public maxSupply = 5000;
  uint256 public maxMintAmount = 20;
  uint256 public maxFreeMint = 777;
  uint256 public freeMintCounter = 0;
  bool public isSaleActive = false;
  mapping(address => uint256) public freeMintCounterMap;
  address founder = 0x1Aff7B3E73B8f166768aaDeB7976dD70DEc9D74c;

  constructor(
    string memory _name,
    string memory _symbol
  ) ERC721A(_name, _symbol , maxSupply , maxMintAmount) {
  }

  function mint(uint256 _mintAmount ) public payable {

    require(isSaleActive , "Mint closed");
    require(_mintAmount > 0 && _mintAmount <= maxMintAmount , "Mint amount is not between 1 and 20");
    uint256 index = totalSupply();
    require(index + _mintAmount <= maxSupply ,"Not enough supply");

    require(msg.value >= cost * _mintAmount , "Not enough eth");

    _safeMint(msg.sender, _mintAmount); 

  }

  function freeMint() public {
    require(isSaleActive , "Mint closed");
    uint256 index = totalSupply();
    require(index < maxSupply ,"Not enough supply");
    require(freeMintCounter < maxFreeMint , "Free Mint is finished");
    require(freeMintCounterMap[msg.sender] == 0 , "You already minted your free mint");

    freeMintCounter++;
    freeMintCounterMap[msg.sender] = 1;
    _safeMint(msg.sender, 1);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), uriSuffix))
        : "";
  }

  //only owner
  function setCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner() {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner() {
    uriSuffix = _uriSuffix;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function pause(bool _state) public onlyOwner() {
    isSaleActive = _state;
  }

  function withdraw() public payable onlyOwner() {
      uint256 balanceContract = address(this).balance;
      require(balanceContract > 0, "Sales Balance = 0");

      _withdraw(founder, balanceContract);

  }

  function _withdraw(address _address, uint256 _amount) private {
      (bool success, ) = _address.call{value: _amount}("");
      require(success, "Transfer failed.");
    }
  
}