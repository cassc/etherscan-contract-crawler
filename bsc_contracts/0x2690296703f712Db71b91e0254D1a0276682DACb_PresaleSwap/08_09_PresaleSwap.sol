// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {PresaleSwapStorage} from "./PresaleSwapStorage.sol";

// investToken 0x55d398326f99059ff775485246999027b3197955 (USDT-BEP20)
// wantToken 0xab11DFD9CDFC51053415a505C97937Df1881b3d1 (SELF-BEP20 version)
// bscTest investToken (USDT) 0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684

contract PresaleSwap is PresaleSwapStorage, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @dev constants
    string public constant nameBase = "Presale V1.2.1";

    /// @dev variables
    /// investToken to be swapped
    IERC20 public iToken;

    /// decimals of investToken
    uint8 public iDecimals;

    /// @dev constructor
    /// @param _token : address for swapping investments
    /// @param _start : epoch unix timestamp starttime of sale
    /// @param _duration : duration of sale in seconds
    /// @dev constructing the easy...
    constructor(address _token, uint _start, uint _duration) {
        require(_token != address(0), "Invalid token address");
        require(_start > block.timestamp, "invalid startTime");
        require(_duration > 0, "invalid duration");

        /// for the sake of simplicity
        /// input variable by call or lazy hardcoded
        /// all decimal conversions in constructor
        /// see description in PresaleStorage.sol
        iToken = IERC20(_token);
        iDecimals = 18 ;
        rate = 50000; // +extra 3 decimals
        hardCap = 52000 * (10 ** iDecimals); // solidity number
        startTime = _start;
        endTime = _start + _duration;
        minSwap = 10 * (10 ** iDecimals); // solidity number
        maxSwap = 5000 * (10 ** iDecimals); // solidity number
        swapOn = false;
        tokenSupply = (hardCap * rate) / 1000; // solidity number, (rate corrects 3 decimals!)
        swapTotal = 0; // solidity number
    }

    /// @dev function called by user : msg.sender
    /// @param _amount the amount of tokens to swap for the sale
    /// @notice contract checks limits and updates balances and state variables
    function swap(
        uint _amount
    ) external nonReentrant swapEnabled onProgress returns (bool) {
        /// have the frontend also validate the _amount input
        require(
            _amount >= minSwap,
            "Swap routine: amount must be at least 10 tokens"
        );
        require(
            _amount <= maxSwap,
            "Swap routine: amount can be max. 5_000 tokens"
        );
        require((_amount + swapTotal) <= hardCap, "hardCap exceeded");

        /// make the actual transfer 1st..
        iToken.safeTransferFrom(msg.sender, address(this), _amount);

        /// then we can update the swapped amount
        swaps[msg.sender] += _amount;

        /// and also reserve the claims....
        claims[msg.sender] += (_amount * rate) / 1000;

        /// update totals
        swapTotal += _amount;

        /// if hardCap is reached... (..or almost reached.. :)
        if ((swapTotal + minSwap) > hardCap) {
            /// raise red flag
            swapOn = false;

            /// emit lucky staker
            emit hardCapFilled(msg.sender);
        }

        /// notify just another swap
        emit Swapped(msg.sender, _amount);

        /// notify caller all is good
        return true;
    }

    /// @dev function called by owner
    /// @notice contract checks if there is balance before sending tokens
    function forwardInvestTokens() external onlyOwner {
        /// do some checks
        require(iToken.balanceOf(address(this)) > 0, "Presale:  No Tokens");

        // check balance of contract
        uint _balance = iToken.balanceOf(address(this));

        // transfer funds to owners balance
        iToken.transfer(msg.sender, _balance);

        // notify transfer
        emit InvestTokensForwarded(_balance);
    }

    /// @dev function called by owner
    /// @param _flag : enable or disable the sales
    function enableSwap(bool _flag) external onlyOwner {
        // set swap on or off
        swapOn = _flag;

        // notifiy flag change
        emit SwapEnabledUpdated(_flag);
    }

    /// @dev function called by owner
    /// @param _start : set startTime of sales
    /// @param _end : set endTime of sales
    function setSalesTime(uint _start, uint _end) external onlyOwner {
        /// set new sales starting time
        startTime = _start;

        /// set new sales ending time
        endTime = _end;

        /// notify new endTime
        emit timeUpdated(_end);
    }
}