// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IABCMintable {
    function mint(address to) external;
    function batchMint(address[] memory recipients) external;
}