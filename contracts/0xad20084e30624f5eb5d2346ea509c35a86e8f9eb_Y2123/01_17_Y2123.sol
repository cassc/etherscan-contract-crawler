//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*

Y2123 Game

Impact driven blockchain game with collaborative protocol.
Save our planet by completing missions.

y2123.com

*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./IY2123.sol";

contract Y2123 is IY2123, ERC721Enumerable, Ownable, Pausable, ReentrancyGuard {
  struct LastWrite {
    uint64 timestamp;
    uint64 blockNumber;
  }

  mapping(address => LastWrite) private lastWriteAddress;
  mapping(uint256 => LastWrite) private lastWriteToken;
  mapping(address => bool) private admins;

  using MerkleProof for bytes32[];
  bytes32 merkleRoot;
  bytes32 freeRoot;

  uint256 public constant MAX_SUPPLY_GENESIS = 500;
  uint256 public MAX_SUPPLY = 500;
  uint256 public MAX_RESERVE_MINT = 35;
  uint256 public MAX_FREE_MINT = 15;

  string private baseURI;
  uint256 public mintPrice = 0.063 ether;
  uint256 public maxMintPerTx = 3;
  uint256 public maxMintPerAddress = 2;
  bool public presaleEnabled = false;
  bool public saleEnabled = true;
  bool public freeMintEnabled = false;
  uint256 public reserveMintCount = 0;
  uint256 public freeMintCount = 0;

  mapping(address => uint256) public freeMintMinted;
  mapping(address => uint256) public whitelistMinted;
  mapping(address => uint256) public addressMinted;

  event Minted(uint256 indexed id);
  event MintedNonTxOrigin(address indexed addr, uint256 indexed id);
  event Burned(uint256 indexed id);
  event PresaleActive(bool active);
  event SaleActive(bool active);

  modifier blockIfChangingAddress() {
    require(admins[_msgSender()] || lastWriteAddress[tx.origin].blockNumber < block.number, "last write same block number");
    _;
  }

  modifier blockIfChangingToken(uint256 tokenId) {
    require(admins[_msgSender()] || lastWriteToken[tokenId].blockNumber < block.number, "last write same block number");
    _;
  }

  constructor(string memory uri) ERC721("Y2123", "Y2123") {
    _pause();
    baseURI = uri;
  }

  function setMerkleRoot(bytes32 root) public onlyOwner {
    merkleRoot = root;
  }

  function setFreeRoot(bytes32 root) public onlyOwner {
    freeRoot = root;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string memory newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
    if (MAX_SUPPLY != newMaxSupply) {
      require(newMaxSupply >= totalSupply(), "Value lower than total supply");
      require(newMaxSupply >= MAX_RESERVE_MINT + MAX_FREE_MINT, "Value lower than total reserve & free mints");
      MAX_SUPPLY = newMaxSupply;
    }
  }

  function setMaxReserveMint(uint256 newMaxReserveMint) external onlyOwner {
    if (MAX_RESERVE_MINT != newMaxReserveMint) {
      require(newMaxReserveMint >= reserveMintCount, "Value lower then reserve minted");
      MAX_RESERVE_MINT = newMaxReserveMint;
    }
  }

  function setMaxFreeMint(uint256 newMaxFreeMint) external onlyOwner {
    if (MAX_FREE_MINT != newMaxFreeMint) {
      require(newMaxFreeMint >= freeMintCount, "Value lower then free minted");
      MAX_FREE_MINT = newMaxFreeMint;
    }
  }

  function setMintPrice(uint256 newPrice) external onlyOwner {
    mintPrice = newPrice;
  }

  function toggleSale() external onlyOwner {
    saleEnabled = !saleEnabled;
    emit SaleActive(saleEnabled);
  }

  function togglePresale() external onlyOwner {
    presaleEnabled = !presaleEnabled;
    emit PresaleActive(presaleEnabled);
  }

  function toggleFreeMint() external onlyOwner {
    freeMintEnabled = !freeMintEnabled;
  }

  function setMaxMintPerTx(uint256 newMaxMintPerTx) public onlyOwner {
    require(newMaxMintPerTx > 0, "Value lower then 1");
    maxMintPerTx = newMaxMintPerTx;
  }

  function setMaxMintPerAddress(uint256 newMaxMintPerAddress) public onlyOwner {
    require(newMaxMintPerAddress > 0, "Value lower then 1");
    maxMintPerAddress = newMaxMintPerAddress;
  }

  function availableSupplyIndex() public view returns (uint256) {
    return (MAX_SUPPLY - MAX_RESERVE_MINT - MAX_FREE_MINT + reserveMintCount + freeMintCount);
  }

  function getTokenIDs(address addr) external view returns (uint256[] memory) {
    uint256 count = balanceOf(addr);

    uint256[] memory tokens = new uint256[](count);
    for (uint256 i; i < count; i++) {
      tokens[i] = tokenOfOwnerByIndex(addr, i);
    }

    return tokens;
  }

  // reserve NFT's for core team
  function reserve(uint256 amount) public onlyOwner {
    uint256 totalMinted = totalSupply();

    require(reserveMintCount + amount <= MAX_RESERVE_MINT, "Reserved more then available");

    for (uint256 i = 0; i < amount; i++) {
      _safeMint(msg.sender, totalMinted + i);
      addressMinted[msg.sender]++;
      reserveMintCount += 1;
    }
  }

  function airDrop(address[] calldata recipient, uint256[] calldata quantity) external onlyOwner {
    require(quantity.length == recipient.length, "Please provide equal quantities and recipients");

    uint256 totalQuantity = 0;
    uint256 supply = totalSupply();
    for (uint256 i = 0; i < quantity.length; ++i) {
      totalQuantity += quantity[i];
    }
    require(supply + totalQuantity <= availableSupplyIndex(), "Not enough supply");
    delete totalQuantity;

    for (uint256 i = 0; i < recipient.length; ++i) {
      for (uint256 j = 0; j < quantity[i]; ++j) {
        _safeMint(recipient[i], supply++);
        addressMinted[recipient[i]]++;
      }
    }
  }

  // ONLY 1 free mint per address throughout all collections
  function freeMint(bytes32[] memory proof) public payable nonReentrant {
    uint256 totalMinted = totalSupply();

    require(msg.sender == tx.origin);
    require(freeMintEnabled, "Free mint not enabled");
    require(proof.verify(freeRoot, keccak256(abi.encodePacked(msg.sender))), "You are not on the free list");
    require(freeMintCount + 1 <= MAX_FREE_MINT, "No more supply");
    require(freeMintMinted[msg.sender] < 1, "You already minted your free nft");

    _safeMint(msg.sender, totalMinted);
    addressMinted[msg.sender]++;

    freeMintMinted[msg.sender] = 1;
    freeMintCount += 1;
  }

  function paidMint(uint256 amount, bytes32[] memory proof) public payable nonReentrant {
    uint256 totalMinted = totalSupply();

    require(msg.sender == tx.origin);
    require(saleEnabled, "Sale not enabled");
    require(amount * mintPrice <= msg.value, "More ETH please");
    require(amount + totalMinted <= availableSupplyIndex(), "Please try minting with less, not enough supply!");

    if (presaleEnabled == true) {
      require(proof.verify(merkleRoot, keccak256(abi.encodePacked(msg.sender))), "You are not on the whitelist");
      require(amount + whitelistMinted[msg.sender] <= maxMintPerAddress, "Exceeded max mint per address for whitelist, try minting with less");
    } else {
      require(amount <= maxMintPerTx, "Exceeded max mint per transaction");
    }

    for (uint256 i = 0; i < amount; i++) {
      _safeMint(msg.sender, totalMinted + i);
      addressMinted[msg.sender]++;
      if (presaleEnabled == true) {
        whitelistMinted[msg.sender]++;
      }
    }
  }

  function withdrawAll() external onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }

  function getTokenWriteBlock(uint256 tokenId) external view override returns (uint64) {
    require(admins[_msgSender()], "Admins only!");
    return lastWriteToken[tokenId].blockNumber;
  }

  function getAddressWriteBlock(address addr) external view override returns (uint64) {
    require(admins[_msgSender()], "Admins only!");
    return lastWriteAddress[addr].blockNumber;
  }

  function mint(address recipient) external override whenNotPaused {
    uint256 minted = totalSupply();

    require(admins[_msgSender()], "Admins only!");
    require(minted + 1 <= availableSupplyIndex(), "All tokens minted");

    emit Minted(minted);
    if (tx.origin != recipient) {
      emit MintedNonTxOrigin(recipient, minted);
    }
    _safeMint(recipient, minted);
    addressMinted[msg.sender]++;
  }

  function burn(uint256 tokenId) external override whenNotPaused {
    require(admins[_msgSender()], "Admins only!");
    require(ownerOf(tokenId) == tx.origin, "Oops you don't own that");
    emit Burned(tokenId);
    _burn(tokenId);
  }

  function updateOriginAccess(uint256[] memory tokenIds) external override {
    require(admins[_msgSender()], "Admins only!");
    uint64 timestamp = uint64(block.timestamp);
    uint64 blockNumber = uint64(block.number);
    lastWriteAddress[tx.origin] = LastWrite(timestamp, blockNumber);
    for (uint256 i = 0; i < tokenIds.length; i++) {
      lastWriteToken[tokenIds[i]] = LastWrite(timestamp, blockNumber);
    }
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override(ERC721, IERC721) blockIfChangingToken(tokenId) {
    if (!admins[_msgSender()]) {
      require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
    }
    _transfer(from, to, tokenId);
  }

  /** ADMIN */

  function setPaused(bool _paused) external onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  function addAdmin(address addr) external onlyOwner {
    require(addr != address(0), "empty address");
    admins[addr] = true;
  }

  function removeAdmin(address addr) external onlyOwner {
    require(addr != address(0), "empty address");
    admins[addr] = false;
  }

  /** OVERRIDES FOR SAFETY */

  function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override(ERC721Enumerable, IERC721Enumerable) blockIfChangingAddress returns (uint256) {
    require(admins[_msgSender()] || lastWriteAddress[owner].blockNumber < block.number, "last write same block number");
    uint256 tokenId = super.tokenOfOwnerByIndex(owner, index);
    require(admins[_msgSender()] || lastWriteToken[tokenId].blockNumber < block.number, "last write same block number");
    return tokenId;
  }

  function balanceOf(address owner) public view virtual override(ERC721, IERC721) blockIfChangingAddress returns (uint256) {
    require(admins[_msgSender()] || lastWriteAddress[owner].blockNumber < block.number, "last write same block number");
    return super.balanceOf(owner);
  }

  function ownerOf(uint256 tokenId) public view virtual override(ERC721, IERC721) blockIfChangingAddress blockIfChangingToken(tokenId) returns (address) {
    address addr = super.ownerOf(tokenId);
    require(admins[_msgSender()] || lastWriteAddress[addr].blockNumber < block.number, "last write same block number");
    return addr;
  }

  function tokenByIndex(uint256 index) public view virtual override(ERC721Enumerable, IERC721Enumerable) returns (uint256) {
    uint256 tokenId = super.tokenByIndex(index);
    require(admins[_msgSender()] || lastWriteToken[tokenId].blockNumber < block.number, "last write same block number");
    return tokenId;
  }

  function approve(address to, uint256 tokenId) public virtual override(ERC721, IERC721) blockIfChangingToken(tokenId) {
    super.approve(to, tokenId);
  }

  function getApproved(uint256 tokenId) public view virtual override(ERC721, IERC721) blockIfChangingToken(tokenId) returns (address) {
    return super.getApproved(tokenId);
  }

  function setApprovalForAll(address operator, bool approved) public virtual override(ERC721, IERC721) blockIfChangingAddress {
    super.setApprovalForAll(operator, approved);
  }

  function isApprovedForAll(address owner, address operator) public view virtual override(ERC721, IERC721) blockIfChangingAddress returns (bool) {
    return super.isApprovedForAll(owner, operator);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override(ERC721, IERC721) blockIfChangingToken(tokenId) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual override(ERC721, IERC721) blockIfChangingToken(tokenId) {
    super.safeTransferFrom(from, to, tokenId, _data);
  }
}