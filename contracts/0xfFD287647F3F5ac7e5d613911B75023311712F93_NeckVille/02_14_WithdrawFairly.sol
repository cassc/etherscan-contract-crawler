// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract WithdrawFairly is Ownable {
    using SafeMath for uint256;

    struct Part {
        address wallet;
        uint256 salePart;
    }

    Part[] public parts;

    constructor(){
        parts.push(Part(0xd61DbEB0500803ed6839267dcc5f8f1FFDAC8Caf, 75));
        parts.push(Part(0xb224811F71c803af1762CC6AEfd995edbfAFBD42, 25));
    }

    function withdrawSales() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Sales Balance = 0");

        for(uint8 i = 0; i < parts.length; i++){
            if(parts[i].salePart > 0){
                _withdraw(parts[i].wallet, balance.mul(parts[i].salePart).div(100));
            }
        }

        _withdraw(owner(), address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    receive() external payable {}

}