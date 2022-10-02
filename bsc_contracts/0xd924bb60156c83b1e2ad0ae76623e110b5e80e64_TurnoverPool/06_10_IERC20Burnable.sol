// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20Burnable is IERC20Upgradeable {
    function burn(uint256 _amount) external;

    function burnFrom(address _account, uint256 _amount) external;
}