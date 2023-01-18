// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface ISafeHook is IERC165Upgradeable {
    function executeHook(address from, address to, uint256 tokenId) external returns(bool success);
}