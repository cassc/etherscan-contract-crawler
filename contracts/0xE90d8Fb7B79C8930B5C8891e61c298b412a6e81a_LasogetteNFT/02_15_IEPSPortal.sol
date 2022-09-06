// SPDX-License-Identifier: MIT
// EPS Contracts v2.0.0

pragma solidity 0.8.16;

/**
 *
 * @dev Interface for the EPS portal
 *
 */

/**
 *
 * @dev Returns the beneficiary of the `tokenId` token.
 *
 */
interface IEPSPortal {
  function beneficiaryOf(
    address tokenContract_,
    uint256 tokenId_,
    uint256 rightsIndex_
  ) external view returns (address beneficiary_);

  /**
   *
   * @dev Returns the beneficiary balance for a contract.
   *
   */
  function beneficiaryBalanceOf(
    address queryAddress_,
    address tokenContract_,
    uint256 rightsIndex_
  ) external view returns (uint256 balance_);

  /**
   *
   * @dev Returns the proxied address details (cold and delivery address) for a passed hot address
   *
   */
  function getAddresses(address _receivedAddress)
    external
    view
    returns (
      address cold,
      address delivery,
      bool isProxied
    );

  /**
   * @dev coldIsLive: Return if a cold wallet is live
   */
  function coldIsLive(address cold_) external view returns (bool);

  /**
   * @dev hotIsLive: Return if a hot wallet is live
   */
  function hotIsLive(address hot_) external view returns (bool);
}