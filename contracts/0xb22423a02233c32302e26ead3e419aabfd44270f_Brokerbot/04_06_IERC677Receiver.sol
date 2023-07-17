// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Given that development on ERC 677 has stalled, we should consider supporting EIP 1363: https://eips.ethereum.org/EIPS/eip-1363
interface IERC677Receiver {
    
    function onTokenTransfer(address from, uint256 amount, bytes calldata data) external returns (bool);

}