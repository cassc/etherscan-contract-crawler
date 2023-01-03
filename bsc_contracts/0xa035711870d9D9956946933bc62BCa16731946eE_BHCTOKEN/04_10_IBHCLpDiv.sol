// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IBHCLpDiv {
    function distributeDividends(uint256 amount) external;

    function process()
        external
        returns (
            uint256,
            uint256,
            uint256
        );
}
