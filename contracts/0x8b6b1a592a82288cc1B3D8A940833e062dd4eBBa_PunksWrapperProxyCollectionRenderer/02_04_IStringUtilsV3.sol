// SPDX-License-Identifier: UNLICENSED
/// @title IStringUtilsV3
/// @notice IStringUtilsV3
/// @author CyberPnk <[email protected]>
//        __________________________________________________________________________________________________________
//       _____/\/\/\/\/\______________/\/\________________________________/\/\/\/\/\________________/\/\___________
//      ___/\/\__________/\/\__/\/\__/\/\__________/\/\/\____/\/\__/\/\__/\/\____/\/\__/\/\/\/\____/\/\__/\/\_____
//     ___/\/\__________/\/\__/\/\__/\/\/\/\____/\/\/\/\/\__/\/\/\/\____/\/\/\/\/\____/\/\__/\/\__/\/\/\/\_______
//    ___/\/\____________/\/\/\/\__/\/\__/\/\__/\/\________/\/\________/\/\__________/\/\__/\/\__/\/\/\/\_______
//   _____/\/\/\/\/\________/\/\__/\/\/\/\______/\/\/\/\__/\/\________/\/\__________/\/\__/\/\__/\/\__/\/\_____
//  __________________/\/\/\/\________________________________________________________________________________
// __________________________________________________________________________________________________________

import "./IStringUtilsV2.sol";

pragma solidity ^0.8.13;

interface IStringUtilsV3 is IStringUtilsV2 {
    function base64Decode(bytes memory data) external pure returns (bytes memory);
    function extractFromTo(string memory str, string memory needleStart, string memory needleEnd) external pure returns(string memory);
    function extractFrom(string memory str, string memory needleStart) external pure returns(string memory);
    function removeSuffix(string memory str, string memory suffix) external pure returns(string memory);
    function removePrefix(string memory str, string memory prefix) external pure returns(string memory);
}