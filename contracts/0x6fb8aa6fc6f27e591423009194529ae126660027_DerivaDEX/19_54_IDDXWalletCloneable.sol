// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import { IDDX } from "./IDDX.sol";

interface IDDXWalletCloneable {
    function initialize(
        address _trader,
        IDDX _ddxToken,
        address _derivaDEX
    ) external;
}