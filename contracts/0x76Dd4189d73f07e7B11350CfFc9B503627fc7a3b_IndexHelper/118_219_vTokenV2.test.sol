// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "../vToken.sol";

contract vTokenV2Test is vToken {
    function test() external pure returns (string memory) {
        return "Success";
    }
}