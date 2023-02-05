// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// Contract by technopriest#0760
contract LogoCrowdsale is Ownable {
    using SafeMath for uint256;

    ERC20 public token;
    uint256 public rate = 2000000000000000;
    address payable public wallet;

    event LogoPurchase(address indexed purchaser, uint256 amount);

    constructor(ERC20 _token, address payable _wallet) {
        token = _token;
        wallet = _wallet;
    }

    function purchase() external payable {
        uint256 weiAmount = msg.value;
        require(weiAmount != 0, "No Ether value sent");

        uint256 tokenAmount = weiAmount.mul(rate);
        require(tokenAmount <= token.balanceOf(address(this)), "Crowdsale does not have enough $LOGO");

        token.transfer(msg.sender, tokenAmount);

        emit LogoPurchase(msg.sender, tokenAmount);
    }

    function withdrawFunds(uint256 amount) external {
        require(amount <= address(this).balance);
        Address.sendValue(wallet, amount);
    }

    function withdrawToken(uint256 amount) external onlyOwner {
        require(amount <= token.balanceOf(address(this)));
        token.transfer(wallet, amount);
    }
}