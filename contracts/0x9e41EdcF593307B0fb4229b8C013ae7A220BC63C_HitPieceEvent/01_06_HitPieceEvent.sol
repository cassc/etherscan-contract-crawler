// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../extensions/OwnableUpgradeable.sol";
import "../extensions/IHPEvent.sol";

// import "hardhat/console.sol";

contract HitPieceEvent is Initializable, OwnableUpgradeable, IHPEvent {

  event Minted(
    address to,
    address indexed nft,
    uint256 indexed tokenId,
    string trackId
  );

  event NftContractInitialized(
    address indexed nft
  );

  event TokenTransferred(
    address from,
    address to,
    address indexed nft,
    uint256 indexed tokenId
  );

  event SetApprovedForAll(
    address indexed nft,
    address indexed operator,
    bool approved
  );

  event Approved(
    address indexed nft,
    address indexed operator,
    uint256 tokenId
  );

  bool public enableSecurity;
  address public adminAddress;
  mapping(address => bool) internal _allowedContracts;

  function initialize() initializer public {
    __Ownable_init_unchained();
  }

  modifier eventSecurityCheck() { // Modifier
    require(enableSecurity == false || _allowedContracts[msg.sender], "Address not authorized");
    _;
  }

  function setEnableSecurity(bool enabled) external {
    require(msg.sender == owner() || msg.sender == adminAddress, "Only admin or owner can call this.");
    enableSecurity = enabled;
  }

  function setAdminAddress(address _adminAddress) external onlyOwner {
    adminAddress = _adminAddress;
  }

  function setAllowedContracts(address _contractAddress) external override {
    require(msg.sender == owner() || msg.sender == adminAddress || tx.origin == owner() || tx.origin == adminAddress, "Only admin or owner can call this.");
    _allowedContracts[_contractAddress] = true;
  }

  function isAllowedContract(address _contractAddress) public view returns(bool) {
    return _allowedContracts[_contractAddress];
  }

  function setInitialOwner(address newOwner) public {
    require(owner() == address(0), "Can only call this if owner is null");
    _transferOwnership(newOwner);
  }

  function emitMintEvent(
    address to,
    address nft,
    uint256 tokenId,
    string memory trackId
  ) external eventSecurityCheck override {
    emit Minted(to, nft, tokenId, trackId);
  }

  function emitNftContractInitialized(
    address nft
  ) external eventSecurityCheck override {
    emit NftContractInitialized(nft);
  }

  function emitTokenTransferred(
    address from,
    address to,
    address nft,
    uint256 tokenId
  ) external eventSecurityCheck override {
    emit TokenTransferred(from, to, nft, tokenId);
  }

  function emitSetApprovedForAll(
    address nft,
    address operator,
    bool approved
  ) external eventSecurityCheck override {
    emit SetApprovedForAll(nft, operator, approved);
  }

  function emitApproved(
    address nft,
    address operator,
    uint256 tokenId
  ) external eventSecurityCheck override {
    emit Approved(nft, operator, tokenId);
  }
}