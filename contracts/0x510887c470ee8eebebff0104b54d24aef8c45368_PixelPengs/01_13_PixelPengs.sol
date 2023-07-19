// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

contract PixelPengs is Ownable, ERC721 {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private _tokenSupply;
  Counters.Counter private _whitelistMinted;

  string public collectionName;
  string public collectionSymbol;

  uint256 public tokenPrice = 0.025 ether;
  uint256 public constant MINT_LIMIT_PER_TX = 8;
  uint256 public constant TOTAL_SUPPLY = 10001;

  // Keep track of the claimed bit map of whitelists
  mapping(uint256 => uint256) private claimedBitMap;
  bytes32 public merkleRoot;
  uint256 public constant WHITELIST_MINTS = 1501;

  // Activation and revealed state
  bool public active = false;
  bool public revealed = false;

  // Stores non revealed URI and its base extension
  string public nonReavealedURI;
  string public constant baseExtension = '.json';

  string _baseTokenURI;
  address _proxyRegistryAddress;

  constructor(
    address proxyRegistryAddress,
    bytes32 _merkleRoot,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721('PixelPengs', 'PXP') {
    collectionName = name();
    collectionSymbol = symbol();
    merkleRoot = _merkleRoot;
    nonReavealedURI = _initNotRevealedUri;
    _baseTokenURI = _initBaseURI;
    _proxyRegistryAddress = proxyRegistryAddress;
    _tokenSupply.increment();
    _whitelistMinted.increment();
    _safeMint(msg.sender, 0);
  }

  function isClaimed(uint256 index) public view returns (bool) {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    uint256 claimedWord = claimedBitMap[claimedWordIndex];
    uint256 mask = (1 << claimedBitIndex);
    return claimedWord & mask == mask;
  }

  function _setClaimed(uint256 index) private {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
  }

  function claim(
    uint256 amount,
    uint256 index,
    address _address,
    bytes32[] memory proof
  ) private {
    require(!isClaimed(index), 'You have already claimed your whitelist mint');
    bytes32 node = keccak256(abi.encodePacked(index, _address, amount));
    require(MerkleProof.verify(proof, merkleRoot, node), 'Invalid Claims - Not on the whitelist or the proof modified');
    _setClaimed(index);
  }

  // Minting Methods
  function whitelistMint(
    uint256 amount,
    uint256 index,
    bytes32[] memory proof
  ) external {
    require(active, 'Token sale is not currently active');

    uint256 supply = _tokenSupply.current();
    uint256 whitelistMinted = _whitelistMinted.current();
    require(supply + amount <= TOTAL_SUPPLY, 'Not enough tokens are remaining in the supply');
    require(whitelistMinted + amount <= WHITELIST_MINTS, 'Whitelist mints have all be claimed');

    // Claim the whitelist mint
    claim(amount, index, msg.sender, proof);

    for (uint256 i = 0; i < amount; i++) {
      _tokenSupply.increment();
      _whitelistMinted.increment();
      _safeMint(msg.sender, supply + i);
    }
  }

  function publicMint(uint256 amount) external payable {
    require(active, 'Token sale is not currently active');
    require(amount <= MINT_LIMIT_PER_TX, 'Cannot mint more than 8 tokens per transation');

    uint256 supply = _tokenSupply.current();
    require(supply + amount <= TOTAL_SUPPLY, 'Not enough tokens are remaining in the supply');

    require(tokenPrice * amount <= msg.value, 'Not enough ethereum sent to mint');

    for (uint256 i = 0; i < amount; i++) {
      _tokenSupply.increment();
      _safeMint(msg.sender, supply + i);
    }
  }

  function mintOwner(address to, uint256 amount) external onlyOwner {
    uint256 supply = _tokenSupply.current();
    require(supply + amount <= TOTAL_SUPPLY, 'Cannot mint more than the total supply');

    for (uint256 i = 0; i < amount; i++) {
      _tokenSupply.increment();
      _safeMint(to, supply + i);
    }
  }

  // ownerOnly Methods
  function reveal() external onlyOwner {
    revealed = true;
  }

  function setTokenPrice(uint256 newPrice) external onlyOwner {
    require(newPrice > 0, 'New price must be greater than 0');
    tokenPrice = newPrice;
  }

  function toggleActiveState() external onlyOwner {
    active = !active;
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setBaseURI(string memory newBaseURI) external onlyOwner {
    _baseTokenURI = newBaseURI;
  }

  function setNonRevealedURI(string memory newNonRevealedURI) external onlyOwner {
    nonReavealedURI = newNonRevealedURI;
  }

  function setProxyRegistryAddress(address proxyRegistryAddress) external onlyOwner {
    _proxyRegistryAddress = proxyRegistryAddress;
  }

  function withdraw() external onlyOwner {
    (bool success, ) = payable(owner()).call{value: address(this).balance}('');
    require(success, 'Withdrawal failed');
  }

  // Internal Methods
  function _baseURI() internal view override returns (string memory) {
    return _baseTokenURI;
  }

  // Public readable methods
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return nonReavealedURI;
    }

    string memory currentBaseURI = _baseURI();
    return
      bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : '';
  }

  function currentSupply() public view returns (uint256) {
    return _tokenSupply.current();
  }

  function whitelistSupply() public view returns (uint256) {
    return _whitelistMinted.current();
  }

  function isApprovedForAll(address owner, address operator) public view override returns (bool) {
    // Whitelist OpenSea proxy contract for easy trading.
    ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
    if (address(proxyRegistry.proxies(owner)) == operator) {
      return true;
    }
    return super.isApprovedForAll(owner, operator);
  }

  receive() external payable {}
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}