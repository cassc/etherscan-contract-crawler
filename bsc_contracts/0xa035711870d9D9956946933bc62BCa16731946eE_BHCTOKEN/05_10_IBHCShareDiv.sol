// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IBHCShareDiv {
    function getTokensDividends(address user)
        external
        view
        returns (
            uint256 total,
            uint256 withdrawn,
            uint256 withdrawable
        );

    function addUser(address user, uint256 value) external;

    function claim(address user) external;

    function distributeDividends(uint256 amount) external;
}
