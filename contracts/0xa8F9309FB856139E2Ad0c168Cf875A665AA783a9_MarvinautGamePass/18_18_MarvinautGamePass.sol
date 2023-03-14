// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/Base64.sol';

/// @custom:security-contact [email protected]
contract MarvinautGamePass is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, Pausable {
  using Strings for uint256;
  using ECDSA for bytes32;
  using ECDSA for bytes;

  address public signer;

  string public baseURI;
  string public mediaURI;
  uint256 public constant maxSupply = 2500;
  uint256 public price;

  uint256 public maxMintPerWallet;
  uint256 public wlMintStart;
  uint256 public publicMintStart;
  uint256 public endMint;

  uint256 public goldSlots;
  uint256 public diamondSlots;
  uint256 private currentTokenId = 0;
  uint256 private upgradedTokenId = maxSupply + 1;
  mapping(uint256 => uint8) tokenIdToTier;

  event Upgrade(address _account, uint256[] _tokens, uint8[] _tiers);

  constructor() ERC721('Marvinaut Game Pass', 'MVG') {}

  function setupContract(
    address _signer,
    string memory __baseURI,
    string memory _mediaURI,
    uint256 _price,
    uint256 _maxMintPerWallet,
    uint256 _wlMintStart,
    uint256 _publicMintStart,
    uint256 _endMint,
    uint256 _goldSlots,
    uint256 _diamondSlots
  ) public onlyOwner {
    signer = _signer;
    baseURI = __baseURI;
    mediaURI = _mediaURI;
    price = _price;
    maxMintPerWallet = _maxMintPerWallet;
    wlMintStart = _wlMintStart;
    publicMintStart = _publicMintStart;
    endMint = _endMint;
    goldSlots = _goldSlots;
    diamondSlots = _diamondSlots;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function mintingActive() public view returns (bool) {
    return block.timestamp > publicMintStart;
  }

  function wlActive() public view returns (bool) {
    return block.timestamp > wlMintStart;
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    if (tokenId > 2500) {
      require(ownerOf(tokenId) != address(0), 'ERC721: invalid token ID');

      uint8 tier = tokenIdToTier[tokenId];
      string memory video = 'silver';
      string memory tierStr = 'Silver';

      if (tier == 1) {
        video = 'gold';
        tierStr = 'Gold';
      }

      if (tier == 2) {
        video = 'blackdiamond';
        tierStr = 'Black Diamond';
      }

      bytes memory metadata = abi.encodePacked(
        '{',
        '"name": "#',
        tokenId.toString(),
        '",',
        '"description": "Marvinaut Game Pass",',
        '"image": "',
        string(abi.encodePacked(mediaURI, video, '.mp4')),
        '",',
        '"attributes": [{',
        '"trait_type": "Tier",',
        '"value": "',
        tierStr,
        '"',
        '}]',
        '}'
      );
      return string(abi.encodePacked('data:application/json;base64,', Base64.encode(metadata)));
    }
    return super.tokenURI(tokenId);
  }

  function _mintGamePass(address _to, uint256 _mintAmount) internal {
    require(!paused(), 'Paused');
    require(block.timestamp < endMint, 'MintIsEnded');
    require(currentTokenId + _mintAmount < maxSupply + 1, 'NotEnoughTokenLeft');

    if (_msgSender() != owner()) {
      require(msg.value >= price * _mintAmount, 'Insufficient');
    }

    for (uint256 i = 1; i < _mintAmount + 1; i++) {
      _mint(_to, currentTokenId + i);
    }
    currentTokenId += _mintAmount;
  }

  function mint(address _to, uint256 _mintAmount) external payable {
    require(mintingActive(), 'PublicMintNotStarted');
    _mintGamePass(_to, _mintAmount);
  }

  function wlMint(address _to, uint256 _mintAmount, bytes32 _hashedMessage, bytes memory _signature) external payable {
    require(wlActive(), 'WhitelistMintNotStarted');
    require(_hashedMessage.toEthSignedMessageHash().recover(_signature) == signer, 'InvalidSigner');
    require(block.timestamp < publicMintStart, 'WhitelistMintIsEnded');
    require(_mintAmount <= maxMintPerWallet, 'InvalidAmount');

    _mintGamePass(_to, _mintAmount);
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    require(_isApprovedOrOwner(_msgSender(), tokenId), 'ERC721: caller is not token owner or approved');
    super._burn(tokenId);
  }

  function upgradeGamePass(
    uint256[] calldata _tokens,
    uint8[] calldata _tiers,
    bytes32 _hashedMessage,
    bytes memory _signature
  ) public {
    require(_tokens.length == 3, 'Need3ItemsToUpgrade');
    require(_tokens.length == _tiers.length, 'InvalidData');

    bytes32 msgHash = keccak256(abi.encodePacked(_tokens, _tiers));
    require(msgHash == _hashedMessage, 'InvalidSignature');
    require(_hashedMessage.toEthSignedMessageHash().recover(_signature) == signer, 'InvalidSigner');

    uint8 tier = _tiers[0];
    require(tier < 2, 'NoNeedToUpgrade');
    for (uint256 i = 0; i < _tokens.length; i++) {
      require(_isApprovedOrOwner(_msgSender(), _tokens[i]), 'ERC721: caller is not token owner or approved');
      require(tier == _tiers[i], 'MustBeSameTier');
    }

    if (tier == 0) {
      require(goldSlots > 0, 'GoldMaxReached');
    }

    if (tier == 1) {
      require(diamondSlots > 0, 'DiamondMaxReached');
    }

    _mint(_msgSender(), upgradedTokenId);
    tokenIdToTier[upgradedTokenId] = tier + 1;
    upgradedTokenId++;

    if (tier == 0) {
      goldSlots--;
    }

    if (tier == 1) {
      goldSlots += 3;
      diamondSlots--;
    }

    for (uint256 i = 0; i < _tokens.length; i++) {
      _burn(_tokens[i]);
    }

    emit Upgrade(msg.sender, _tokens, _tiers);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 batchSize
  ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
    super._beforeTokenTransfer(from, to, tokenId, batchSize);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function setSigner(address _signer) public onlyOwner {
    signer = _signer;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setMediaURI(string memory _newMediaURI) public onlyOwner {
    mediaURI = _newMediaURI;
  }

  function setPrice(uint256 _newPrice) public onlyOwner {
    price = _newPrice;
  }

  function setMaxMintPerWallet(uint256 _maxMintPerWallet) public onlyOwner {
    maxMintPerWallet = _maxMintPerWallet;
  }

  function setPublicMintStart(uint256 _publicMintStart) public onlyOwner {
    publicMintStart = _publicMintStart;
  }

  function setWlMintStart(uint256 _wlMintStart) public onlyOwner {
    wlMintStart = _wlMintStart;
  }

  function setEndMint(uint256 _endMint) public onlyOwner {
    endMint = _endMint;
  }

  function setGoldSlots(uint256 _goldSlots) public onlyOwner {
    goldSlots = _goldSlots;
  }

  function setDiamondSlots(uint256 _diamondSlots) public onlyOwner {
    diamondSlots = _diamondSlots;
  }

  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }
}