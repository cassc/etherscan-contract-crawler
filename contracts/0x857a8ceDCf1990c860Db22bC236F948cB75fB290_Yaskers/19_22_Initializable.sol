// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Initializable {
    bool public inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}