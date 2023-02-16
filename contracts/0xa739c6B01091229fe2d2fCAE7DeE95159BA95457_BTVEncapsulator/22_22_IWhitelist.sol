//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ICallable
 * @author [email protected]
 */
abstract contract IWhitelist {
    function hasAccess(address addr) external virtual returns (bool access);
}