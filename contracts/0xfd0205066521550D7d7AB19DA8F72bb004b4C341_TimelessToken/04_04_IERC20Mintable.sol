// SPDX-License-Identifier: AGPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IERC20Mintable {
    function mint(address to, uint256 amount) external;
}