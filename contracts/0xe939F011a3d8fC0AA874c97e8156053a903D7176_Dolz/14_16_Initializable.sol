// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

contract Initializable {
    bool inited;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}