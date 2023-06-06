// SPDX-License-Identifier: MIT
// Original Copyright 2021 convex-eth
// Original source: https://github.com/convex-eth/platform/blob/ebd46ca7f05cca679568f6bd98cea54e27bbdd32/contracts/contracts/interfaces/ICvx.sol
pragma solidity 0.6.12;

interface ITokenWrapper {
   function token() external view returns (address);
}