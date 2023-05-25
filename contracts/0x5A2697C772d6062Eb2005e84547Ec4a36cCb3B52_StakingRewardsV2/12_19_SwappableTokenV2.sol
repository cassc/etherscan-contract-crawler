//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

// Inheritance
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../interfaces/Owned.sol";
import "../interfaces/ISwapReceiver.sol";


/// @title   Umbrella Rewards contract V2
/// @author  umb.network
/// @notice  This contract serves Swap functionality for rewards tokens
/// @dev     It allows to swap itself for other token (main UMB token).
abstract contract SwappableTokenV2 is Owned, ERC20 {
    struct SwapData {
        // number of tokens swapped so far (no decimals)
        uint32 swappedSoFar;
        // used limit since last swap (no decimals)
        uint32 usedLimit;
        // daily cup (no decimals)
        uint32 dailyCup;
        uint32 dailyCupTimestamp;
        uint32 swapEnabledAt;
    }

    uint256 public constant ONE = 1e18;

    uint256 public immutable swapStartsOn;
    ISwapReceiver public immutable umb;

    SwapData public swapData;

    event LogStartEarlySwapNow(uint time);
    event LogSwap(address indexed swappedTo, uint amount);
    event LogDailyCup(uint newCup);

    constructor(address _umb, uint32 _swapStartsOn, uint32 _dailyCup) {
        require(_dailyCup != 0, "invalid dailyCup");
        require(_swapStartsOn > block.timestamp, "invalid swapStartsOn");
        require(ERC20(_umb).decimals() == 18, "invalid UMB token");

        swapStartsOn = _swapStartsOn;
        umb = ISwapReceiver(_umb);
        swapData.dailyCup = _dailyCup;
    }

    function swapForUMB() external {
        SwapData memory data = swapData;

        (uint256 limit, bool fullLimit) = _currentLimit(data);
        require(limit != 0, "swapping period not started OR limit");

        uint256 amountToSwap = balanceOf(msg.sender);
        require(amountToSwap != 0, "you dont have tokens to swap");

        uint32 amountWoDecimals = uint32(amountToSwap / ONE);
        require(amountWoDecimals <= limit, "daily CUP limit");

        swapData.usedLimit = uint32(fullLimit ? amountWoDecimals : data.usedLimit + amountWoDecimals);
        swapData.swappedSoFar += amountWoDecimals;
        if (fullLimit) swapData.dailyCupTimestamp = uint32(block.timestamp);

        _burn(msg.sender, amountToSwap);
        umb.swapMint(msg.sender, amountToSwap);

        emit LogSwap(msg.sender, amountToSwap);
    }

    function startEarlySwap() external onlyOwner {
        require(block.timestamp < swapStartsOn, "swap is already allowed");
        require(swapData.swapEnabledAt == 0, "swap was already enabled");

        swapData.swapEnabledAt = uint32(block.timestamp);
        emit LogStartEarlySwapNow(block.timestamp);
    }

    /// @param _cup daily cup limit (no decimals), eg. if cup=5 means it is 5 * 10^18 tokens
    function setDailyCup(uint32 _cup) external onlyOwner {
        swapData.dailyCup = _cup;
        emit LogDailyCup(_cup);
    }

    function isSwapStarted() external view returns (bool) {
        // will it save gas if I do 2x if??
        return block.timestamp >= swapStartsOn || swapData.swapEnabledAt != 0;
    }

    function canSwapTokens(address _address) external view returns (bool) {
        uint256 balance = balanceOf(_address);
        if (balance == 0) return false;

        (uint256 limit,) = _currentLimit(swapData);
        return balance / ONE <= limit;
    }

    function currentLimit() external view returns (uint256 limit) {
        (limit,) = _currentLimit(swapData);
        limit *= ONE;
    }

    function _currentLimit(SwapData memory data) internal view returns (uint256 limit, bool fullLimit) {
        if (block.timestamp < swapStartsOn && data.swapEnabledAt == 0) return (0, false);

        fullLimit = block.timestamp - data.dailyCupTimestamp >= 24 hours;
        limit = fullLimit ? data.dailyCup : data.dailyCup - data.usedLimit;
    }
}