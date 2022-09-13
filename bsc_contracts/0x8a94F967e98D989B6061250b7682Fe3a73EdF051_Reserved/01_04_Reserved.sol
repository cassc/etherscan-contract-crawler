// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./lib/Auth.sol";
import "./interfaces/IBEP20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Reserved is Auth {
    using SafeMath for uint256;
    IBEP20 public token;

    constructor(IBEP20 _token) Auth(msg.sender){
        token = _token;
    }

    receive() external payable {
        
    }

    function setToken(address _token) external onlyOwner{
        require(_token != address(0));
        token = IBEP20(_token);
    }

    function withdrawToken(address _to, uint256 _amount) external onlyOwner{
        require(token.balanceOf(address(this)) >= _amount, "Insufficient balance");
        require(_to != address(0), "Destination is 0");
        token.transfer(_to, _amount);
    }

    function withDrawBNB(address to, uint amount) external onlyOwner{
        require(address(this).balance >= amount, "Not enough balance");
        (bool success, ) = payable(to).call{value: amount}("");
    }
}