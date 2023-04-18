// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {PresaleSwapStorage} from "./PresaleSwapStorage.sol";


contract PresaleSwap is PresaleSwapStorage, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @dev constants
    string public constant nameBase = "Presale V1.2.1";

    /// @dev variables
    IERC20 public iToken;

    uint8 public iDecimals;

    constructor(address _token, uint _start, uint _duration) {
        require(_token != address(0), "Invalid token address");
        require(_start > block.timestamp, "invalid startTime");
        require(_duration > 0, "invalid duration");

        iToken = IERC20(_token);
        iDecimals = 18 ;
        rate = 50000; 
        hardCap = 52000 * (10 ** iDecimals); 
        startTime = _start;
        endTime = _start + _duration;
        minSwap = 10 * (10 ** iDecimals); 
        maxSwap = 5000 * (10 ** iDecimals); 
        swapOn = false;
        tokenSupply = (hardCap * rate) / 1000;
        swapTotal = 0; 
    }


    function swap(
        uint _amount
    ) external nonReentrant swapEnabled onProgress returns (bool) {
        require(
            _amount >= minSwap,
            "Swap routine: amount must be at least 10 tokens"
        );
        require(
            _amount <= maxSwap,
            "Swap routine: amount can be max. 5_000 tokens"
        );
        require((_amount + swapTotal) <= hardCap, "hardCap exceeded");

        iToken.safeTransferFrom(msg.sender, address(this), _amount);

        swaps[msg.sender] += _amount;

        claims[msg.sender] += (_amount * rate) / 1000;

        swapTotal += _amount;

        if ((swapTotal + minSwap) > hardCap) {
            swapOn = false;

            emit hardCapFilled(msg.sender);
        }

        emit Swapped(msg.sender, _amount);

        return true;
    }

  
    function forwardInvestTokens() external onlyOwner {
        require(iToken.balanceOf(address(this)) > 0, "Presale:  No Tokens");

        uint _balance = iToken.balanceOf(address(this));

        iToken.transfer(msg.sender, _balance);

        emit InvestTokensForwarded(_balance);
    }


    function enableSwap(bool _flag) external onlyOwner {
        swapOn = _flag;

        emit SwapEnabledUpdated(_flag);
    }


    function setSalesTime(uint _start, uint _end) external onlyOwner {
        startTime = _start;

        endTime = _end;

        emit timeUpdated(_end);
    }
}