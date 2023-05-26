// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

interface IMintableToken {

    function mint(
        address to,
        uint256 value
    )
        external;

    function burn(
        address to,
        uint256 value
    )
        external;

}