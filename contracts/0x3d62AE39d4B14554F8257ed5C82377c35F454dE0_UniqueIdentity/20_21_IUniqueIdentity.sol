// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IUniqueIdentity is IERC1155Upgradeable {
  /// @notice Mint a new UniqueIdentity token to the msgSender
  /// @param id The id representing the KYC type of the UniqueIdentity
  /// @param expiresAt The expiration time of the signature
  /// @param signature An EIP-191 signature of the corresponding mint params:
  ///                  account, id, expiresAt, address(this), nonces[account], block.chainid
  ///                  from an address with the SIGNER_ROLE.
  function mint(uint256 id, uint256 expiresAt, bytes calldata signature) external payable;

  /// @notice Mint a new UniqueIdentity token to the `recipient`
  /// @param recipient The recipient address to be minted to.
  /// @param id The id representing the KYC type of the UniqueIdentity
  /// @param expiresAt The expiration time of the signature
  /// @param signature An EIP-191 signature of the corresponding mintTo params:
  ///                  (account, recipient, id, expiresAt, address(this), nonces[account], block.chainid)
  ///                  from an address with the SIGNER_ROLE.
  function mintTo(
    address recipient,
    uint256 id,
    uint256 expiresAt,
    bytes calldata signature
  ) external payable;

  /// @notice Burn a UniqueIdentity token of `id` from the `account`
  /// @param account The account which currently owns the UID
  /// @param id The id representing the KYC type of the UniqueIdentity
  /// @param expiresAt The expiration time of the signature
  /// @param signature An EIP-191 signature of the corresponding burn params:
  ///                  (account, id, expiresAt, address(this), nonces[account], block.chainid)
  ///                  from an address with the SIGNER_ROLE.
  function burn(address account, uint256 id, uint256 expiresAt, bytes calldata signature) external;
}