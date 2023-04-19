// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@parallelmarkets/token/contracts/IParallelID.sol";
import "../interfaces/IAlloyxWhitelist.sol";
import "../config/AlloyxConfig.sol";
import "../config/ConfigHelper.sol";
import "./AdminUpgradeable.sol";

/**
 * @title AlloyxWhitelist
 * @notice Whitelist contract to determine if user can operate within the protocol
 * @author AlloyX
 */
contract AlloyxWhitelist is IAlloyxWhitelist, AdminUpgradeable {
  mapping(address => bool) private whitelistedAddresses;
  IERC1155 private uidToken;
  IParallelID private parallelID;
  AlloyxConfig public config;

  using ConfigHelper for AlloyxConfig;

  event ChangeAddress(string _field, address _address);

  /**
   * @notice Initialize the contract
   * @param _configAddress the address of configuration contract
   * @param _uidTokenAddress goldfinch UID token address
   * @param _parallelIdAddress parallel ID contract address
   */
  function initialize(
    address _configAddress,
    address _uidTokenAddress,
    address _parallelIdAddress
  ) external initializer {
    __AdminUpgradeable_init(msg.sender);
    config = AlloyxConfig(_configAddress);
    require(_uidTokenAddress != address(0));
    uidToken = IERC1155(_uidTokenAddress);
    require(_parallelIdAddress != address(0));
    parallelID = IParallelID(_parallelIdAddress);
  }

  /**
   * @notice If address is whitelisted
   * @param _address The address to verify.
   */
  modifier isWhitelisted(address _address) {
    require(isUserWhitelisted(_address), "You need to be whitelisted");
    _;
  }

  /**
   * @notice If address is not whitelisted
   * @param _address The address to verify.
   */
  modifier notWhitelisted(address _address) {
    require(!isUserWhitelisted(_address), "You are whitelisted");
    _;
  }

  /**
   * @notice If address is not whitelisted by goldfinch(non-US entity or non-US individual)
   * @param _userAddress The address to verify.
   */
  function hasWhitelistedUID(address _userAddress) public view returns (bool) {
    uint256 balanceForNonUsIndividual = uidToken.balanceOf(_userAddress, 0);
    uint256 balanceForNonUsEntity = uidToken.balanceOf(_userAddress, 4);
    return balanceForNonUsIndividual + balanceForNonUsEntity > 0;
  }

  /**
   * @notice  check to see if any are currently monitored and safe from sanctions
   * @param _subject The address to verify.
   */
  function isSanctionsSafe(address _subject) public view returns (bool) {
    for (uint256 i = 0; i < parallelID.balanceOf(_subject); i++) {
      uint256 tokenId = parallelID.tokenOfOwnerByIndex(_subject, i);
      if (parallelID.isSanctionsSafe(tokenId)) return true;
    }
    return false;
  }

  /**
   * @notice Add whitelist address
   * @param _addressToWhitelist The address to whitelist.
   */
  function addWhitelistedUser(address _addressToWhitelist) external onlyAdmin notWhitelisted(_addressToWhitelist) {
    require(_addressToWhitelist != address(0));
    whitelistedAddresses[_addressToWhitelist] = true;
  }

  /**
   * @notice Remove whitelist address
   * @param _addressToDeWhitelist The address to de-whitelist.
   */
  function removeWhitelistedUser(address _addressToDeWhitelist) external onlyAdmin isWhitelisted(_addressToDeWhitelist) {
    whitelistedAddresses[_addressToDeWhitelist] = false;
  }

  /**
   * @notice Check whether user is whitelisted
   * @param _address The address to whitelist.
   */
  function isUserWhitelisted(address _address) public view override returns (bool) {
    return whitelistedAddresses[_address] || hasWhitelistedUID(_address) || isSanctionsSafe(_address);
  }

  /**
   * @notice Change UID address
   * @param _uidAddress the address to change to
   */
  function changeUIDAddress(address _uidAddress) external onlyAdmin {
    require(_uidAddress != address(0));
    uidToken = IERC1155(_uidAddress);
    emit ChangeAddress("uidToken", _uidAddress);
  }

  /**
   * @notice Change ParallelID address
   * @param _pAddress the address to change to
   */
  function changeParallelIDAddress(address _pAddress) external onlyAdmin {
    require(_pAddress != address(0));
    parallelID = IParallelID(_pAddress);
    emit ChangeAddress("parallelID", _pAddress);
  }
}