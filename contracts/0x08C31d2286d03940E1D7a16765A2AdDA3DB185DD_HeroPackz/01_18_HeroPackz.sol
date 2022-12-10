// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract HeroPackz is ERC721A, Ownable, PaymentSplitter, ReentrancyGuard {
/*
██╗  ██╗███████╗██████╗  ██████╗ ██████╗  █████╗  ██████╗██╗  ██╗███████╗
██║  ██║██╔════╝██╔══██╗██╔═══██╗██╔══██╗██╔══██╗██╔════╝██║ ██╔╝╚══███╔╝
███████║█████╗  ██████╔╝██║   ██║██████╔╝███████║██║     █████╔╝   ███╔╝ 
██╔══██║██╔══╝  ██╔══██╗██║   ██║██╔═══╝ ██╔══██║██║     ██╔═██╗  ███╔╝  
██║  ██║███████╗██║  ██║╚██████╔╝██║     ██║  ██║╚██████╗██║  ██╗███████╗
╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝
*/

  using Strings for uint256;

  bytes32 public merkleRoot;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  
  uint256 public cost; 
  uint256 public WLcost; 
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public whitelistMintEnabled = false;        //disabled whitelist being seperate
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri,
    address[] memory payeeAddrs, 
    uint256[] memory payeeShares_
  ) ERC721A(_tokenName, _tokenSymbol)  PaymentSplitter(payeeAddrs,payeeShares_){
    cost = _cost;
    maxSupply = _maxSupply;
    maxMintAmountPerTx = _maxMintAmountPerTx;
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!"); 
    require(_currentIndex  + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }
  modifier mintComplianceWL(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!"); 
    require(_currentIndex  + _mintAmount <= 500, "Presale max supply exceeded!");
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    _;
  }
  modifier mintWhitelistPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= WLcost * _mintAmount, "Insufficient funds!");
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintComplianceWL(_mintAmount) mintWhitelistPriceCompliance(_mintAmount) {
    require(whitelistMintEnabled, "The whitelist sale is not enabled!");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");
    _safeMint(msg.sender, _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");
    _safeMint(msg.sender, _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    _safeMint(_receiver, _mintAmount);
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
  function setWhitelistCost(uint256 _WLcost) public onlyOwner {
    WLcost = _WLcost;
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

  //whitelist for discount
  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {        //disabled
    whitelistMintEnabled = _state;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}