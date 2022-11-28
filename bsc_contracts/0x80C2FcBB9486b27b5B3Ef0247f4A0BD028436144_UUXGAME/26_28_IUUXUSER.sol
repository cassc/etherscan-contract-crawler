// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract IUUXUSER is AccessControlEnumerable, Pausable {
    /**
     * @dev Decrease Balance
     */
    function addAsset(address owner, bytes memory name, uint256 amount,address addr,uint256 types,uint256 level) external virtual;
    /**
     * @dev Decrease Balance
     */
    function _addAsset(address owner, bytes memory name, uint256 amount) internal virtual;
     /**
     * @dev Decrease Balance
     */
    function subAsset(address owner, bytes memory name, uint256 amount,address addr,uint256 types,uint256 level) external virtual;
     /**
     * @dev Decrease Balance
     */
    function _subAsset(address owner, bytes memory name, uint256 amount) internal virtual;
     /**
     * @dev Decrease Balance
     */
    function getUserBalance(address owner, uint256 types) external virtual returns(uint256);
     /**
     * @dev Decrease Balance
     */
    function _getUserBalance(address owner, uint256 types) internal virtual returns(uint256);
}