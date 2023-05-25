// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IPresaleAccessControlHandler is IERC165 {
  /// @dev Returns [true] if [sender] is able to mint the requested number of presale tokens.
  function verifyCanMintPresaleTokens(
    address minter,
    uint32 balance,
    uint64 presaleStart,
    uint64 presaleEnd,
    uint32 count,
    uint256 nonce,
    bytes calldata signature
  ) external view returns (bool, bytes memory);
}