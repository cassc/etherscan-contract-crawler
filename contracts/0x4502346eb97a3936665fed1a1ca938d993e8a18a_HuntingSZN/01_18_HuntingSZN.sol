// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {DefaultOperatorFilterer721, OperatorFilterer721} from "./DefaultOperatorFilterer721.sol";

contract HuntingSZN is ERC721A, DefaultOperatorFilterer721, Ownable, ReentrancyGuard {

  using Strings for uint256;

  mapping(address => uint256) public amountClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;

  bytes32 public merkleRoot;
  bytes32 public merkleRootTeam;

  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public teamMintEnabled = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    bytes32 _merkleRoot,
    bytes32 _merkleRootTeam
  ) ERC721A(_tokenName, _tokenSymbol) {
    cost = _cost;
    maxSupply = _maxSupply;
    maxMintAmountPerTx = _maxMintAmountPerTx;
    merkleRoot = _merkleRoot;
    merkleRootTeam = _merkleRootTeam;
  }

  function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
  public
  override
  onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(!paused, 'Contract is paused!');
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function teamMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) {
    require(teamMintEnabled, 'Team sale is disabled!');
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRootTeam, leaf), 'Invalid proof!');
    _safeMint(_msgSender(), _mintAmount);
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(whitelistMintEnabled, 'The whitelist sale is disabled!');
    require(amountClaimed[_msgSender()] <= maxMintAmountPerTx, 'Address already claimed max amount');
    amountClaimed[_msgSender()] = amountClaimed[_msgSender()] + _mintAmount;
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!whitelistMintEnabled, 'The whitelist sale is enabled!');
    _safeMint(_msgSender(), _mintAmount);
  }

  function airDrop(uint256 _mintAmount, address[] calldata _receivers) public mintCompliance(_mintAmount) onlyOwner {
    for (uint256 i = 0; i < _receivers.length; i++) {
      _safeMint(_receivers[i], _mintAmount);
    }
  }

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

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setMerkleRootTeam(bytes32 _merkleRootTeam) public onlyOwner {
    merkleRootTeam = _merkleRootTeam;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
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

  function setTeamMintEnabled(bool _state) public onlyOwner {
    teamMintEnabled = _state;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    uint256 balance = address(this).balance;
    uint256 projectWalletBal = balance * 40 / 100;
    uint256 founderBal = balance * 20 / 100;
    uint256 artistBal = balance * 20 / 100;
    uint256 communityManagerBal = balance * 10 / 100;
    uint256 developerBal = balance * 10 / 100;

    (bool ps, ) = payable(0x17BD65a45cD6B48C162191a1E2276e67812bC3Ce).call{value: projectWalletBal}('');
    require(ps);

    (bool fs, ) = payable(0x6f99D6E7E88d506F431B288608eE4A8a64477D9A).call{value: founderBal}('');
    require(fs);

    (bool cs, ) = payable(0x1BF1CC67aafd64385F8Bae6d257CDfA35E7cA951).call{value: artistBal}('');
    require(cs);

    (bool ms, ) = payable(0x89d46Fb865D46eee7813871C6E3764ebA4438AF2).call{value: communityManagerBal}('');
    require(ms);

    (bool ds, ) = payable(0xd8cf6013f11a93eE6E6C9c7CBf779eB5d36C9CAf).call{value: developerBal}('');
    require(ds);

    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}