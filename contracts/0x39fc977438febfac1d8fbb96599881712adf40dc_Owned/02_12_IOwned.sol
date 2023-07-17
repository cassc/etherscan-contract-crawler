// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

/**
 * @dev Required interface of an Owned compliant contract.
 */
interface IOwned {
  event Lend(address owner, address to, uint tokenId, uint expire);
  event Claim(address owner, address from, uint tokenId);
  event ReturnToken(address holder, address to, uint tokenId);
  event Mint(address from, address to, uint tokenId);

  /**
   * @dev Returns the ``owner``, ``holder`` and ``expire`` (lending expiration) for a ``tokenId``.
   */
  function tokenInfo(uint tokenId) external view returns (address owner, address holder, uint expire);

  /**
   * @dev Lend ``tokenId`` to ``to`` address until lending ``expire``s.
   * When ``expire`` is set to ``0`` the owner can claim the token any time, otherwise they have to wait until expiration.
   *
   * Requirements:
   * - Caller must be an admin or approved operator.
   * - Owner is holder of the token or ``expire`` is ``0``.
   *
   * Emits a {ERC721.Transfer} event.
   * Emits a {IOwned.Lend} event.
   */
  function lend(address to, uint tokenId, uint expire) external;

  /**
   * @dev Owner can use this method to claim ``tokenId`` back.
   *
   * Requirements:
   * - Token was lent with ``expire`` set to ``0`` or lending has expired i.e. ``block.timestamp`` > ``expire``.
   *
   * Emits a {ERC721.Transfer} event.
   * Emits a {IOwned.Claim} event.
   */
  function claim(uint tokenId) external;

  /**
   * @dev Holder can return ``tokenId`` to Owner any time.
   *
   * Requirements:
   * - Token held by caller.
   *
   * Emits a {ERC721.Transfer} event.
   * Emits a {IOwned.ReturnToken} event.
   */
  function returnToken(uint tokenId) external;

  /**
   * @dev Mint ``tokenId`` to ``to`` address.
   *
   * Requirements:
   * - caller must be an admin.
   * - ``tokenId`` must not exist.
   *
   * Emits a {ERC721.Transfer} event.
   * Emits a {IOwned.Mint} event.
   */
  function mint(address to, uint tokenId) external;

  /**
   * @dev Burn ``tokenId``.
   *
   * Requirements:
   * - caller must be the token owner and holder.
   * - ``tokenId`` must exist.
   *
   * Emits a {ERC721.Transfer} event.
   */
  function burn(uint tokenId) external;

  /**
   * @dev Returns total tokens supply.
   */
  function supply() external view returns (uint);
}