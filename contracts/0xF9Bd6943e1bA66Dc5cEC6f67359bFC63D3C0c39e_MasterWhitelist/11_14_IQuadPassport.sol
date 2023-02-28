// SPDX-License-Identifier: MIT
//slither-disable-next-line solc-version
pragma solidity =0.8.14;

interface IQuadPassport {
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);
}