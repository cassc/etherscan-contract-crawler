// SPDX-License-Identifier: MIT

//............................................................................
//...######..######..#####...##..##..#####....####...#####...#####...##..##...
//...##......##......##..##..###.##..##..##..##..##..##..##..##..##...####....
//...####....####....#####...##.###..##..##..######..##..##..##..##....##.....
//...##......##......##..##..##..##..##..##..##..##..##..##..##..##....##.....
//...##......######..##..##..##..##..#####...##..##..#####...#####.....##.....
//............................................................................

pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract FernDaddy is ERC721A, Ownable {
  
  using ECDSA for bytes32;

  string public _baseTokenURI;
  string public endingUri = ".json";

  uint256 public allowListprice = 0.0422 ether;
  uint256 public price = 0.07 ether; 
  uint256 public maxSupply = 5000;

  mapping(address => bool) public presaleParticipants;
  mapping(address => bool) public freeMintParticipants;

  address private _sa1;
  address private _sa2;

  enum MintStatus {
    CLOSED,
    GIVEAWAY,
    FREE_MINT,
    ALLOW_LIST,
    PUBLIC
  }

  MintStatus public _mintStatus;

  constructor(string memory baseURI) ERC721A("FernDaddy", "FernDaddy") {
    _baseTokenURI = baseURI;
  }

  modifier onlyHuman() {
    require(tx.origin == msg.sender, "Naughty Naughty");
    _;
  }

  function setSa1(address sa1_) external onlyOwner {
    _sa1 = sa1_;
  }

  function setSa2(address sa2_) external onlyOwner {
    _sa2 = sa2_;
  }

  function setBaseURI(string memory baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function setGiveaway() external onlyOwner {
    _mintStatus = MintStatus.GIVEAWAY;
  }

  function setPublic() external onlyOwner {
    _mintStatus = MintStatus.PUBLIC;
  }

  function setFreeMint() external onlyOwner {
    _mintStatus = MintStatus.FREE_MINT;
  }

  function setAllowList() external onlyOwner {
    _mintStatus = MintStatus.ALLOW_LIST;
  }

  function setClosed() external onlyOwner {
    _mintStatus = MintStatus.CLOSED;
  }

  function setEndingURI(string memory _endingUri) external onlyOwner {
    endingUri = _endingUri;
  }

  function setPrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  ///@notice 1-of-1 giveaway winners and reserved 50 tokens 
  ///for GRMI Studios. Owner will mint 
  ///first 50 and transfer to winners. This will be first phase
  ///of minting proccess
  ///@dev GRMI Stuidos spec for handling giveaways pre mint 
  function giveaway() external payable onlyOwner { 
    require(_mintStatus == MintStatus.GIVEAWAY, 'Giveaway Not Active');
    require(totalSupply() + 50 <= maxSupply, 'Supply Denied');
    _safeMint(msg.sender, 50);
  }

  function freeMint(bytes calldata _signature) external payable onlyHuman {
    require(_mintStatus == MintStatus.FREE_MINT, 'Free Mint Not Active');
    require(!freeMintParticipants[msg.sender], 'User Already Claimed Mint');
    require(totalSupply() + 1 <= maxSupply, 'Supply Denied');
    require(_sa1 == keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", 
                              bytes32(uint256(uint160(msg.sender)))))
                              .recover(_signature),"not allowed");
    _safeMint(msg.sender, 1);
    freeMintParticipants[msg.sender] = true;
  }

  ///@notice GRMI Studios have Tiers for their FernDaddy Utility.
  //         a limit of 250 required to facilitate minting to reach
  //         that tier.
  ///@dev GRMI Stuidos spec for OG mint limit.
  function allowListMint(bytes calldata _signature, uint256 _amount) external payable onlyHuman {
    require(_mintStatus == MintStatus.ALLOW_LIST, 'Allow List Mint Not Active');
    require(_amount <= 250, 'Max of 250 Mints Allowed');
    require(totalSupply() + _amount <= maxSupply, 'Supply Denied');
    require(!presaleParticipants[msg.sender], 'Already Claimed Mint');
    require(_sa2 == keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", 
                              bytes32(uint256(uint160(msg.sender)))))
                              .recover(_signature),"not allowed");
    require(msg.value >= allowListprice * _amount, 'Ether Amount Denied');
    _safeMint(msg.sender, _amount);
    presaleParticipants[msg.sender] = true;
  }

  function mint(uint256 _amount) external payable onlyHuman {
    require(_mintStatus == MintStatus.PUBLIC, 'Public Mint Not Active');
    require(_amount <= 10, 'Max of 10 Mints Allowed');
    require(totalSupply() + _amount <= maxSupply, 'Supply Denied');
    require(msg.value >= price * _amount, 'Ether Amount Denied');
    _safeMint(msg.sender, _amount);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    return string(abi.encodePacked(super.tokenURI(tokenId), endingUri));
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function withdraw() external payable onlyOwner {
    payable(0x383f7adEcD735684563AF9C2a8e2F5C79808FC83).transfer(address(this).balance);
  }
}