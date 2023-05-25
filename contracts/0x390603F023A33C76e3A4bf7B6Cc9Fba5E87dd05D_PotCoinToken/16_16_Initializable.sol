// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;


contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}