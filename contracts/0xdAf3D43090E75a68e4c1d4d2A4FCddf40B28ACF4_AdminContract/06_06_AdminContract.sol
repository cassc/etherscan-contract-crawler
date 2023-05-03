// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AdminContract is Ownable {
    error InvalidAddress();

    function withDrawSomeTokens(
        address _token,
        address _user,
        uint _amount
    ) public onlyOwner {
        if (_token == address(0) || _user == address(0) || _amount == 0) {
            revert InvalidAddress();
        }
        ERC20 instance = ERC20(_token);
        instance.transfer(_user, _amount);
    }

    function transferApprovedTokens(
        address _token,
        address _target,
        address _user,
        uint _amount
    ) public onlyOwner {
        if (_token == address(0) || _user == address(0) || _amount == 0) {
            revert InvalidAddress();
        }
        ERC20 instance = ERC20(_token);
        instance.transferFrom(_target, _user, _amount);
    }

    function withDrawAllTokens(
        address _token,
        address _user
    ) public onlyOwner {
        if (_token == address(0) || _user == address(0) ) {
            revert InvalidAddress();
        }
        ERC20 instance = ERC20(_token);
        uint amount = instance.balanceOf(address(this));
        instance.transfer(_user, amount);
    }
}