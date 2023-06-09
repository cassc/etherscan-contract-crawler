// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@[email protected]@@@@@@@@[email protected]@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@[email protected]@[email protected]@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@[email protected]@[email protected]@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@.............................................@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@
// @@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract FairyFiends is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => uint256) public whitelistClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

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

// Checking that user is able to mint _mintAmount
  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

// Checking that the price is correct to mint _mintAmount
  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

// Minting function for the Owner 
  function mintOwner(uint256 quantity_) external onlyOwner {
    _safeMint(msg.sender, quantity_);
  }

// Whitelist (Fairylist) minting function
  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(whitelistClaimed[_msgSender()] + _mintAmount <= 3, 'Address already claimed or will exceed max ammount!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] += _mintAmount;
    _safeMint(_msgSender(), _mintAmount);
  }

// Minting function for current user / Wallet
  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), _mintAmount);
  }
  
  // Minting function to send to another user / Wallet
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

// Wallet address for the owner, returning the ammount of tokens held by the owner
  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];

      if (!ownership.burned && ownership.addr != address(0)) {
        latestOwnerAddress = ownership.addr;
      }

      if (latestOwnerAddress == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

// Starting the token id's from 1 
  function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

// The URI of the token specified by _tokenID 
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

// Set the revealed var
  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

// Set the cost var
  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

// Set the max Supply var
  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }
// Set max ammount per transaction
  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

// Set the hidden metadata URI
  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

// Set the URI prefix
  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

// Set the URI suffix
  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

// Set the mint to paused
  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

// Set the Merkleroot for the collection
  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

// Set the whitelist enabled var
  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

// Withdraw from contract, accessible only to the owner
  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

// Returns the base URI 
  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}