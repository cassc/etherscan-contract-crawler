// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../Library/StringHelper.sol";

contract TestStringHelper
{
    function getBytes(string memory str) public pure returns (bytes32) { return StringHelper.toBytes32(str); }
    function getString(bytes32 data) public pure returns (string memory) { return StringHelper.toString(data); }
}