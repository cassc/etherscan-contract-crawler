// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@openzeppelin/contracts/interfaces/IERC20.sol';

interface IAvastarsReplicantToken is IERC20 {
    function burnArt(uint256 artToBurn) external;
}