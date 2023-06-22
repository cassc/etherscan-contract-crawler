// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC20Entity.sol";

interface IERC20EntityBurnable is IERC20Entity {
    function burn(uint256 amount) external;

    function burnFrom(uint256 entity, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}