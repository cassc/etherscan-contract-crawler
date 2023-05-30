// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Withdraw is Ownable {
    using SafeMath for uint256;

    struct Part {
        address wallet;
        uint256 salePart;
    }

    Part[] public parts;

    uint256 public saleDivider;
    mapping(address => bool) executor;

    constructor(){
        executor[_msgSender()] = true;
    }

    modifier onlyExecutor() {
        require(executor[_msgSender()] == true, "Bad executor");
        _;
    }

    function withdrawAdd(Part memory _part) internal {
        parts.push(_part);
        saleDivider += _part.salePart;
        executor[_part.wallet] = true;
    }

    function editWallet(uint256 _key, address _wallet) public onlyExecutor {
        require(parts[_key].wallet == _msgSender(), "Bad wallet part key");

        parts[_key].wallet = _wallet;

        delete executor[_msgSender()];
        executor[_wallet] = true;
    }

    function withdrawSales() public onlyExecutor {

        uint256 balance = address(this).balance;
        require(balance > 0, "Sales Balance = 0");

        for(uint8 i = 0; i < parts.length; i++){
            if(parts[i].salePart > 0){
                _withdraw(parts[i].wallet, balance.mul(parts[i].salePart).div(saleDivider));
            }
        }

        _withdraw(owner(), address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}