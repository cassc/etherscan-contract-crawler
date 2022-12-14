pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

interface AMO__ITempleERC20Token {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
}