// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

interface IBProtocolAMM {
    function swap(
        uint256 lusdAmount,
        uint256 minEthReturn,
        address payable dest
    ) external returns (uint256);
}