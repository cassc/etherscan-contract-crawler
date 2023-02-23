// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IHATVaultsV2 {
    function hatVaults(uint256 _pid) external view returns (IERC20 hatVault);
}