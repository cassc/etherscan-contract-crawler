// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./AsciiPunkFactory.sol";
import "./ERC721Metadata.sol";
import "./PaymentSplitter.sol";

contract AsciiPunks is ERC721Metadata, PaymentSplitter {
  using Address for address;
  using Strings for uint256;

  // EVENTS
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );

  event Approval(
    address indexed owner,
    address indexed approved,
    uint256 indexed tokenId
  );

  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

  event Generated(uint256 indexed index, address indexed a, string value);

  mapping(uint256 => uint256) internal idToSeed;
  mapping(uint256 => uint256) internal seedToId;
  mapping(uint256 => address) internal idToOwner;
  mapping(address => uint256[]) internal ownerToIds;
  mapping(uint256 => uint256) internal idToOwnerIndex;
  mapping(address => mapping(address => bool)) internal ownerToOperators;
  mapping(uint256 => address) internal idToApproval;
  uint256 internal numTokens = 0;
  uint256 public constant TOKEN_LIMIT = 2048;
  bool public hasSaleStarted = false;

  bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
  bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

  modifier validNFToken(uint256 tokenId) {
    require(
      idToOwner[tokenId] != address(0),
      "ERC721: query for nonexistent token"
    );
    _;
  }

  modifier canOperate(uint256 tokenId) {
    address owner = idToOwner[tokenId];

    require(
      owner == _msgSender() || ownerToOperators[owner][_msgSender()],
      "ERC721: approve caller is not owner nor approved for all"
    );
    _;
  }

  modifier canTransfer(uint256 tokenId) {
    address tokenOwner = idToOwner[tokenId];

    require(
      tokenOwner == _msgSender() ||
        idToApproval[tokenId] == _msgSender() ||
        ownerToOperators[tokenOwner][_msgSender()],
      "ERC721: transfer caller is not owner nor approved"
    );
    _;
  }

  constructor() {
    _registerInterface(_INTERFACE_ID_ERC721);
    _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
  }

  function createPunk(uint256 seed) external payable returns (string memory) {
    return _mint(_msgSender(), seed);
  }

  function calculatePrice() internal view returns (uint256) {
    uint256 price;
    if (numTokens < 256) {
      price = 50000000000000000;
    } else if (numTokens >= 256 && numTokens < 512) {
      price = 100000000000000000;
    } else if (numTokens >= 512 && numTokens < 1024) {
      price = 200000000000000000;
    } else if (numTokens >= 1024 && numTokens < 1536) {
      price = 300000000000000000;
    } else {
      price = 400000000000000000;
    }
    return price;
  }

  function _mint(address to, uint256 _seed) internal returns (string memory) {
    require(hasSaleStarted == true, "Sale hasn't started");
    require(to != address(0), "ERC721: mint to the zero address");
    require(
      numTokens < TOKEN_LIMIT,
      "ERC721: maximum number of tokens already minted"
    );
    require(msg.value >= calculatePrice(), "ERC721: insufficient ether");

    uint256 seed = uint256(
      keccak256(abi.encodePacked(_seed, block.timestamp, msg.sender, numTokens))
    );

    require(seedToId[seed] == 0, "ERC721: seed already used");

    uint256 id = numTokens + 1;

    idToSeed[id] = seed;
    seedToId[seed] = id;

    string memory punk = AsciiPunkFactory.draw(idToSeed[id]);
    emit Generated(id, to, punk);

    numTokens = numTokens + 1;
    _registerToken(to, id);

    emit Transfer(address(0), to, id);

    return punk;
  }

  function _registerToken(address to, uint256 tokenId) internal {
    require(idToOwner[tokenId] == address(0));
    idToOwner[tokenId] = to;

    ownerToIds[to].push(tokenId);
    uint256 length = ownerToIds[to].length;
    idToOwnerIndex[tokenId] = length - 1;
  }

  function draw(uint256 tokenId)
    external
    view
    validNFToken(tokenId)
    returns (string memory)
  {
    string memory uri = AsciiPunkFactory.draw(idToSeed[tokenId]);
    return uri;
  }

  function totalSupply() public view returns (uint256) {
    return numTokens;
  }

  function tokenByIndex(uint256 index) public view returns (uint256) {
    require(index < numTokens, "ERC721Enumerable: global index out of bounds");
    return index;
  }

  function tokenOfOwnerByIndex(address owner, uint256 _index)
    external
    view
    returns (uint256)
  {
    require(
      _index < ownerToIds[owner].length,
      "ERC721Enumerable: owner index out of bounds"
    );
    return ownerToIds[owner][_index];
  }

  function balanceOf(address owner) external view returns (uint256) {
    require(owner != address(0), "ERC721: balance query for the zero address");
    return ownerToIds[owner].length;
  }

  function ownerOf(uint256 tokenId) external view returns (address) {
    return _ownerOf(tokenId);
  }

  function _ownerOf(uint256 tokenId)
    internal
    view
    validNFToken(tokenId)
    returns (address)
  {
    address owner = idToOwner[tokenId];
    require(owner != address(0), "ERC721: query for nonexistent token");
    return owner;
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external validNFToken(tokenId) canTransfer(tokenId) {
    address tokenOwner = idToOwner[tokenId];
    require(tokenOwner == from, "ERC721: transfer of token that is not own");
    require(to != address(0), "ERC721: transfer to the zero address");
    _transfer(to, tokenId);
  }

  function _transfer(address to, uint256 tokenId) internal {
    address from = idToOwner[tokenId];
    _clearApproval(tokenId);
    emit Approval(from, to, tokenId);

    _removeNFToken(from, tokenId);
    _registerToken(to, tokenId);

    emit Transfer(from, to, tokenId);
  }

  function _removeNFToken(address from, uint256 tokenId) internal {
    require(idToOwner[tokenId] == from);
    delete idToOwner[tokenId];

    uint256 tokenToRemoveIndex = idToOwnerIndex[tokenId];
    uint256 lastTokenIndex = ownerToIds[from].length - 1;

    if (lastTokenIndex != tokenToRemoveIndex) {
      uint256 lastToken = ownerToIds[from][lastTokenIndex];
      ownerToIds[from][tokenToRemoveIndex] = lastToken;
      idToOwnerIndex[lastToken] = tokenToRemoveIndex;
    }

    ownerToIds[from].pop();
  }

  function approve(address approved, uint256 tokenId)
    external
    validNFToken(tokenId)
    canOperate(tokenId)
  {
    address owner = idToOwner[tokenId];
    require(approved != owner, "ERC721: approval to current owner");
    idToApproval[tokenId] = approved;
    emit Approval(owner, approved, tokenId);
  }

  function _clearApproval(uint256 tokenId) private {
    if (idToApproval[tokenId] != address(0)) {
      delete idToApproval[tokenId];
    }
  }

  function getApproved(uint256 tokenId)
    external
    view
    validNFToken(tokenId)
    returns (address)
  {
    return idToApproval[tokenId];
  }

  function setApprovalForAll(address operator, bool approved) external {
    require(operator != _msgSender(), "ERC721: approve to caller");
    ownerToOperators[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  function isApprovedForAll(address owner, address operator)
    external
    view
    returns (bool)
  {
    return ownerToOperators[owner][operator];
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external {
    _safeTransferFrom(from, to, tokenId, data);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external {
    _safeTransferFrom(from, to, tokenId, "");
  }

  function _safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) private validNFToken(tokenId) canTransfer(tokenId) {
    address tokenOwner = idToOwner[tokenId];
    require(tokenOwner == from, "ERC721: transfer of token that is not own");
    require(to != address(0), "ERC721: transfer to the zero address");

    _transfer(to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, data),
      "ERC721: transfer to non ERC721Receiver implementer"
    );
  }

  function tokenURI(uint256 tokenId)
    external
    view
    validNFToken(tokenId)
    returns (string memory)
  {
    string memory uri = _baseURI();
    return
      bytes(uri).length > 0
        ? string(abi.encodePacked(uri, tokenId.toString()))
        : "";
  }

  function startSale() public onlyOwner {
    hasSaleStarted = true;
  }

  function pauseSale() public onlyOwner {
    hasSaleStarted = false;
  }

  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) private returns (bool) {
    if (to.isContract()) {
      try
        IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data)
      returns (bytes4 retval) {
        return retval == IERC721Receiver(to).onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721: transfer to non ERC721Receiver implementer");
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
  }
}