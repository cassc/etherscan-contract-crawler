//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Exchange is Ownable {

    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;

    IERC20 public immutable tokena;

    IERC20 public immutable tokenb;

    event ExchangeTokenaForTokenb(address account,uint256 amount);

    constructor(IERC20 tokena_,IERC20 tokenb_){
        tokena = tokena_;
        tokenb = tokenb_;
    }

    function exchangeTokenaForTokenb() external
    {
        address user = msg.sender;
        uint256 tokenaBalance = tokena.balanceOf(user);
        tokena.transferFrom(user,DEAD, tokenaBalance);
        require(tokenaBalance<=tokenb.balanceOf(address(this)));
        tokenb.transfer(user, tokenaBalance);
        emit ExchangeTokenaForTokenb(user,tokenaBalance);
    }

    function withdraw(address _token, address payable _to) external onlyOwner {
        if (_token == address(0x0)) {
            payable(_to).transfer(address(this).balance);
        } else {
            IERC20(_token).transfer(
                _to,
                IERC20(_token).balanceOf(address(this))
            );
        }
    }
}