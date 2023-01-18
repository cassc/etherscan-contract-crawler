// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

// abstract contract BColor {
//     function getColor()
//         external view virtual
//         returns (bytes32);
// }

contract BBronze {
    function getColor() external pure returns (bytes32) {
        return bytes32("BRONZE");
    }
}