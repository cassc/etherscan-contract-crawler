// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial lab archive interface required by controller functions
 */
interface ILabArchiveController {
    error UnexpectedCharacter(uint256 code);
    
    error UnexpectedWhitespaceString();
}