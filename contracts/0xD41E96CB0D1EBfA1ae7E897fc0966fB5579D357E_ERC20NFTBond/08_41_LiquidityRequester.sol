// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/ILiquidityRequester.sol";
import "../access/AccessManagedUpgradeable.sol";
import "../Roles.sol";

/**
 * @title LiquidityRequester
 * @dev Contains functions related to withdraw or return liquidity to the contract for borrowing
 * Increments every time money is taking out for lending projects, decrements every time is returned
 * @author Ethichub
 */
abstract contract LiquidityRequester is Initializable, ILiquidityRequester, AccessManagedUpgradeable {
    uint256 public totalBorrowed;

    event LiquidityRequested(uint256 totalBorrowed, address indexed destination);
    event LiquidityReturned(uint256 totalBorrowed, address indexed destination);

    /**
     * @dev External function to withdraw liquidity for borrowing
     * @param destination address of recipient
     * @param amount uint256 in wei
     *
     * Requirement:
     *
     * - Only the role LIQUIDITY_REQUESTER can call this function
     */
    function requestLiquidity(address destination, uint256 amount) public virtual override onlyRole(LIQUIDITY_REQUESTER) returns (uint256) {
        return _requestLiquidity(destination, amount);
    }

    /**
     * @dev External function to return liquidity from borrowing
     * @param amount uint256 in wei
     */
    function returnLiquidity(uint256 amount) public payable virtual override returns (uint256) {
        return _returnLiquidity(amount);
    }

    /**
     * @dev Internal function to withdraw liquidity for borrowing
     * Updates and returns totalBorrowed
     * @param destination address of recipient
     * @param amount uint256 in wei
     */
    function _requestLiquidity(address destination, uint256 amount) internal returns (uint256) {
        totalBorrowed = totalBorrowed + amount;
        emit LiquidityRequested(totalBorrowed, destination);
        return totalBorrowed;
    }

    /**
     * @dev Internal function to return liquidity from borrowing
     * Updates and returns totalBorrowed
     * @param amount uint256 in wei
     */
    function _returnLiquidity(uint256 amount) internal returns (uint256) {
        totalBorrowed = totalBorrowed - amount;
        emit LiquidityReturned(totalBorrowed, msg.sender);
        return totalBorrowed;
    }
    
    uint256[49] private __gap;
}