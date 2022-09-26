// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract ViewablePaymentSplitter is PaymentSplitter {

    constructor(
        address[] memory payees, 
        uint256[] memory shares_
    )
        PaymentSplitter(payees, shares_) 
    {}

    /** 
     * @dev View total received Ether payment.
     */
    function totalReceived() public virtual view returns (uint256) {
        return address(this).balance + totalReleased();
    }

    /** 
     * @dev View total received `token` payment.
     */
    function totalReceived(IERC20 token) public virtual view returns (uint256) {
        return token.balanceOf(address(this)) + totalReleased(token);
    } 

    /**
     * @dev View the pending Ether payment of an `account`.
     */
    function pending(address account) public virtual view returns (uint256) {
        uint256 _totalReceived = address(this).balance + totalReleased();
        return (_totalReceived * shares(account)) / totalShares() - released(account);
    }

    /**
     * @dev View the pending `token` payment of an `account`.
     */
    function pending(IERC20 token,  address account) public virtual view returns (uint256) {
        uint256 _totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        return (_totalReceived * shares(account)) / totalShares() - released(token, account);
    }
}