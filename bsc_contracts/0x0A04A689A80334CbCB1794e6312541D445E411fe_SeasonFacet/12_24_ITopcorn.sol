/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity = 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title TopCorn Interface
 **/
abstract contract ITopcorn is IERC20 {
    function burn(uint256 amount) public virtual;

    function burnFrom(address account, uint256 amount) public virtual;

    function mint(address account, uint256 amount) public virtual returns (bool);
}