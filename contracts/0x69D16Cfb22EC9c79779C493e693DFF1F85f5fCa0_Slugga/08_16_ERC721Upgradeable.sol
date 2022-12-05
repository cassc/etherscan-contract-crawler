// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Slugga is ERC721AUpgradeable, AccessControl, DefaultOperatorFilterer {
  using Strings for uint256;

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  uint256 public mintId;
  string public contractURI;
  string public baseTokenURI;
  string public baseTokenURIUnrevealed;
  address public ownerAddress;

  uint256 public max;

  modifier onlyMinter() {
    require(hasRole(MINTER_ROLE, msg.sender), "Must have minter role.");
    _;
  }
  modifier onlyOwner() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Must have admin role.");
    _;
  }

  /// @param _name the name of the token
  /// @param _symbol the token symbol
  /// @param _contractURI the contract URI
  /// @param _baseTokenURI the base URI for computing the tokenURI
  /// @param _max supply
  function initialize(
    string memory _name,
    string memory _symbol,
    string memory _contractURI,
    string memory _baseTokenURI,
    uint256 _max
  ) public initializerERC721A {
    __ERC721A_init(_name, _symbol);
    contractURI = _contractURI;
    baseTokenURI = _baseTokenURI;
    max = _max;
    ownerAddress = msg.sender;
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MINTER_ROLE, msg.sender);
    _mint(msg.sender, 1);
    mintId = 1;
  }

  function mint(address _to, uint256 _quantity) public onlyMinter {
    require(mintId + _quantity <= max + 1, "max supply reached");
    mintId = mintId + _quantity;
    _mint(_to, _quantity);
  }

  function mintDirect(address _to, uint256 _quantity) public onlyOwner {
    require(mintId + _quantity <= max + 1, "max supply reached");
    mintId = mintId + _quantity;
    _mint(_to, _quantity);
  }

  function burn(uint256 tokenId) public {
    require(ownerOf(tokenId) == msg.sender, "Must be owner of token");
    _burn(tokenId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
  }

  function setMaxQuantity(uint256 _quantity) public onlyOwner {
    max = _quantity;
  }

  function setContractURI(string memory _contractURI) public onlyOwner {
    contractURI = _contractURI;
  }

  function setBaseURI(string memory _baseTokenURI) public onlyOwner {
    baseTokenURI = _baseTokenURI;
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

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(AccessControl, ERC721AUpgradeable)
    returns (bool)
  {
    return
      super.supportsInterface(interfaceId) ||
      ERC721AUpgradeable.supportsInterface(interfaceId);
  }
}