// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BuyTokens is Ownable {

    IERC20 public romToken;

    constructor(IERC20 tokenRom) {
        romToken = tokenRom;
    }

    function BuyTokensNoRef() public payable {
        uint256 amountTobuy = msg.value;
        uint256 dexBalance = romToken.balanceOf(address(this));
        require(
            amountTobuy >= 100000000000000000,
            "You need to deposit at least 0.1 bnb to buy our Rom tokens"
        );
        require(
            amountTobuy * 50000 <= dexBalance,
            "Not enough tokens in the reserve of contract please contact to support"
        );
        romToken.transfer(msg.sender, amountTobuy * 50000);
    }

    function BuyTokensByRef(address addressRef) public payable {
        uint256 amountTobuy = msg.value;
        uint256 dexBalance = romToken.balanceOf(address(this));
        require(
            amountTobuy >= 100000000000000000,
            "You need to deposit at least 0.1 bnb to buy Rom"
        );
        require(
            amountTobuy * 50000 <= dexBalance,
            "Not enough tokens in the reserve"
        );
        romToken.transfer(msg.sender, amountTobuy * 50000);
        address payable to = payable(addressRef);
        to.transfer(amountTobuy * 10 / 100);
    }

    function GetBalanceofToken() external view returns (uint256) {
        return romToken.balanceOf(address(this));
    }

    function GetBalanceofBNB() public view returns (uint256) {
        return address(this).balance;
    }

    function WithdrawTokens(uint256 amount) public onlyOwner returns (uint256) {
        IERC20(romToken).transfer(owner(), amount);
    }

    function WithdrawBNB(uint256 amount) public onlyOwner returns (uint256) {
        address payable to = payable(msg.sender);
        to.transfer(amount);
    }
}