// SPDX-License-Identifier: MIT
//* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//* IEPS_DR: EPS Delegate Regsiter Interface
//* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// EPS Contracts v2.0.0

pragma solidity ^0.8.17;

/**
 *
 * @dev Interface for the EPS portal
 *
 */

/**
 * @dev Returns the beneficiary of the `tokenId` token.
 */
interface IEPS_DR {
  function beneficiaryOf(
    address tokenContract_,
    uint256 tokenId_,
    uint256 rightsIndex_
  ) external view returns (address beneficiary_);

  /**
   * @dev Returns the beneficiary balance for a contract.
   */
  function beneficiaryBalanceOf(
    address queryAddress_,
    address tokenContract_,
    uint256 rightsIndex_
  ) external view returns (uint256 balance_);

  /**
   * @dev beneficiaryBalance: Returns the beneficiary balance of ETH.
   */
  function beneficiaryBalance(address queryAddress_)
    external
    view
    returns (uint256 balance_);

  /**
   * @dev beneficiaryBalanceOf1155: Returns the beneficiary balance for an ERC1155.
   */
  function beneficiaryBalanceOf1155(
    address queryAddress_,
    address tokenContract_,
    uint256 id_
  ) external view returns (uint256 balance_);

  function getAddresses(address receivedAddress_, uint256 rightsIndex_)
    external
    view
    returns (address[] memory proxyAddresses_, address delivery_);

  function getAddresses1155(address receivedAddress_, uint256 rightsIndex_)
    external
    view
    returns (address[] memory proxyAddresses_, address delivery_);

  function getAddresses20(address receivedAddress_, uint256 rightsIndex_)
    external
    view
    returns (address[] memory proxyAddresses_, address delivery_);

  function getAllAddresses(address receivedAddress_, uint256 rightsIndex_)
    external
    view
    returns (address[] memory proxyAddresses_, address delivery_);

  /**
   * @dev coldIsLive: Return if a cold wallet is live
   */
  function coldIsLive(address cold_) external view returns (bool);

  /**
   * @dev hotIsLive: Return if a hot wallet is live
   */
  function hotIsLive(address hot_) external view returns (bool);
}