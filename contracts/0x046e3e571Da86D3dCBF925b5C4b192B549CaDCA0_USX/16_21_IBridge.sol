// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

// Generic bridge interface
interface IBridge {
    function sendMessage(address payable _from, uint16 _dstChainId, bytes memory _toAddress, uint256 _amount)
        external
        payable
        returns (uint64 sequence);
}