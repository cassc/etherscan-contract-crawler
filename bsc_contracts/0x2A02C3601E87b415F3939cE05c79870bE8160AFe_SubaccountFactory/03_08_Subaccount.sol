/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: Apache-2.0
*/
import "../intf/IDealer.sol";

pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice Subaccount can help its owner manage risk and positions.
/// You can open orders with isolated positions via Subaccount.
/// You can also let others trade for you by setting them as authorized
/// operators. Operators have no access to fund transfer.
contract Subaccount {
    // ========== storage ==========

    /*
       This is not a standard ownable contract because the ownership
       can not be transferred. This contract is designed to be
       initializable to better support clone, which is a low gas
       deployment solution.
    */
    address public owner;
    address public dealer;
    bool public initialized;

    // ========== modifier ==========

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    // ========== functions ==========

    function init(address _owner, address _dealer) external {
        require(!initialized, "ALREADY INITIALIZED");
        initialized = true;
        owner = _owner;
        dealer = _dealer;
        IDealer(dealer).setOperator(owner, true);
    }

    /// @param isValid authorize operator if value is true
    /// unauthorize operator if value is false
    function setOperator(address operator, bool isValid) external onlyOwner {
        IDealer(dealer).setOperator(operator, isValid);
    }

    /*
        Subaccount can only withdraw asset to its owner account.
        No deposit related function is supported in subaccount because the owner can
        transfer fund to subaccount directly in the Dealer contract. 
    */

    /// @param primaryAmount The amount of primary asset you want to withdraw
    /// @param secondaryAmount The amount of secondary asset you want to withdraw
    function requestWithdraw(uint256 primaryAmount, uint256 secondaryAmount)
        external
        onlyOwner
    {
        IDealer(dealer).requestWithdraw(primaryAmount, secondaryAmount);
    }

    /// @notice Always withdraw to owner, no matter who fund this subaccount
    function executeWithdraw(address to, bool isInternal) external onlyOwner {
        IDealer(dealer).executeWithdraw(to, isInternal);
    }

    /// @notice retrieve asset
    function retrieve(
        address to,
        address token,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }
}