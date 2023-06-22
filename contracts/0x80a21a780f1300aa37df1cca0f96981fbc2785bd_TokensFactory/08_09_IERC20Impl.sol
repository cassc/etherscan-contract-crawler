// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20Impl is IERC20Upgradeable{
    function __ERC20Impl_init(
        string memory name,
        string memory symbol,
        uint8 tokenDecimals,
        address owner
    ) external;
}