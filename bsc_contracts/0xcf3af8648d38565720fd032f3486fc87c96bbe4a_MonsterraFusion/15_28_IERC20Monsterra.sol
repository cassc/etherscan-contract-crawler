// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";


pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Monsterra is IERC20Upgradeable{

    function burn(uint256 amount) external;
    function burnFrom(uint256 amount, address _address) external;
}