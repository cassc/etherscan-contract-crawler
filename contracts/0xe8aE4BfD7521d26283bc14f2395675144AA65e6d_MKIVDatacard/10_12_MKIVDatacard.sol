// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./Single1155.sol";

// solhint-disable no-empty-blocks
contract MKIVDatacard is Single1155 {
    constructor()
        Single1155(
            "",
            50000000000000000, // 0.05 ETH
            4,
            2250
        )
    {}
}