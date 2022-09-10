// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "./BaseController.sol";
import "../interfaces/IWETH.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract WethController is BaseController {
    using SafeMath for uint256;

    IWETH public immutable weth;

    constructor (
        address manager,
        address accessControl,
        address registry
    ) public BaseController(manager, accessControl, registry) {
        weth = IWETH(IAddressRegistry(registry).weth());
    }

    /// @notice Allows Manager contract to wrap ether
    /// @dev Interacts with Weth contract
    /// @param amount Amount of Ether to wrap
    function wrap(uint256 amount) external payable onlyManager onlyMiscOperation {
        require(amount > 0, "INVALID_VALUE");
        // weth contract reverts without message when value > balance of caller
        require(address(this).balance >= amount, "NOT_ENOUGH_ETH"); 

        uint256 balanceBefore = weth.balanceOf(address(this));
        weth.deposit{value: amount}();
        uint256 balanceAfter = weth.balanceOf(address(this));

        require(balanceBefore.add(amount) == balanceAfter, "INCORRECT_WETH_AMOUNT");
    }

    /// @notice Allows manager to unwrap weth to eth
    /// @dev Interacts with Weth contract
    /// @param amount Amount of weth to unwrap
    function unwrap(uint256 amount) external onlyManager onlyMiscOperation {
        require (amount > 0, "INVALID_AMOUNT");

        uint256 balanceBeforeWeth = weth.balanceOf(address(this));
        uint256 balanceBeforeEther = address(this).balance;

        // weth contract fails silently on withdrawal overage
        require(balanceBeforeWeth >= amount, "EXCESS_WITHDRAWAL"); 
        weth.withdraw(amount);
        uint256 balanceAfterEther = address(this).balance;

        require(balanceBeforeEther.add(amount) == balanceAfterEther, "INCORRECT_ETH_AMOUNT");
    }
}