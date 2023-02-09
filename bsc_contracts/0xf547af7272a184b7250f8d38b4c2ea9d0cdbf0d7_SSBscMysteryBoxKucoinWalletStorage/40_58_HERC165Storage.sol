// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./HERC165Layout.sol";

//this is a leaf module
contract HERC165Storage is HERC165Layout {

    constructor () {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }
}