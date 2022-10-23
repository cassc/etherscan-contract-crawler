// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CancerWarriors is ERC721A, Ownable, ReentrancyGuard {
  /*
 ██████╗ █████╗ ███╗   ██╗ ██████╗███████╗██████╗     ██╗    ██╗ █████╗ ██████╗ ██████╗ ██╗ ██████╗ ██████╗ ███████╗
██╔════╝██╔══██╗████╗  ██║██╔════╝██╔════╝██╔══██╗    ██║    ██║██╔══██╗██╔══██╗██╔══██╗██║██╔═══██╗██╔══██╗██╔════╝
██║     ███████║██╔██╗ ██║██║     █████╗  ██████╔╝    ██║ █╗ ██║███████║██████╔╝██████╔╝██║██║   ██║██████╔╝███████╗
██║     ██╔══██║██║╚██╗██║██║     ██╔══╝  ██╔══██╗    ██║███╗██║██╔══██║██╔══██╗██╔══██╗██║██║   ██║██╔══██╗╚════██║
╚██████╗██║  ██║██║ ╚████║╚██████╗███████╗██║  ██║    ╚███╔███╔╝██║  ██║██║  ██║██║  ██║██║╚██████╔╝██║  ██║███████║
 ╚═════╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚══════╝╚═╝  ╚═╝     ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝
  */
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  bytes32 public merkleRoot;
  bytes32 public merkleRoot2;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  
  uint256 public cost; 
  uint256 public freeMintLimit; 
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  mapping(address => uint256) public mintCount;
  bool public revealed = false;

  address deadZone = address(0x000000000000000000000000000000000000dEaD); //burn address

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    cost = _cost;
    maxSupply = _maxSupply;
    maxMintAmountPerTx = _maxMintAmountPerTx;
    setHiddenMetadataUri(_hiddenMetadataUri);
    setFreeMintLimit(400);
  }

  modifier mintCompliance(uint256 _mintAmount) { 
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx , "Invalid mint amount!"); //no limit on mint amount for normal mints
    require(_currentIndex  + _mintAmount <= maxSupply, "Max supply exceeded!");
    require(mintCount[msg.sender] < 10);
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    if(getCurrentCost() == 0)
      require(_currentIndex + _mintAmount <= freeMintLimit + 1, "Mints would exceed the free mint limit.");
    require(msg.value >= getCurrentCost() * _mintAmount , "Insufficient funds!");
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");

    _mintLoop(msg.sender, _mintAmount);
    mintCount[msg.sender] += _mintAmount;

  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _mintLoop(_receiver, _mintAmount);
  }
  
  function mintForAddresses(uint256[] memory _mintAmounts , address[] memory _receivers ) public onlyOwner {
    for (uint i=0; i<_receivers.length; i++) {
        _mintLoop(_receivers[i], _mintAmounts[i]);
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 0;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
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

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function getCurrentCost() public view returns (uint256) {
    if(_currentIndex <= freeMintLimit)
      return 0;
    return cost;
  }

  function setFreeMintLimit(uint256 _freeMintLimit) public onlyOwner {
    freeMintLimit = _freeMintLimit;
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

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function burn(uint _nftTokenId) public payable {
      require(balanceOf(msg.sender) >= 1, "You don't own any Cancer Warriors");
      safeTransferFrom(msg.sender, deadZone, _nftTokenId);
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
      _safeMint(_receiver, _mintAmount);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function _startTokenId() internal view virtual override returns (uint256){
    return 101;
  }
}