//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20Mintable {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
}

contract xSereneSwapper is Ownable {
    using SafeERC20 for IERC20;
     
    address inToken;
    address outToken;
    address receiver;

    uint256 public baseRatio;
    uint256 public soldAmount;
    uint256 public burnRate;
    uint256 public nextPrice;
    uint256 ratioModifier = 1e18;

    constructor(address _inToken, address _outToken, uint256 _ratio, uint256 _burnRate, address _receiver) {
        inToken = _inToken;
        outToken = _outToken;
        baseRatio = _ratio;
        receiver = _receiver;
        burnRate = _burnRate;
    }

    function setRatio(uint256 _ratio) public onlyOwner {
        baseRatio = _ratio;
    }

    function setSoldAmount(uint256 _soldAmount) public onlyOwner {
        soldAmount = _soldAmount;
    }

    function setBurnRate(uint256 _burnRate) public onlyOwner {
        burnRate = _burnRate;
    }

    function setReceiver(address _receiver) public onlyOwner {
        receiver = _receiver;
    }

    function setRatioModifier(uint256 _mod) public onlyOwner {
        ratioModifier = _mod;
    }

    function exchange(uint256 amount) public {
        address sender = msg.sender;
        require(IERC20(inToken).balanceOf(sender) >= amount, "sender does not have enough inToken");
        uint256 __ratio = baseRatio + (soldAmount / ratioModifier);
        uint256 outAmount = (amount / __ratio) * 100;
        uint256 burnAmount = (amount / 100) * burnRate;
        IERC20(inToken).safeTransferFrom(sender, address(this), amount);
        IERC20Mintable(inToken).burn(burnAmount);
        IERC20Mintable(outToken).mint(sender, outAmount);
        IERC20(inToken).approve(address(this), amount);
        IERC20(inToken).safeTransferFrom(address(this), receiver, amount - burnAmount);
        soldAmount = soldAmount + outAmount;
        nextPrice = baseRatio + (soldAmount / ratioModifier);
    } 

    function withdrawAll() public onlyOwner {
        IERC20(outToken).safeTransfer(msg.sender, IERC20(outToken).balanceOf(address(this)));
        IERC20(inToken).safeTransfer(msg.sender, IERC20(inToken).balanceOf(address(this)));
    }
}