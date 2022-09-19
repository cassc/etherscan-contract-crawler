// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./utils/MinterAccessControl.sol";

/** @title The ERC1155 contract of Highstreet Asset */
contract HighstreetAssets is Context, ERC1155Burnable, ERC1155Supply, Ownable, MinterAccessControl {

  using Strings for uint256;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  /// @dev a string of base uri for this nft
  string private _baseUri;

  mapping(uint256 => uint256) private _maxSupply;

  event SetMaxSupply(uint256 indexed id, uint256 amount);

  /**
    * @dev Fired in updateBaseUri()
    *
    * @param sender an address which performed an operation, usually contract owner
    * @param uri a stringof base uri for this nft
    */
  event UpdateBaseUri(address indexed sender, string uri);


  constructor(string memory name_, string memory symbol_, string memory url_) ERC1155(url_) {
    _name = name_;
    _symbol = symbol_;
    _baseUri = url_;
  }

  function name() public view virtual returns (string memory) {
    return _name;
  }

  function symbol() public view virtual returns (string memory) {
    return _symbol;
  }

  function decimals() public view virtual returns (uint8) {
    return 0;
  }

  /**
    * @notice Creates `amount` tokens of token type `id`, and assigns them to `to`.
    *
    * @dev this function can only be called by minter
    *
    * @param to_ an address which received nft
    * @param id_ a number of id expected to mint
    * @param amount_ a number of amount of token be minted
    */
  function mint(
    address to_,
    uint256 id_,
    uint256 amount_,
    bytes memory data_
  ) public virtual onlyMinter {
    _mint(to_, id_, amount_, data_);
  }

  /**
    * @notice Creates `amount` tokens of token type `id`, and assigns them to `to`.
    *
    * @dev this function can only be called by minter
    * @dev `ids` and `amounts` must have the same length.
    *
    * @param to_ an address which received nft
    * @param ids_ a number of id expected to mint
    * @param amounts_ a number of amount of token be minted
    */
  function mintBatch(
    address to_,
    uint256[] memory ids_,
    uint256[] memory amounts_,
    bytes memory data_
  ) public virtual onlyMinter {
    _mintBatch(to_, ids_, amounts_, data_);
  }

  /**
    * @dev Hook that is called before any token transfer. This includes minting
    * and burning.
    *
    * @dev Additionally to the parent smart contract, restrict this contract can not be receiver.
    */
  function _beforeTokenTransfer(
      address operator_,
      address from_,
      address to_,
      uint256[] memory ids_,
      uint256[] memory amounts_,
      bytes memory data_
  ) internal virtual override(ERC1155, ERC1155Supply) {
    require(to_ != address(this), "this contract cannot be receiver");

    if (from_ == address(0)) {
      for (uint256 i = 0; i < ids_.length; ++i) {
        uint256 id = ids_[i];
        if(isLimited(id)) {
          require(totalSupply(id) + amounts_[i] <= maxSupply(id), "exceed max amount");
        }
      }
    }

    super._beforeTokenTransfer(operator_, from_, to_, ids_, amounts_, data_);
  }

  /**
    * @notice Check whether the token id has maximum supply or not.
    *
    * @param id_ a number of id expected to check
    * @return the boolean result
    */
  function isLimited(uint256 id_) public view virtual returns (bool) {
    return _maxSupply[id_] > 0;
  }

  /**
    * @notice Query the maximum supply of specified token id
    *
    * @param id_ a number of id expected to check
    * @return the value of maximum supply 
    */
  function maxSupply(uint256 id_) public view virtual returns (uint256) {
    return _maxSupply[id_];
  }

  /**
    * @notice Set the maximum supply of specified token id
    *
    * @dev this function can only be called by minter
    * @param id_ a number of id expected to set
    * @param amount_ the amount of maximum supply
    */
  function setMaxSupply(uint256 id_, uint256 amount_) external virtual onlyMinter {
    require(amount_ >= totalSupply(id_), "invalid amount");
    _maxSupply[id_] = amount_;
    emit SetMaxSupply(id_, amount_);
  }

  /**
    * @dev  See {IERC1155MetadataURI-uri}.
    * @dev Additionally to the parent smart contract, return string of uri based on id
    */
  function uri(uint256 id_) public view virtual override returns (string memory) {
    require(exists(id_), "URI query for nonexistent token");
    return bytes(_baseUri).length > 0 ? string(abi.encodePacked(_baseUri, id_.toString())) : "";
  }

  /**
    * @notice Service function to update base uri
    *
    * @dev this function can only be called by owner
    *
    * @param uri_ a string for updating base uri
    */
  function updateBaseUri(string memory uri_) public virtual onlyOwner {
    _baseUri = uri_;
    emit UpdateBaseUri(_msgSender(), uri_);
  }

  /**
    * @dev  See {MinterAccessControl-_grantMinterRole}.
    *
    */
  function grantMinterRole(address addr_) external virtual onlyOwner {
    super._grantMinterRole(addr_);
  }

  /**
    * @dev  See {MinterAccessControl-_revokeMinterRole}.
    *
    */
  function revokeMinterRole(address addr_) external virtual onlyOwner {
    super._revokeMinterRole(addr_);
  }
}