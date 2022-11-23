// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts-newone/token/ERC20/IERC20.sol";

interface ISyntERC20 is IERC20 {
    function mint(address account, uint256 amount) external;

    function mintWithAllowance(
        address account,
        address spender,
        uint256 amount
    ) external;

    function burnWithAllowanceDecrease(
        address account,
        address spender,
        uint256 amount
    ) external;

    function burn(address account, uint256 amount) external;

    function getChainId() external returns (uint256);
}