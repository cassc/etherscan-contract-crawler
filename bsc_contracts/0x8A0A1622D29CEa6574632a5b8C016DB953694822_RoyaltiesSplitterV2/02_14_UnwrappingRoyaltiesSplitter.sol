// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IWETH.sol";
import "./ViewablePaymentSplitter.sol";

contract UnwrappingRoyaltiesSplitter is ViewablePaymentSplitter {

    address public immutable WBNB;
    uint256 internal immutable _payeesLength;

    constructor(
        address[] memory payees, 
        uint256[] memory shares_,
        address wbnb
    )
        ViewablePaymentSplitter(payees, shares_) 
    {
        WBNB = wbnb;
        _payeesLength = payees.length;
    }

    function release(IERC20 token, address account) public virtual override {
        require(address(token) != WBNB, "Use release(address) for WBNB");
        super.release(token, account);
    }


    function release(address payable account) public virtual override {
        _unwrap();
        super.release(account);
    }

    function releaseAll() public virtual {
        _unwrap();
        for (uint256 i = 0; i < _payeesLength; ++i) {
            super.release(payable(payee(i)));
        }
    }

    function releaseAll(IERC20 token) public virtual {
        require(address(token) != WBNB, "Use releaseAll() for WBNB");
        for (uint256 i = 0; i < _payeesLength; ++i) {
            super.release(token, payee(i));
        }
    }

    /** 
     * @dev View total received Ether payment.
     */
    function totalReceived() public view virtual override returns (uint256) {
        return super.totalReceived(IERC20(WBNB)) + super.totalReceived();
    }

    /** 
     * @dev View total received `token` payment.
     */
    function totalReceived(IERC20 token) public view override returns (uint256) {
        if (address(token) == WBNB) return 0;
        return token.balanceOf(address(this)) + totalReleased(token);
    } 

    /**
     * @dev View the pending Ether payment of an `account`.
     */
    function pending(address account) public view virtual override returns (uint256) {
        return super.pending(IERC20(WBNB), account) + super.pending(account);
    }

    /**
     * @dev View the pending `token` payment of an `account`.
     */
    function pending(IERC20 token,  address account) public view override returns (uint256) {
        if (address(token) == WBNB) return 0;
        return super.pending(token, account);
    }

    function _unwrap() internal {
        uint256 balance = IWETH(WBNB).balanceOf(address(this));
        if (balance > 0) {
            IWETH(WBNB).withdraw(balance);
        }
    }
}