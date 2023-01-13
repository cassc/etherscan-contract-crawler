// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.9;

contract Initializable {
    bool inited;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}