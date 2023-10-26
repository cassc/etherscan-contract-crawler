// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev Interface for a permittable ERC721 contract
 * See https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC72 allowance (see {IERC721-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC721-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IWrappedPunks is IERC721 {
  /**
   * @dev Gets address of cryptopunk smart contract
   */
  function punkContract() external view returns (address);

  /**
   * @dev Mints a wrapped punk
   * @param punkIndex the punk index of the punk to be minted
   */
  function mint(uint256 punkIndex) external;

  /**
   * @dev Burns a specific wrapped punk
   * @param punkIndex the punk index of the punk to be minted
   */
  function burn(uint256 punkIndex) external;

  /**
   * @dev Registers proxy
   */
  function registerProxy() external;

  /**
   * @dev Gets the proxy address
   * @param user the user address
   */
  function proxyInfo(address user) external returns (address proxy);
}