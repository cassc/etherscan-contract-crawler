// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IAirdropAcceptorFactory {
    function createAirdropAcceptor(address _to) external returns (address, uint256);
}