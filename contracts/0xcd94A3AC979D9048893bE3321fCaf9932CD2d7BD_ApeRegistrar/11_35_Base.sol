// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Interface.sol";
import "../common/StandardNFT.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BaseZone is ZoneInterface, StandardNFT {
  using SafeMath for uint256;

  bytes32 private _origin;

  constructor(
    address admin,
    bytes32 origin,
    string memory name,
    string memory symbol
  ) ERC721(name, symbol) EIP712MetaTransaction(name) {
    _origin = origin;
    _safeMint(admin, uint256(origin));
    emit ZoneCreated(origin, name, symbol);
  }

  function getOrigin() public view override returns (bytes32) {
    return _origin;
  }

  function owner() public view virtual override returns (address) {
    return ownerOf(uint256(_origin));
  }

  modifier onlyOwner() {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function exists(bytes32 namehash)
    external
    view
    virtual
    override
    returns (bool)
  {
    return _exists(uint256(namehash));
  }

  function register(
    address to,
    bytes32 parent,
    string memory label
  ) public virtual override returns (bytes32 namehash) {
    require(
      _isApprovedOrOwner(_msgSender(), uint256(parent)),
      "must own parent"
    );
    require(_isValidLabel(bytes(label)), "invalid label");

    namehash = keccak256(abi.encodePacked(parent, keccak256(bytes(label))));
    _safeMint(to, uint256(namehash));

    emit ResourceRegistered(parent, label);
  }

  function _isValidLabel(bytes memory label)
    internal
    view
    virtual
    returns (bool valid)
  {
    require(label.length > 0, "must include a label");

    valid = true;

    for (uint256 i = 0; i < label.length; i++) {
      uint8 char = uint8(label[i]);
      valid =
        valid &&
        (char == 45 ||
          (char >= 48 && char <= 57) ||
          (char >= 97 && char <= 122));
    }
  }

  function _msgSender()
    internal
    view
    virtual
    override
    returns (address sender)
  {
    return EIP712MetaTransaction.msgSender();
  }
}