// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract xmoose is ERC721, Ownable, ReentrancyGuard {
using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;
  mapping(address => uint256) public totalClaimed;

  string public uriPrefix = "ipfs://QmSTfJTzSBYRLT6mBBZBL1vZbyGYBkbwNrEQg1g8JE5Se8/";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;

  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;
  uint256 public maxMintAmount;

  bool public paused = false;
  bool public whitelistMintEnabled = false;
  bool public revealed = true;
  bool public metaMintEnabled = true;

  uint256 public metaCount;
  IERC721 public metaContract;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    uint256 _maxMintAmount,
    string memory _hiddenMetadataUri,
    uint256 _metaCount,
    address _metaContract
  ) ERC721(_tokenName, _tokenSymbol) {
    cost = _cost;
    maxSupply = _maxSupply;
    maxMintAmountPerTx = _maxMintAmountPerTx;
    maxMintAmount = _maxMintAmount;
    setHiddenMetadataUri(_hiddenMetadataUri);
    metaCount = _metaCount;
    metaContract = IERC721(_metaContract);
  }

  modifier mintCompliance(address _receiver, uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(supply.current() + _mintAmount + metaCount <= maxSupply, "Max supply exceeded!");
    require(totalClaimed[_receiver] + _mintAmount <= maxMintAmount, "Maximum Mint Amount reached");
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    _;
  }

  modifier metaMintCompliance(uint256 _metaTokenId) {
    require(msg.sender == metaContract.ownerOf(_metaTokenId), "Invalid token id");
    require(_metaTokenId < metaCount, "Invalid token id");
    require(metaMintEnabled == true, "Minting Disabled");
    _;
  }

  function metaMint(uint256 _metaTokenId) public metaMintCompliance(_metaTokenId) {
    _safeMint(msg.sender, _metaTokenId);
  }

  function setMetaMintEnabled(bool _metaMintEnabled) public onlyOwner{
    metaMintEnabled = _metaMintEnabled;
  }

  function metaMintOwner(uint256[] calldata _metaTokenId) public onlyOwner {
    uint256 i = 0;
    while(i < _metaTokenId.length){
      require(_metaTokenId[i] < metaCount, "Meta supply exceeded");
      _safeMint(msg.sender, _metaTokenId[i]);
      i = i + 1;
    }
  }

  function totalSupply() public view returns (uint256) {
    return supply.current() + metaCount;
  }

    function ownerMint(address _user, uint256 _mintAmount) public onlyOwner {
    _mintLoop(_user, _mintAmount);
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(msg.sender, _mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, "The whitelist sale is not enabled!");

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");

    whitelistClaimed[msg.sender] = true;
    _mintLoop(msg.sender, _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(msg.sender, _mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");
    _mintLoop(msg.sender, _mintAmount);
  }

  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_receiver, _mintAmount) onlyOwner {
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

   function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

function setMaxMintAmount(uint256 _maxMintAmount) public onlyOwner {
    maxMintAmount = _maxMintAmount;
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

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {

    // =============================================================================
    (bool hs, ) = payable(0x7a8633a6d00BC857E684fD6f15687f9a0fc24585).call{value: address(this).balance * 10 / 100}("");
    require(hs);
    // =============================================================================

    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {

    totalClaimed[_receiver] = totalClaimed[_receiver] + _mintAmount;
    for (uint256 i = 0; i < _mintAmount; i++) {
      _safeMint(_receiver, supply.current() + metaCount);
      supply.increment();
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}