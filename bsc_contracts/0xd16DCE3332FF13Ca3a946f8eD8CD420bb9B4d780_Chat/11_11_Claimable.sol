// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Claimable {

    modifier validAddress(address _to) {
        require(_to != address(0));
        _;
    }
    function _claimValues(address token_, address to_) internal validAddress(to_) {
        if (token_ == address(0)) {
            _claimNativeCoins(to_);
        } else {
            _claimErc20Tokens(token_, to_);
        }
    }

    function _claimNativeCoins(address to_) internal {
        uint256 value = address(this).balance;
        _sendValue(payable(to_), value);
    }

    function _claimErc20Tokens(address token_, address to_) internal {
        IERC20 _ERC20 = IERC20(token_);
        uint256 balance = _ERC20.balanceOf(address(this));
        _ERC20.transfer(to_, balance);
    }

    function _sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}