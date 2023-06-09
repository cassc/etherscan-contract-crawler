// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract GREENETHSwap is Ownable {
    using SafeMath for uint256;

    IERC20 public tokenFrom = IERC20(0x087B81c5312bCb45179a05afF5aeC5CdDdC789b6);
    IERC20 public tokenTo = IERC20(0xf792e5E95C5d08173b8Fe0307473F8b9486F2d88);

    constructor() {
    }

    function swapGRE() public {
        uint256 amount = tokenFrom.balanceOf(msg.sender);
        require(amount > 0, "Not enough tokens");
        require(tokenTo.balanceOf(owner()) >= amount, "Not enough new tokens");

        tokenFrom.transferFrom(msg.sender, address(this), amount);
        tokenTo.transferFrom(owner(), msg.sender, amount);
    }


    receive() external payable {}

    function rescueWrongTokens(address payable _recipient) public onlyOwner {
        _recipient.transfer(address(this).balance);
    }

    function rescueWrongERC20(address erc20Address) public onlyOwner {
        IERC20(erc20Address).transfer(msg.sender, IERC20(erc20Address).balanceOf(address(this)));
    }
}