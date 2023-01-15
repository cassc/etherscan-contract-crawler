// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol";

import "contracts/sbinft/market/v1/library/AuctionDomain.sol";

/**
 * @title SBINFT Platform Registry
 */
interface IPlatformRegistry is IERC165Upgradeable {
  /**
   * @dev Update to new PlatformFeeRateLowerLimit
   *
   * @param _new new PlatformFeeRateLowerLimit
   */
  function updatePlatformFeeLowerLimit(uint16 _new) external;

  /**
   * @dev Update to new PlatformFeeReceiver
   *
   * @param _new new PlatformFeeReceiver
   */
  function updatePlatformFeeReceiver(address payable _new) external;

  /**
   * @dev Update to new PartnerFeeReceiver for partner's collection
   *
   * @param collection partner's collection
   * @param partnerFeeReceiver new partner's FeeReceiver
   * @param sign bytes calldata signature of platform signer
   */
  function updatePartnerFeeReceiver(
    address collection,
    address payable partnerFeeReceiver,
    bytes calldata sign
  ) external;

  /**
   * @dev Checks if partner fee receiver
   *
   * @param _collection address of token
   * @param _partnerFeeReceiver address of partner FeeReceiver
   *
   * Requirements:
   * - _collection must be a non zero address
   * - _partnerFeeReceiver must be a non zero address
   */
  function isPartnerFeeReceiver(
    address _collection,
    address _partnerFeeReceiver
  ) external view returns (bool);

  /**
   * @dev Checks state of a Whitelisted token
   *
   * @param _token address of token
   */
  function isWhitelistedERC20(address _token) external view returns (bool);

  /**
   * @dev Adds list of token to Whitelisted, if zero address then will be ignored
   *
   * @param _addTokenList array of address of token to add
   */
  function addToERC20Whitelist(address[] calldata _addTokenList) external;

  /**
   * @dev Removes list of token from Whitelisted
   *
   * @param _tokenList array of address of token to remove
   */
  function removeFromERC20Whitelist(address[] calldata _tokenList) external;

  /**
   * @dev Checks state of a Whitelisted token
   *
   * @param _signer address of token
   */
  function isPlatformSigner(address _signer) external view returns (bool);

  /**
   * @dev Adds list of token to Whitelisted, if zero address then will be ignored
   *
   * @param _platformSignerList array of platfomr signer address  to add
   */
  function addPlatformSigner(address[] calldata _platformSignerList) external;

  /**
   * @dev Removes list of platform signers address
   *
   * @param _list array of platfomr signer address to remove
   */
  function removePlatformSigner(address[] calldata _list) external;

  /**
   * @dev Returns PlatformFeeReceiver
   */
  function getPlatformFeeReceiver() external returns (address payable);

  /**
   * @dev Returns PartnerFeeReceiver
   *
   * @param _token address of partner token
   */
  function getPartnerFeeReceiver(
    address _token
  ) external returns (address payable);

  /**
   * @dev Returns PlatformFeeReceiver
   *
   */
  function getPlatformFeeRateLowerLimit() external returns (uint16);

  /**
   * @dev Update to new PartnerPfFeeReceiver for partner's platformSigner
   *
   * @param _externalPlatformToken address of external Platform Token
   * @param _partnerPfFeeReceiver address new partner's platformer FeeReceiver
   *
   * Requirements:
   * - _platformSigner must be a non zero address
   * - _partnerPfFeeReceiver must be a non zero address
   *
   * Emits a {ExternalPfFeeReceiverUpdated} event
   */
  function updateExternalPlatformFeeReceiver(
    address _externalPlatformToken,
    address payable _partnerPfFeeReceiver
  ) external;

  /**
   * @dev Returns ExternalPlatformFeeReceiver
   *
   * @param _token address of external platform token
   */
  function getExternalPlatformFeeReceiver(
    address _token
  ) external returns (address payable);

  /**
   * @dev Check validity of arguments when called CreateAuction
   *
   * @param _auction auction info
   *
   */
  function checkParametaForAuctionCreate(
    AuctionDomain.Auction calldata _auction
  ) external;
}