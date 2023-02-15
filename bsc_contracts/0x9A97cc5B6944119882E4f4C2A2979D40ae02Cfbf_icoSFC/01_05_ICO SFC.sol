// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/[email protected]/token/ERC20/IERC20.sol";
import "@openzeppelin/[email protected]/security/Pausable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract icoSFC is Pausable, Ownable {
    address public constant SFC = 0xc02F0512a9967Fe509722F96Dd1bE26bAE214629;
    address public constant LIQUIDITY_POOL = 0x94c03960dAE18866Bd859040D65e2441039e7Ce9;
    
    uint public constant MAX_ORDER_SIZE = 10000000000000000000000000000000;
    mapping(address => uint) public orders;
   
    uint public bnbPrice;
    uint public icoBalance;

    event Released(address indexed to, uint amount);

    function start() public onlyOwner {
       icoBalance = IERC20(SFC).balanceOf(address(this));
    }

    function purchese() public payable whenNotPaused returns (bool) {
        uint amount = (10000 * (bnbPrice * msg.value * 1000000000000000000)) / 1000000000000000000; 
       
        require(amount <= icoBalance, "ICO BALANCE IS LESS THAN YOUR ORDER");
        require(amount < MAX_ORDER_SIZE, "MAX_ORDER_SIZE ERROR");
        require((orders[msg.sender] + amount) < MAX_ORDER_SIZE, "YOU ARE LIMITED");
      
       (bool liquiditySuccess, ) = LIQUIDITY_POOL.call{value: msg.value}("");

        if(liquiditySuccess) {
            IERC20(SFC).transfer(msg.sender, amount);
            orders[msg.sender] += amount;
            icoBalance -= amount;
            emit Released(msg.sender,amount);

            return true;
        }

        return false;
    }

    function setBnbPrice(uint price) public onlyOwner {
        bnbPrice = price;
    }
    function emergencyWithdraw() public onlyOwner {
       uint balance = IERC20(SFC).balanceOf(address(this));
       IERC20(SFC).transfer(msg.sender, balance);
     icoBalance -= balance;
    }
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}