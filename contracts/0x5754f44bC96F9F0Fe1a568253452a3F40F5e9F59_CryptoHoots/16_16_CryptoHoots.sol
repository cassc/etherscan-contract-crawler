//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

/**
  CryptoHoots: Steampunk Parliament
  2021.09.28
 */
contract CryptoHoots is ERC721URIStorage, Ownable, VRFConsumerBase {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  bool private saleStarted = false;
  uint256 public constant MAX_HOOT = 2500;
  uint256 public price = 0.03 ether;
  string public baseURI;
  string public baseContractURI;
  address public payoutAccountAddress;
  uint256 public randomNumber = 112251241738492409971660691241763937113569996400635104450295902338183133602780; // default random
  mapping(uint256 => uint256) public tokenIdToDNA;

  event Hatched(uint256 indexed tokenId, uint256 dna, address indexed owner);
  event RequestedRandomNumber(bytes32 indexed requestId);
  event FulfilledRandomNumber(bytes32 indexed requestId, uint256 randomNumber);

  constructor(string memory _baseURI_, string memory _contractURI_, address _accountAddress_, address _VRFCoordinator_, address _LinkToken_)
  VRFConsumerBase(_VRFCoordinator_, _LinkToken_)
  ERC721("CryptoHoots Steampunk Parliament", "HOOTS") {
    setBaseURI(_baseURI_);
    payoutAccountAddress = _accountAddress_;
    baseContractURI = _contractURI_;
  }

  function contractURI() public view returns (string memory) {
    return baseContractURI;
  }

  function hatch(uint256 quantity) public payable {
    require(saleStarted, "Sale has not started yet.");
    require(quantity > 0, "Quantity cannot be zero");
    require(quantity <= 10, "Exceeds 10, the max qty per mint.");
    require(totalSupply() + quantity <= MAX_HOOT, "Quantity requested exceeds max supply.");
    require(msg.value >= price * quantity, "Ether value sent is below the price");

    (bool success, ) = payoutAccountAddress.call{value: msg.value}("");
    require(success, "Address: unable to send value, recipient may have reverted");

    for (uint256 i = 0; i < quantity; i++) {
      // initialize tokenId
      uint256 mintIndex = _tokenIds.current();
      
      // mint
      _safeMint(msg.sender, mintIndex);

      // init dna for hoot
      tokenIdToDNA[mintIndex] = uint256(keccak256(abi.encode(randomNumber, mintIndex + block.number)));

      // increment id counter
      _tokenIds.increment();
      emit Hatched(mintIndex, tokenIdToDNA[mintIndex], msg.sender);
    }
  }

  function getDNAForHoot(uint256 hootId) public view returns (uint256) {
    return tokenIdToDNA[hootId];
  }

  function setBaseURI(string memory uri) public onlyOwner {
    baseURI = uri;
  }

  function setSaleStarted(bool started) public onlyOwner {
    saleStarted = started;
  }

  function hasSaleStarted() public view returns (bool) {
    return saleStarted;
  }

  function setContractURI(string memory uri) public onlyOwner {
    baseContractURI = uri;
  }

  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  function hasSoldOut() public view returns (bool) {
    if (totalSupply() >= MAX_HOOT) {
      return true;
    } else {
      return false;
    }
  }

  function requestRandomNumber(bytes32 keyhash, uint256 fee) public returns (bytes32) {
    bytes32 requestId = requestRandomness(keyhash, fee);
    emit RequestedRandomNumber(requestId);
    return requestId;
  }

  function fulfillRandomness(bytes32 requestId, uint256 _randomNumber) internal override {
    randomNumber = _randomNumber;
    emit FulfilledRandomNumber(requestId, _randomNumber);
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function totalSupply() public view returns (uint256) {
    return _tokenIds.current();
  }
}