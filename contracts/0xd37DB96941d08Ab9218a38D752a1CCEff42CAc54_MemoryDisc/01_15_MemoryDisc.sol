// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract MemoryDisc is
  ERC721,
  ReentrancyGuard,
  Ownable,
  DefaultOperatorFilterer
{
  uint256 public constant MAX_SUPPLY = 3000;
  uint256 public constant PRICE = 0.02 ether;
  address public constant ARTIST = 0x2fe815AE662c439B5D33e712D0b2AC1B47FA2567;

  struct Attrs {
    bytes32 hash;
    string palette;
    string image;
    string message;
    string shape;
    uint256 speed;
    uint256 size;
    uint256 weight;
    uint256 offset;
    bool dynamic;
  }

  string[] private PALETTES = [
    "0100a8-58a8a9-bfc7c8-a9aeb1-0a0919",
    "e6e6e6-6ccbf9-dbd5d9-4f8cdc-ffffff-e8e8e8",
    "455354-f8f8f2-1b1d1e-f92672-a6e22e-ae81ff",
    "313633-ccdc90-7f9f7f-3f3f3f-e3ceab-dcdccc",
    "818596-17171b-89b8c2-84a0c6-c6c8d1-a093c7",
    "504945-ebdbb2-282828-fb4934-83a598-b8bb26",
    "88c0d0-4c566a-2e3440-81a1c1-d8dee9-b48ead",
    "000000-424450-bd93f9-ff79c6-f8f8f2-50fa7b",
    "f8f8f2-66747f-2b3e50-ff6541-66d9ef-5c98cd",
    "ebefc0-232738-0e101a-795ccc-5a5f7b-aeb18d",
    "80cbc4-546e7a-263238-ffffff-c792ea-82b1ff",
    "f7f9f9-121424-54c9ff-e9729f-a2a0df-7e7e7e",
    "87afff-1c1c1c-ffffff-00afff-c6c6c6-ffaf5f",
    "eeeeee-005f5f-002b36-8787af-ffdf87-87afaf",
    "ee5d43-5f6167-23262e-ffffff-c74ded-00e8c6",
    "b7c5d3-171d23-5ec4ff-b7c5d3-718ca1-70e1e8",
    "1a1d45-d7b7bb-ff4ea5-6cac99-eaad64-7eb564"
  ];

  string[] private SHAPES = ["circle", "square", "triangle"];

  bool public isOnSale;
  bool public isMetadataFrozen;
  mapping(uint256 => Attrs) public tokenIdToAttributes;
  uint256[] private _mintedTokenIdList;

  string private _baseTokenURI;

  constructor(string memory baseTokenURI) ERC721("Memory Disc", "MD") {
    _baseTokenURI = baseTokenURI;
  }

  function mintedTokenIdList() external view returns (uint256[] memory) {
    return _mintedTokenIdList;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(_exists(tokenId), "MemoryDisc: URI query for nonexistent token");
    return
      string(
        bytes.concat(
          bytes(_baseTokenURI),
          bytes(Strings.toString(tokenId)),
          bytes(".json")
        )
      );
  }

  function setImage(uint256 tokenId, string memory image) external {
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "MemoryDisc: caller is not token owner"
    );
    tokenIdToAttributes[tokenId].image = image;
  }

  function setMessage(uint256 tokenId, string memory message) external {
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "MemoryDisc: caller is not token owner"
    );
    tokenIdToAttributes[tokenId].message = message;
  }

  function mintAndTransfer(address to, uint256 quantity) internal {
    uint256 nextTokenId = _mintedTokenIdList.length;
    require(
      nextTokenId + quantity <= MAX_SUPPLY,
      "MemoryDisc: Sold out or invalid amount"
    );

    for (uint256 i = 0; i < quantity; i++) {
      uint256 tokenId = nextTokenId + i;
      bytes32 hash = keccak256(
        abi.encodePacked(tokenId, block.timestamp, msg.sender)
      );

      Attrs memory attrs = _generateAttrs(hash);
      tokenIdToAttributes[tokenId] = attrs;

      _mintedTokenIdList.push(tokenId);
      _safeMint(ARTIST, tokenId);
      _safeTransfer(ARTIST, to, tokenId, "");
    }
  }

  function mint(uint256 quantity) external payable nonReentrant {
    require(isOnSale, "MemoryDisc: Not on sale");
    require(msg.value == PRICE * quantity, "MemoryDisc: Invalid value");
    mintAndTransfer(_msgSender(), quantity);
  }

  function mintForFree(address to, uint256 quantity) external onlyOwner {
    mintAndTransfer(to, quantity);
  }

  function setIsOnSale(bool _isOnSale) external onlyOwner {
    isOnSale = _isOnSale;
  }

  function setIsMetadataFrozen(bool _isMetadataFrozen) external onlyOwner {
    require(
      !isMetadataFrozen,
      "MemoryDisc: isMetadataFrozen cannot be changed"
    );
    isMetadataFrozen = _isMetadataFrozen;
  }

  function setBaseTokenURI(string memory baseTokenURI) external onlyOwner {
    require(!isMetadataFrozen, "MemoryDisc: Metadata is already frozen");
    _baseTokenURI = baseTokenURI;
  }

  function withdraw() external onlyOwner {
    Address.sendValue(payable(msg.sender), address(this).balance);
  }

  function _generateAttrs(bytes32 hash) internal view returns (Attrs memory) {
    uint256 pseudorandomness = uint256(hash);

    string memory palette = PALETTES[uint8(pseudorandomness) % PALETTES.length];
    string memory shape = SHAPES[uint8(pseudorandomness) % SHAPES.length];
    uint256 speed = (uint256(pseudorandomness >> (8 * 1)) % 100) + 1;
    uint256 size = (uint256(pseudorandomness >> (8 * 2)) % 100) + 1;
    uint256 weight = (uint256(pseudorandomness >> (8 * 3)) % 100) + 1;
    uint256 offset = (uint256(pseudorandomness >> (8 * 4)) % 100) + 1;
    bool dynamic = pseudorandomness % 10 != 0;

    return
      Attrs(hash, palette, "", "", shape, speed, size, weight, offset, dynamic);
  }

  /**
   * Operator Filter Registry
   */
  function setApprovalForAll(address operator, bool approved)
    public
    override
    onlyAllowedOperatorApproval(operator)
  {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId)
    public
    override
    onlyAllowedOperatorApproval(operator)
  {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}