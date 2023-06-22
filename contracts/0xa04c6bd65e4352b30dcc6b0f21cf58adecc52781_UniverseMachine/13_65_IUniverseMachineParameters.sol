// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

import "./Parameters.sol";

interface IUniverseMachineParameters is IERC165 {

    function getUniverse(uint8 index) external view returns (uint8[4] memory universe);

    function getParameters(uint256 tokenId, int32 seed)
        external
        view
        returns (Parameters memory parameters);
}