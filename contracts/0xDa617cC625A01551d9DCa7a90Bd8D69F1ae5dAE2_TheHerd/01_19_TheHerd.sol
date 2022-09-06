// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC721Royalty.sol";

contract TheHerd is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721Royalty, PausableUpgradeable, OwnableUpgradeable {
  using CountersUpgradeable for CountersUpgradeable.Counter;
  using SafeMath for uint256;

  event NFTMinted(address indexed purchaser, uint256 indexed id);
  CountersUpgradeable.Counter private _tokenIdCounter;

  string private baseURI;
  uint256 private cost;
  uint256 public maxSupply;
  uint256 private maxMintAmount;
  bool private revealed;
  string private notRevealedUri;
  address payable private wallet;

  /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
       _disableInitializers();
    }
    
/// See also https://abhik.hashnode.dev/6-nuances-of-using-upgradeable-smart-contracts


  function initialize(address payable _wallet, uint256 initCost) initializer public {
    __ERC721_init("The Herd", "GOAT");
    __ERC721Enumerable_init();
    __Ownable_init();
    __Pausable_init();
    setBaseURI("");
    setNotRevealedURI("https://wildcard-bay.vercel.app/api/"); 
    setRoyalties(msg.sender, 300);
    cost = initCost;
    maxSupply = 10000; 
    maxMintAmount = 20; 
    revealed = false; 
    wallet = _wallet; 
    _tokenIdCounter.increment();
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
  {
    require(!paused());
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function initMint(address initWallet, uint256 initMintAmount) external onlyOwner {
    for (uint256 i = 1; i <= initMintAmount; i++) {
      safeMint(initWallet);
    }
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused());
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply.add(_mintAmount) <= maxSupply);

    uint256 totalCost = cost.mul(_mintAmount);

    require(msg.value >= cost.mul(_mintAmount));

    for (uint256 i = 1; i <= _mintAmount; i++) {
      safeMint(msg.sender);
    }

    forwardFunds(totalCost);
  }

  function safeMint(address to) private {
      uint256 tokenId = _tokenIdCounter.current();
      _tokenIdCounter.increment();
      _safeMint(to, tokenId);
      emit NFTMinted(msg.sender, tokenId);
  }

  function forwardFunds(uint256 weiAmount) internal {
      wallet.transfer(weiAmount);
  }
  // 

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
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
    
    if (revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, StringsUpgradeable.toString(tokenId), ".json"))
        : "";
  }

  function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
  {
      return super.supportsInterface(interfaceId);
  }

  function setRoyalties(address recipient, uint256 value) public onlyOwner {
      _setRoyalties(recipient, value);
  }

  function getOutstandingSupply() external view returns (uint256) {
      return totalSupply();
  }

  function getWallet() external view returns (address payable) {
      return wallet;
  }

  function getCost() external view returns (uint256) {
    return cost;
  }

  //only owner
  function setRevealed(bool _revealed) public onlyOwner {
    revealed = _revealed;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
    maxMintAmount = _newMaxMintAmount;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function pause() public onlyOwner {
      _pause();
  }

  function unpause() public onlyOwner {
      _unpause();
  }

  function setWallet(address payable _wallet) external onlyOwner {
      wallet = _wallet;
  }

  function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
      maxSupply = _newMaxSupply;
  }
}