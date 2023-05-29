// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract LongNeckieKids is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public phase1MerkleRoot;
  bytes32 public phase2MerkleRoot;
  mapping(address => bool) public phase1AllowListClaimed;
  mapping(address => bool) public phase2AllowListClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public phase1AllowListEnabled = false;
  bool public phase2AllowListEnabled = false;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function allowListMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify allowlist requirements
		if (phase2AllowListEnabled) {
			require(!phase2AllowListClaimed[_msgSender()], 'Address already claimed!');
			bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
			require(MerkleProof.verify(_merkleProof, phase2MerkleRoot, leaf), 'Invalid proof!');

			phase2AllowListClaimed[_msgSender()] = true;
		} else {
			require(phase1AllowListEnabled, 'The allow list sale is not enabled!');
			require(!phase1AllowListClaimed[_msgSender()], 'Address already claimed!');
			bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
			require(MerkleProof.verify(_merkleProof, phase1MerkleRoot, leaf), 'Invalid proof!');

			phase1AllowListClaimed[_msgSender()] = true;
		}

		_safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

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

    while (ownedTokenIndex < ownerTokenCount && currentTokenId < _currentIndex) {
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

  function setPhase1MerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    phase1MerkleRoot = _merkleRoot;
  }

	function setPhase2MerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    phase2MerkleRoot = _merkleRoot;
  }

  function setPhase1AllowListMintEnabled(bool _state) public onlyOwner {
    phase1AllowListEnabled = _state;
    phase2AllowListEnabled = false;
  }

	function setPhase2AllowListMintEnabled(bool _state) public onlyOwner {
    phase1AllowListEnabled = false;
    phase2AllowListEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {

		uint256 beforeBalance = address(this).balance;

		// Split account 1 - 44.55%
    (bool success1, ) = payable(0xFC92a0656B4Bd7fBf4Cbdf2d7b55c251d738C3d8).call{value: beforeBalance * 4455 / 10000}('');
    require(success1);

		// Split account 2 - 4.95%
    (bool success2, ) = payable(0x7F27a7d6f7D89D16a28ccf53F817159F594886d7).call{value: beforeBalance * 495 / 10000}('');
    require(success2);

		// Split account 3 - 50.5% (49.5% zigazoo + 1% charity)
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}