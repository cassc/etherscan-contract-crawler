// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface IOsqthController {
    function getDenormalizedMark(uint32 _period) external view returns (uint256);

    function getIndex(uint32 _period) external view returns (uint256);
}