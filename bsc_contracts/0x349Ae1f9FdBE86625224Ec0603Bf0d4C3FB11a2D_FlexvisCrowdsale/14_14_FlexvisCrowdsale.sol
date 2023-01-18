// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./crowdsale/validation/TimedCrowdsale.sol";
import "./crowdsale/validation/CappedCrowdsale.sol";
import "./crowdsale/distribution/PostDeliveryCrowdsale.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract FlexvisCrowdsale is PostDeliveryCrowdsale, Ownable{

    IERC20 private flexvis;

    constructor(
        uint256 rate,
        address payable wallet,
        IERC20 token,
        uint256 openingTime,
        uint256 closingTime,
        uint cap
    ) Crowdsale(rate, wallet, token) TimedCrowdsale(openingTime, closingTime) CappedCrowdsale(cap) {
        flexvis = token;
    }

    function endCrowdsale() external onlyOwner {
        _endCrowdsale();
    }

    function extendTime(uint256 duration) external onlyOwner {
        _extendTime(closingTime() + duration);
    }

    function concludeSale(uint amount) external onlyOwner {
        require(block.timestamp > closingTime(), "Presale still Live");
        flexvis.transfer(msg.sender, amount);
    }
   
}