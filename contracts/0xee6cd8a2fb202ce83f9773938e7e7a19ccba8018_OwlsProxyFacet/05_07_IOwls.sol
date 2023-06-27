// SPDX-License-Identifier: MIT

/*********************************
*                                *
*               0,0              *
*                                *
 *********************************/

pragma solidity ^0.8.13;

import { IOwlDescriptor } from "./IOwlDescriptor.sol";

interface IOwls {
    function setMinting(bool value) external;

    function setDescriptor(IOwlDescriptor newDescriptor) external;

    function withdraw() external payable;

    function updateSeed(uint256 tokenId, uint256 seed) external;

    function disableSeedUpdate() external;
}