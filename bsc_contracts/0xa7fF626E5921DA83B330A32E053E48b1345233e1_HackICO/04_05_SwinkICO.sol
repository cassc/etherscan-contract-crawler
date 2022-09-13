// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SwinkICO is Ownable {
    IERC20 public SWINK;
    IERC20 public USDC;
    bool enable;
    address private teamWallet;
    uint256 price = 5;

    constructor() {
        USDC = IERC20(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d);   // bsc mainnet: 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d
    }

    function setSwink(address _swink) public onlyOwner {
        SWINK = IERC20(_swink); 
    }

    function buySwink(uint256 usdcAmount) public {
        uint256 usdcBalanceOfUser = USDC.balanceOf(msg.sender);
        require(usdcBalanceOfUser >= usdcAmount, "You dont have enough balance");
        uint256 allowance = USDC.allowance(msg.sender, address(this));
        require(allowance >= usdcAmount, "Check allowance");
        USDC.transferFrom(msg.sender, address(this), usdcAmount);
        uint256 swinkAmount = usdcAmount * 100 / 10 ** 8 / price;
        SWINK.transfer(msg.sender, swinkAmount);
    }

    function withdrawSwink() public onlyOwner {
        uint256 swinkBalance = SWINK.balanceOf(address(this));
        SWINK.transfer(teamWallet, swinkBalance);
    }

    function withdrawUsdc() public onlyOwner {
        require(enable, "Withdraw is not enabled yet");
        uint256 usdcBalance = USDC.balanceOf(address(this));
        USDC.transfer(teamWallet, usdcBalance);
    }

    function setTeamWallet(address _teamAddress) public onlyOwner {
        teamWallet = _teamAddress;
    }

    function toggleEnable() public onlyOwner {
        enable = !enable;
    }
}