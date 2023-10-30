// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";

interface IToken is IERC20Upgradeable {
    function burnFrom(address account, uint256 amount) external;

    function mint(address to, uint256 amount) external;

    function decimals() external view returns (uint8);
}