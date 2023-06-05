// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721PEnum.sol";

interface IEpicEagles {
  function balanceOf(address owner) external view returns (uint256);
  function ownerOf(uint256 tokenId) external returns (address);
  function walletOfOwner(address _owner) external view returns (uint256[] memory);
}

contract VoidWarriors is ERC721PEnum, Ownable, PaymentSplitter {
  using SafeMath for uint256;
  using Strings for uint256;
  string public baseUrl;
  uint256 public price = 0.03 ether;
  uint256 public limit = 21;
  uint256 public supply = 7676;
  bool public claimOn = false;
  mapping(uint256 => bool) public claimed;
  mapping(address => bool) public allowlist;
  address creator = 0x722FFd38eB050e92f4C3804a8bf823521C726d77;
  address developer = 0x1AF8c7140cD8AfCD6e756bf9c68320905C355658;
  address comManager = 0x1288eb773F9Ab5fD2368C870f02Aaf97A7Bfce9c;
  address community = 0x1A1bb1509a707B1Da31f12D0d12E47B299Af377D;
  address artist = 0xF119d575FE73c92E0aAB01d03cf301F856DbE60B;
  address[] payees = [creator, developer, comManager, community];
  uint256[] split = [57, 27, 7, 9];

  IEpicEagles eaglesContract;

  struct Claim {
    uint256 tokenId;
    bool claimed;
  }

  enum MintStatus {
    CLOSED, ALLOWLIST, PUBLIC
  }

  MintStatus public mintStatus;

  constructor(string memory _baseUrl, address _epicEagles) ERC721P("Void Warriors", "VW") PaymentSplitter(payees, split) {
    baseUrl = _baseUrl;
    eaglesContract = IEpicEagles(_epicEagles);
  }

  function mint(uint256 amount) public payable {
    require(mintStatus == MintStatus.PUBLIC, "Public minting off");
    uint256 voidWarriors = totalSupply();
    require(voidWarriors + amount <= supply, "Exceeds supply");
    require(amount < 21, "Max 20 mints per transaction");
    require(msg.value >= price * amount, "Incorrect eth sent");
    for (uint256 i; i < amount; i++) {
      _safeMint(msg.sender, voidWarriors + i);
    }
    delete voidWarriors;
  }

  function mintAllowlist(uint256 amount) public payable {
    require(mintStatus == MintStatus.ALLOWLIST, "Allowlist minting off");
    require(allowlist[msg.sender] || eaglesContract.balanceOf(msg.sender) > 0, "Not on allowlist");
    uint256 voidWarriors = totalSupply();
    require(voidWarriors + amount <= supply, "Exceeds supply");
    require(amount < 21, "Max 20 mints per transaction");
    require(msg.value >= price * amount, "Incorrect eth sent");
    for (uint256 i; i < amount; i++) {
      _safeMint(msg.sender, voidWarriors + i);
    }
    delete voidWarriors;
  } 

  function claim(uint256[] memory eagleIds) external {
    require(claimOn, "Claiming has not started");
    uint256 voidWarriors = totalSupply();
    require(voidWarriors + eagleIds.length <= supply, "Exceeds supply");
    require(eagleIds.length < 31, "Max 30 claims per transaction");
    for (uint256 i; i < eagleIds.length; i++) {
      uint256 eagleId = eagleIds[i];
      require(eaglesContract.ownerOf(eagleId) == msg.sender, "Not eagle owner");
      require(!claimed[eagleId], "Eagle already claimed");
      _safeMint(msg.sender, voidWarriors + i);
      claimed[eagleId] = true;
      delete eagleId;
    }
    delete voidWarriors;
  }

  function reserve(uint256 amount) external onlyOwner {
    uint256 voidWarriors = totalSupply();
    require(voidWarriors + amount <= supply, "Exceeds supply");
    for (uint256 i; i < amount; i++) {
      _safeMint(msg.sender, voidWarriors + i);
    }
    delete voidWarriors;
  }

  function setMintStatus(uint256 status) external onlyOwner {
    require(status <= uint256(MintStatus.PUBLIC), "Invalid status");
    mintStatus = MintStatus(status);
  }

  function setClaiming(bool _claimOn) external onlyOwner {
    claimOn = _claimOn;
  }

  function setPrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  function setBaseUrl(string memory _baseUrl) external onlyOwner {
    baseUrl = _baseUrl;
  }

  function setEpicEaglesContract(address _epicEagles) external onlyOwner {
    eaglesContract = IEpicEagles(_epicEagles);
  }

  function setAllowlistOwners(address[] calldata owners) external onlyOwner {
    for (uint256 i; i < owners.length; i++) {
      allowlist[owners[i]] = true;
    }
  }

  function withdraw() external payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }

  function withdrawRoyalties() external payable onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0);
    require(payable(artist).send(balance.mul(38).div(100)));
    require(payable(creator).send(balance.mul(62).div(100)));
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
    return bytes(baseUrl).length > 0 ? string(abi.encodePacked(baseUrl, tokenId.toString(), ".json")) : "";
  }

  function eaglesOfOwnerWithClaims(address owner) public view returns (Claim[] memory) {
    uint256[] memory eagleIds = eaglesContract.walletOfOwner(owner);
    Claim[] memory claimArray = new Claim[](eagleIds.length);
    for (uint256 i = 0; i < eagleIds.length; i++) {
      uint256 eagleId = eagleIds[i];
      claimArray[i] = Claim(eagleId, claimed[eagleId]);
    }
    return claimArray;
  }

  function tokenURIsOfOwner(address owner) public view returns (string[] memory) {
    uint256[] memory tokenIds = tokensOfOwner(owner);
    string[] memory tokenURIs = new string[](tokenIds.length);
    for (uint256 i = 0; i < tokenIds.length; i++) {
        tokenURIs[i] = tokenURI(tokenIds[i]);
    }
    return tokenURIs;
  }

  function isOnAllowlist(address owner) public view returns (bool) {
    return allowlist[owner];
  }

}