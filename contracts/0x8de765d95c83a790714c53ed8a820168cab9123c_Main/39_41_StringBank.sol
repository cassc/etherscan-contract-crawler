// SPDX-License-Identifier: CC0-1.0

// solhint-disable no-global-import

pragma solidity ^0.8.19;

import "./IStringBank.sol";

contract StringBank is IStringBank {    
    mapping(uint256 => bytes) private strings;

    function addString(uint256 index, bytes memory value) internal {
        strings[index] = value;
    }

    function getString(uint256 index) external view returns (bytes memory value) {
        value = strings[index];
    }
}