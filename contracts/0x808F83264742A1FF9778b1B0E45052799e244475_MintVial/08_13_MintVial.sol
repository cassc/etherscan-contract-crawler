// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract MintVial is ERC721A, AccessControl, DefaultOperatorFilterer {
  using Strings for uint256;

  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  uint256 public mintId;
  string public contractURI;
  string public baseTokenURI;
  address public ownerAddress;

  uint256 public max;

  modifier onlyMinter() {
    require(hasRole(MINTER_ROLE, msg.sender), "Must have minter role.");
    _;
  }
  modifier onlyBurner() {
    require(hasRole(BURNER_ROLE, msg.sender), "Must have burner role.");
    _;
  }
  modifier onlyOwner() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Must have admin role.");
    _;
  }

  /// @notice Constructor for the ONFT
  /// @param _name the name of the token
  /// @param _symbol the token symbol
  /// @param _contractURI the contract URI
  /// @param _baseTokenURI the base URI for computing the tokenURI
  constructor(
    string memory _name,
    string memory _symbol,
    string memory _contractURI,
    string memory _baseTokenURI
  ) ERC721A(_name, _symbol) {
    contractURI = _contractURI;
    baseTokenURI = _baseTokenURI;
    max = 3333;
    mintId = 167;

    ownerAddress = msg.sender;
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(BURNER_ROLE, msg.sender);
    _setupRole(MINTER_ROLE, msg.sender);
    _mint(msg.sender, 167);
  }

  function mint(address _to, uint256 _quantity) public onlyMinter {
    require(mintId + _quantity <= max + 1, "max supply reached");
    mintId = mintId + _quantity;
    _mint(_to, _quantity);
  }

  function burn(uint256 tokenId) public virtual onlyBurner {
    _burn(tokenId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    return baseTokenURI;
  }

  function setContractURI(string memory _contractURI) public onlyOwner {
    contractURI = _contractURI;
  }

  function setMaxQuantity(uint256 _quantity) public onlyOwner {
    max = _quantity;
  }

  function setBaseURI(string memory _baseTokenURI) public onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  function owner() external view returns (address) {
    return ownerAddress;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(AccessControl, ERC721A)
    returns (bool)
  {
    return
      super.supportsInterface(interfaceId) ||
      ERC721A.supportsInterface(interfaceId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}