// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface INiftyRegistry {
   function isValidNiftySender(address sendingKey) external view returns (bool);
}