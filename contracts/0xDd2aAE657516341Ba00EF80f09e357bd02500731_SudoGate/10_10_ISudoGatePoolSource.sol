// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.16;

interface ISudoGatePoolSource {
    // base interface that just tracks a collection of SudoSwap pools 
    function pools(address, uint256) external view returns (address);
    function knownPool(address) external view returns (bool);
    function registerPool(address sudoswapPool) external returns (bool);
}