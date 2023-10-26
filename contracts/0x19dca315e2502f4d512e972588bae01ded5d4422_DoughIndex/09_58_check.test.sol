// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Change {
    bool public status;

    function change(bool _status) public {
        status = _status;
    }
}

contract DoughCheck is Change {
    function isOk() external view returns (bool ok) {
        return status;
    }
}