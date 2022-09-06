// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract HoneyBadger is ERC721, Ownable, Pausable, ReentrancyGuard {
  uint256 public constant MAX_NORMAL_SUPPLY = 6666;
  uint256 public constant SUPER_MINT_SUPPLY = 12;
  uint256 public constant MAX_FREEMINT_SUPPLY = 2222;
  uint256 public constant MINT_PRICE = 0.03 ether;
  uint256 public constant MAX_MINT_AMOUNT = 5;
  uint256 public constant MAX_FREEMINT_AMOUNT = 2;

  uint256 private totalNormalMinted = 0;
  uint256 private totalSuperMinted = 0;

  bytes32 public freeMintMerkleRoot;

  // windows
  uint256 public freeMintStartedAt = 7952313600;
  uint256 public freeMintEndedAt = freeMintStartedAt + 43200;
  uint256 public mintStartedAt = freeMintEndedAt + 3600;

  mapping(address => uint256) public mintedAmount;

  string private baseURI;

  string private superBaseURI;

  string private unopenURI;

  modifier nonContract() {
    require(msg.sender.code.length == 0, "contract address is forbidden");
    require(tx.origin == msg.sender, "external call is forbidden");
    _;
  }

  constructor(string memory _name, string memory _symbol)
    ERC721(_name, _symbol)
  {}

  function setStartTime(
    uint256 _freeMintStartedAt,
    uint256 _freeMintDuration,
    uint256 _mintWait
  ) external onlyOwner {
    freeMintStartedAt = _freeMintStartedAt;
    freeMintEndedAt = _freeMintStartedAt + _freeMintDuration;
    mintStartedAt = freeMintEndedAt + _mintWait;
  }

  function setFreeMintMerkleRoot(bytes32 _root) external onlyOwner {
    freeMintMerkleRoot = _root;
  }

  modifier canEarlyAccess(bytes32[] calldata merkleProof) {
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(
      MerkleProof.verify(merkleProof, freeMintMerkleRoot, leaf),
      "address does not exist in allow list"
    );
    
    _;
  }

  function totalSupply() external view returns (uint256) {
    return totalNormalMinted + totalSuperMinted;
  }

  function canFreeMint() public view returns (bool) {
    uint256 current = block.timestamp;
    return current >= freeMintStartedAt && current < freeMintEndedAt && totalNormalMinted < MAX_FREEMINT_SUPPLY;
  }

  function freeMint(uint256 _amount, bytes32[] calldata _merkleProof) external whenNotPaused nonContract nonReentrant canEarlyAccess(_merkleProof) {
    require(canFreeMint(), "free mint has ended or not started");
    require(_amount + mintedAmount[msg.sender] <= MAX_FREEMINT_AMOUNT, "can only free mint 2 tokens at most");
    require(totalNormalMinted + _amount <= MAX_FREEMINT_SUPPLY, "max freemint supply exceeded");

    _normalMint(msg.sender, _amount);
  }

  function mint(uint256 _amount) external whenNotPaused nonContract nonReentrant payable {
    require(block.timestamp >= mintStartedAt, "mint has not started");
    require(_amount + mintedAmount[msg.sender] <= MAX_MINT_AMOUNT, "can only mint 10 tokens at most");
    require(MINT_PRICE * _amount == msg.value, "value sent is not correct");

    _normalMint(msg.sender, _amount);
  }

  function superMint(address _to) external whenNotPaused nonContract nonReentrant onlyOwner {
    require(block.timestamp >= mintStartedAt, "mint has not started");
    require(totalSuperMinted == 0, "super mint has already been done");

    uint256 tokenId = MAX_NORMAL_SUPPLY;

    _batchSafeMint(_to, tokenId, SUPER_MINT_SUPPLY);

    totalSuperMinted += SUPER_MINT_SUPPLY;
  }

  function _normalMint(address to, uint256 amount) internal {
    require(totalNormalMinted + amount <= MAX_NORMAL_SUPPLY, "max supply exceeded");

    mintedAmount[to] += amount;

    uint256 tokenId = totalNormalMinted;
    _batchSafeMint(to, tokenId, amount);

    totalNormalMinted += amount;
  }

  function _batchSafeMint(address to, uint256 tokenId, uint256 amount) internal {
    for (uint256 i = 0; i < amount; i++) {
      _safeMint(to, tokenId + i);
    }
  }

  function setBaseURI(string memory _baseURI) external onlyOwner {
    baseURI = _baseURI;
  }

  function setSuperBaseURI(string memory _baseURI) external onlyOwner {
    superBaseURI = _baseURI;
  }

  function setUnopenURI(string memory _unopenURI) external onlyOwner {
    unopenURI = _unopenURI;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    _requireMinted(tokenId);

    if (tokenId < MAX_NORMAL_SUPPLY) {
      return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId))) : unopenURI;
    } else {
      return bytes(superBaseURI).length > 0 ? string(abi.encodePacked(superBaseURI, Strings.toString(tokenId))) : unopenURI;
    }
  }
}