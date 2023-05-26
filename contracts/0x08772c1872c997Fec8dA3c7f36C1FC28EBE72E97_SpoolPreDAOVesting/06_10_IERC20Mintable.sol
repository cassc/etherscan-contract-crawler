// SPDX-License-Identifier: MIT

import "../external/@openzeppelin/token/ERC20/IERC20.sol";

pragma solidity 0.8.11;

interface IERC20Mintable is IERC20 {
    function mint(address, uint256) external;

    function burn(address, uint256) external;
}