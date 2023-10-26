// SPDX-License-Identifier: MIT


//███████╗███████╗██╗░░░░░██╗███╗░░██╗███████╗  ███████╗██████╗░██╗███████╗███╗░░██╗██████╗░░██████╗
//██╔════╝██╔════╝██║░░░░░██║████╗░██║██╔════╝  ██╔════╝██╔══██╗██║██╔════╝████╗░██║██╔══██╗██╔════╝
//█████╗░░█████╗░░██║░░░░░██║██╔██╗██║█████╗░░  █████╗░░██████╔╝██║█████╗░░██╔██╗██║██║░░██║╚█████╗░
//██╔══╝░░██╔══╝░░██║░░░░░██║██║╚████║██╔══╝░░  ██╔══╝░░██╔══██╗██║██╔══╝░░██║╚████║██║░░██║░╚═══██╗
//██║░░░░░███████╗███████╗██║██║░╚███║███████╗  ██║░░░░░██║░░██║██║███████╗██║░╚███║██████╔╝██████╔╝
//╚═╝░░░░░╚══════╝╚══════╝╚═╝╚═╝░░╚══╝╚══════╝  ╚═╝░░░░░╚═╝░░╚═╝╚═╝╚══════╝╚═╝░░╚══╝╚═════╝░╚═════╝░

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FelineFriends is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string public uriPrefix = "ipfs://QmRz3pi2q2JR9AkMMCCLQyBRiby1XsKBmJ2z69CSDL6nYR/";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  
  uint256 public cost = 0.00 ether;
  uint256 public finalMaxSupply = 7777;
  uint256 public currentMaxSupply = 1777;
  uint256 public maxMintAmountPerTx = 15;
  uint256 public maxPerWallet = 45; 

  bool public paused = false;
  bool public revealed = false;

  constructor() ERC721("FelineFriends", "OFF") { 
    setHiddenMetadataUri("ipfs://QmUo1vt839oZM9QX8V2cP4cXodZky2bdiXKuULvHmYQTGu/hidden.json"); 
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= currentMaxSupply, "Max supply exceeded!");
    require(balanceOf(msg.sender) < 45, "Max 45 per wallet"); 
    _;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");

    _mintLoop(msg.sender, _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _mintLoop(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= currentMaxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setCurrentMaxSupply(uint256 _supply) public onlyOwner {
      require(_supply <= finalMaxSupply && _supply >= totalSupply());
      currentMaxSupply = _supply;
  }

  function resetFinalMaxSupply() public onlyOwner {
      finalMaxSupply = currentMaxSupply;
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public onlyOwner {
    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}