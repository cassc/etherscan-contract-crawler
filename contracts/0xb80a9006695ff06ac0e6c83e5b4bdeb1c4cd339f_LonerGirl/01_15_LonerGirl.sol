// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract LonerGirl is ERC721A, Ownable, ReentrancyGuard {
  /*
      ▄▄▌         ▐ ▄ ▄▄▄ .▄▄▄       ▄▄ • ▪  ▄▄▄  ▄▄▌  
      ██•  ▪     •█▌▐█▀▄.▀·▀▄ █·    ▐█ ▀ ▪██ ▀▄ █·██•  
      ██▪   ▄█▀▄ ▐█▐▐▌▐▀▀▪▄▐▀▀▄     ▄█ ▀█▄▐█·▐▀▀▄ ██▪  
      ▐█▌▐▌▐█▌.▐▌██▐█▌▐█▄▄▌▐█•█▌    ▐█▄▪▐█▐█▌▐█•█▌▐█▌▐▌
      .▀▀▀  ▀█▄▀▪▀▀ █▪ ▀▀▀ .▀  ▀    ·▀▀▀▀ ▀▀▀.▀  ▀.▀▀▀ 
  */
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  bytes32 public merkleRoot;
  bytes32 public merkleRoot2;
  mapping(address => uint256) public whitelistClaimed; //Whitelist mint limit is 2 per address
  mapping(address => bool) public freeMintClaimed; //Free mint limit is 1 per address on the FreeMintList

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  
  uint256 public cost = 60000000000000000; //0.06 ETH for normal mints
  uint256 public WLcost = 40000000000000000; //0.04 ETH for whitelisted mints
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  //bool public whitelistMintEnabled = false;        //disabled whitelist being seperate
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
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= 9999, "Invalid mint amount!"); //no limit on mint amount for normal mints
    require(_currentIndex  + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }
  modifier mintComplianceWL(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!"); //limit whitelist mints to two per tx
    require(_currentIndex  + _mintAmount <= maxSupply, "Max supply exceeded!");
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

  function totalSupply2() public view returns (uint256) {
    return _currentIndex ;
  }

  function getWhitelistAmountMinted(address addr) public view returns (uint256) {
    return whitelistClaimed[addr];
  }
  
  
  //Limited at 2 discounted mints
  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintComplianceWL(_mintAmount) mintWhitelistPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    //require(whitelistMintEnabled, "The whitelist sale is not enabled!");
    require(!paused, "The contract is paused!");
    require(_mintAmount + whitelistClaimed[msg.sender] <= 2, "Amount minted would exceed the two mint limit!");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");
    whitelistClaimed[msg.sender] += _mintAmount;
    _mintLoop(msg.sender, _mintAmount);
  }

  function getFreeMintListAmountMinted(address addr) public view returns (bool) {
    return freeMintClaimed[addr];
  }
  //Limited at 1 free mint
  function claimFreeMint(bytes32[] calldata _merkleProof2) public payable  mintComplianceWL(1)  {
    // Verify freemint requirements
    require(!paused, "The contract is paused!");
    require(freeMintClaimed[msg.sender] == false, "Amount minted would exceed the one free mint limit!");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof2, merkleRoot2, leaf), "Invalid proof!");
    freeMintClaimed[msg.sender] = true;
    _mintLoop(msg.sender, 1);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");

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
  //free mint list
  function setMerkleRoot2(bytes32 _merkleRoot2) public onlyOwner {
    merkleRoot2 = _merkleRoot2;
  }

  // function setWhitelistMintEnabled(bool _state) public onlyOwner {        //disabled
  //   whitelistMintEnabled = _state;
  // }

  function withdraw() public onlyOwner nonReentrant {
    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }

  function burn(uint _nftTokenId) public payable {
      require(balanceOf(msg.sender) >= 1, "You don't own any Loner Girls");
      safeTransferFrom(msg.sender, deadZone, _nftTokenId);
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
      _safeMint(_receiver, _mintAmount);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}