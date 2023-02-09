// SPDX-License-Identifier: WISE

pragma solidity ^0.8.17;

contract Events {

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}
