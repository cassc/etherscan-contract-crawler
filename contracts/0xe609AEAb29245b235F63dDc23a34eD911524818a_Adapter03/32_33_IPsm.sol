// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

interface IPsm {
    function sellGem(address usr, uint256 gemAmt) external;

    function buyGem(address usr, uint256 gemAmt) external;
}