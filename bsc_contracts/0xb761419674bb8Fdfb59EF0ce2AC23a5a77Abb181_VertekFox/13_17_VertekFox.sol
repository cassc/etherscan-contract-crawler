// SPDX-License-Identifier: MIT

/***
 *   ___      ___  _______   _______  ___________  _______  __   ___      _____  ___    _______  ___________  ________
 *|"  \    /"  |/"     "| /"      \("     _   ")/"     "||/"| /  ")    (\"   \|"  \  /"     "|("     _   ")/"       )
 * \   \  //  /(: ______)|:        |)__/  \\__/(: ______)(: |/   /     |.\\   \    |(: ______) )__/  \\__/(:   \___/
 *  \\  \/. ./  \/    |  |_____/   )   \\_ /    \/    |  |    __/      |: \.   \\  | \/    |      \\_ /    \___  \
 *   \.    //   // ___)_  //      /    |.  |    // ___)_ (// _  \      |.  \    \. | // ___)      |.  |     __/  \\
 *    \\   /   (:      "||:  __   \    \:  |   (:      "||: | \  \     |    \    \ |(:  (         \:  |    /" \   :)
 *     \__/     \_______)|__|  \___)    \__|    \_______)(__|  \__)     \___|\____\) \__/          \__|   (_______/
 *
 * Vertek Landing Page: https://www.vertek.org/
 * Vertek Dapp: https://www.vertek.exchange/
 * Discord: https://discord.gg/vertek-ames-aalto
 * Medium: https://medium.com/@verteklabs
 * Twitter: https://twitter.com/Vertek_Dex
 * Telegram: https://t.me/aalto_protocol
 */

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract VertekFox is ERC721AQueryable, Ownable, ReentrancyGuard {
  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;
  mapping(uint256 => uint256) public baseRarity;
  uint256 internal seedRarity = 1;
  uint256 internal rarityAssigned;
  uint256 internal internalIndex = 1;

  mapping(uint256 => uint256) public attackRarity;
  mapping(uint256 => uint256) public defenseRarity;
  uint256 internal a_seedRarity = 3;
  uint256 internal d_seedRarity = 7;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
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
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(
      _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
      'Invalid mint amount!'
    );
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  modifier assignRarity(uint256 _mintAmount) {
    uint256 raritySeed = block.timestamp;
    for (uint i = 0; i < _mintAmount; i++) {
      uint256 rarityModulus = ((raritySeed % 10) + seedRarity) % 10;
      if (rarityModulus == 0) {
        rarityAssigned = 4;
      }
      if (rarityModulus >= 1 && rarityModulus <= 2) {
        rarityAssigned = 3;
      }
      if (rarityModulus >= 3 && rarityModulus <= 5) {
        rarityAssigned = 2;
      }
      if (rarityModulus >= 6 && rarityModulus <= 10) {
        rarityAssigned = 1;
      }
      baseRarity[internalIndex] = rarityAssigned;
      rarityModulus++;
      seedRarity = rarityModulus;
      attackRarity[internalIndex] = ((raritySeed % 35) + a_seedRarity) % 30;
      defenseRarity[internalIndex] =
        ((raritySeed % 30) + d_seedRarity + seedRarity) %
        40;
      a_seedRarity = a_seedRarity + d_seedRarity;
      d_seedRarity = d_seedRarity + seedRarity;
      internalIndex++;
    }
    _;
  }

  function whitelistMint(
    uint256 _mintAmount,
    bytes32[] calldata _merkleProof
  )
    public
    payable
    mintCompliance(_mintAmount)
    mintPriceCompliance(_mintAmount)
    assignRarity(_mintAmount)
  {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(
      MerkleProof.verify(_merkleProof, merkleRoot, leaf),
      'Invalid proof!'
    );

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(
    uint256 _mintAmount
  )
    public
    payable
    mintCompliance(_mintAmount)
    mintPriceCompliance(_mintAmount)
    assignRarity(_mintAmount)
  {
    require(!paused, 'The contract is paused!');
    _safeMint(_msgSender(), _mintAmount);
  }

  function mintForAddress(
    uint256 _mintAmount,
    address _receiver
  ) public mintCompliance(_mintAmount) onlyOwner assignRarity(_mintAmount) {
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(
    uint256 _tokenId
  ) public view virtual override returns (string memory) {
    require(
      _exists(_tokenId),
      'ERC721Metadata: URI query for nonexistent token'
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return
      bytes(currentBaseURI).length > 0
        ? string(
          abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)
        )
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

  function setHiddenMetadataUri(
    string memory _hiddenMetadataUri
  ) public onlyOwner {
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
    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{ value: address(this).balance }('');
    require(os);
    // =============================================================================
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}