// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./_external/IERC20Metadata.sol";

interface ICappedGovToken is IERC20Metadata {
    function _underlying() external view returns (IERC20Metadata _underlying);

    function deposit(uint256 amount, uint96 vaultId) external;
}