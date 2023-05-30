// SPDX-License-Identifier: MIT

// Stop looking at this shit ass contract GOBLOK! 
// ᴺᵒ ʳᴼᴬᵈᵐᴬᵖ. ᴺᵒ ᴰᶦˢᶜᵒʳᴰ. ᴺᵒ ᵁᴸᵗᶦᴸᶦᵀʸ. ᶜᴼⁿᵀʳᵃᶜᵗ ʷᴬˢ ᵂʳᶦᵀᵀᵉᴺ ᵇʸ ᵃ ᴳᵒᴮᴸᶦᴺ 

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract GoblinsZukiDeployer is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;
  mapping(address => uint256) public walletMints;
  mapping(address => uint256) public WLwalletMints;

  string public uriPrefix = '';
  string public uriSuffix = '.json';

  // hidden Uri
  string public hiddenMetadataUri = "ipfs://QmTR6ZyjvS2BvVzWRa4h57uGaZcQvuQiyoGz48wjNHPkjL/hidden.json";
  
  uint256 public cost;
  uint256 public costAfterMint = 0.0069 ether;

  // Supply
  uint256 public maxSupply = 6969;
  uint256 public freeMintSupply = 4200;

  // max mint per tx
  uint256 public maxMintAmountPerTx = 2;
  uint256 public WLmaxMintAmountPerTx = 1;

  // max per wallets
  uint256 public maxLimitPerWallet = 2;
  uint256 public WLmaxLimitPerWallet = 1;

  bool public paused = true;
  bool public whitelistMintEnabled = false;

  // reveal
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxMintAmountPerTx
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
  }

  modifier WLmintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    require(WLwalletMints[msg.sender] + _mintAmount <= WLmaxLimitPerWallet, 'Max mint 1 per WL wallet exceeded!' );
    WLwalletMints[msg.sender] += _mintAmount;
    _;
  }
  
  modifier WLmintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    require(walletMints[msg.sender] + _mintAmount <= maxLimitPerWallet, 'Max mint 2 per Public wallet exceeded! WhiteListed please dont mint and trying to be greedy kthxbye ' );
    walletMints[msg.sender] += _mintAmount;
    _;
  }
  
  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable WLmintCompliance(_mintAmount) WLmintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');
    require( totalSupply() + _mintAmount <= maxSupply , "Maximum supply exceeded" );
    if(_mintAmount + totalSupply() > freeMintSupply){
      require(msg.value >= (costAfterMint * _mintAmount), 'Free mint is over scrub');
    } 

     _safeMint(_msgSender(), _mintAmount);
  }

  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId < maxSupply) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];

      if (!ownership.burned) {
        if (ownership.addr != address(0)) {
          latestOwnerAddress = ownership.addr;
        }

        if (latestOwnerAddress == _owner) {
          ownedTokenIds[ownedTokenIndex] = currentTokenId;

          ownedTokenIndex++;
        }
      }

      currentTokenId++;
    }

    return ownedTokenIds;
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

  function setCost(uint256 _cost) public onlyOwner {
      cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  // set Max min per wallet
  function setmaxLimitPerWallet(uint256 _maxLimitPerWallet) public onlyOwner {
    maxLimitPerWallet = _maxLimitPerWallet;
  }

  // set Max WL mint per wallet
  function setWLmaxLimitPerWallet(uint256 _WLmaxLimitPerWallet) public onlyOwner {
    WLmaxLimitPerWallet = _WLmaxLimitPerWallet;
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

  function setmaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function mintForAddresses(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _safeMint(_receiver, _mintAmount);
  }

  function withdraw() public onlyOwner nonReentrant {

    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}