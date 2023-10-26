//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/utils/SafeCast.sol";

library Int128 {
    using SafeCast for uint256;
    using SafeCast for int256;

    function toInt128(uint256 val) internal pure returns (int128) {
        return val.toInt256().toInt128();
    }
}