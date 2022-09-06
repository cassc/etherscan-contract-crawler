// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface DaiInterface is IERC20Upgradeable {
    // --- Approve by signature ---
  function permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) external;
  function transferFrom(address src, address dst, uint wad) external override returns (bool);
}