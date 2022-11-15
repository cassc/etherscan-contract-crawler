// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import 'erc721a/contracts/ERC721A.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract GenesisNote is ERC721AQueryable, Ownable, ReentrancyGuard {

  IERC20 purchaseCurrency;

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;
  uint256 public maxMintAmountPerWallet;

  bool public paused = false;
  bool public transferAllowed = false;
  bool public whitelistMintEnabled = false;
  bool public revealed = true;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri,
    IERC20 _purchaseCurrency,
    string memory _uriPrefix,
    uint256 _maxMintAmountPerWallet
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setMaxMintAmountPerWallet(_maxMintAmountPerWallet);
    setHiddenMetadataUri(_hiddenMetadataUri);
    setUriPrefix(_uriPrefix);
    purchaseCurrency = IERC20(_purchaseCurrency);
  }


  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(balanceOf(msg.sender) + _mintAmount <= maxMintAmountPerWallet, 'maxMintAmountPerWallet reached');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(purchaseCurrency.balanceOf(msg.sender) >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) nonReentrant {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) nonReentrant {
    require(!paused, 'The contract is paused!');

    purchaseCurrency.transferFrom(msg.sender, address(this), _mintAmount * cost);
    _safeMint(msg.sender, _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }


  function transferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721A) {
    transferCompliance(from);
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override(ERC721A) {
    transferCompliance(from);
    super.safeTransferFrom(from, to, tokenId, _data);
  }

  function transferCompliance(address from) internal view {
    if (from != address(0)) {
      require(transferAllowed, "transfers are not allowed at this time");
    }
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721A) {
    require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
    transferCompliance(from);
    super.safeTransferFrom(from, to, tokenId);
  }

  function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual override(ERC721A) {
    super._beforeTokenTransfers(from, to, startTokenId, quantity);
    transferCompliance(from);
  }


  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }


  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }


  function setTransferAllowed(bool _transferAllowed) public onlyOwner {
    transferAllowed = _transferAllowed;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setMaxMintAmountPerWallet(uint256 _maxMintAmountPerWallet) public onlyOwner {
    maxMintAmountPerWallet = _maxMintAmountPerWallet;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function _burn(uint256 tokenId) internal override(ERC721A) nonReentrant {
    super._burn(tokenId);
  }

  function burn(uint256 tokenId) public nonReentrant{
    require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
    _burn(tokenId);
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
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    purchaseCurrency.transfer(msg.sender, purchaseCurrency.balanceOf(address(this)));
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}