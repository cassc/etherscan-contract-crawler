pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract BlockchainBandits is ERC721Enumerable, Ownable {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;

  uint public constant PRICE = 0.088 ether;

  string public baseTokenURI;
  uint public maxSupply;
  mapping(address => bool) whitelist;
  mapping(address => bool) originalMinters;
  bool whitelistOnly;
  bool salePaused;
  address payable recipientAddress;

  constructor(
    string memory baseURI,
    uint _maxSupply,
    address payable newRecipientAddress
  ) ERC721("Blockchain Bandits", "BCB") {
    setBaseURI(baseURI);
    maxSupply = _maxSupply;
    whitelistOnly = true;
    salePaused = true;
    recipientAddress = newRecipientAddress;
  }

  function mintReserveTokens() public onlyOwner {
    uint numNewTokens = 10;

    require(_tokenIds.current() + numNewTokens <= 50, "All reserve tokens have been minted");

    for (uint i = 0; i < numNewTokens; i++) {
      _assignNewTokenToSender();
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function setBaseURI(string memory _baseTokenURI) public onlyOwner {
    baseTokenURI = _baseTokenURI;
  }
  
  function setSalePaused(bool newVal) public onlyOwner {
    salePaused = newVal;
  }

  function addToWhitelist(address addy) public onlyOwner {
    whitelist[addy] = true;
  }

  function isWhitelisted(address addy) public view returns (bool) {
    return whitelist[addy];
  }

  function batchWhitelist(address[] memory _addrs) public onlyOwner {
    for (uint i = 0; i < _addrs.length; i++) {
      if (_addrs[i] != address(0x0)) {
        whitelist[_addrs[i]] = true;
      }
    }
  }

  function setWhitelistOnly(bool newVal) public onlyOwner {
    whitelistOnly = newVal;
  }

  function mint() public payable {
    uint totalMinted = _tokenIds.current();

    require(!salePaused, "Cannot mint when sale is paused");
    require(totalMinted + 1 <= maxSupply, "Maximum number of tokens already minted.");
    require(msg.value >= PRICE, "Not enough ether to purchase.");
    require(!originalMinters[msg.sender], "Only one token per wallet can be minted");
    if (whitelistOnly) {
      require(whitelist[msg.sender], "You are not whitelisted, please wait for public sale to commence");
    }

    _mintSingleNFT();
  }

  function _mintSingleNFT() private {
    _assignNewTokenToSender();
  }

  function _assignNewTokenToSender() private {
    uint newTokenID = _tokenIds.current();
    originalMinters[msg.sender] = true;
    _safeMint(msg.sender, newTokenID);
    _tokenIds.increment();

    if (msg.value > PRICE) {
      (bool success, ) = msg.sender.call{value: msg.value - PRICE}("");
      require(success, "Failed to refund for excess ether");
    }
  }

  function tokensOfOwner(address _owner) external view returns (uint[] memory) {
    uint tokenCount = balanceOf(_owner);
    uint[] memory tokensId = new uint256[](tokenCount);

    for (uint i = 0; i < tokenCount; i++) {
      tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokensId;
  }

  function withdraw() external {
    (bool success, ) = recipientAddress.call{value: address(this).balance}("");

    require(success, "Failed to pay ether to destination address");
  }
}