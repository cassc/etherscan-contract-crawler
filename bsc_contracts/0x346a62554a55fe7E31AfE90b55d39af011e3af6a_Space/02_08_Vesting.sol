// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vesting is Ownable {
    uint public max;
    uint[] public amountList;

    uint public invokedTimestamp;
    IERC20 public lhc;

    uint public startAt;

    // @dev (60*60*24*360/12)*3
    uint INTERVAL = 7776000;

    constructor() {

    }

    function getAmountListSize() external view returns (uint) {
        return amountList.length;
    }

    function claim(address to, uint amount) onlyOwner external returns (uint) {
        require(startAt < amountList.length, "Out of the amount");
        require(invokedTimestamp > 0, "Invoke first");
        require(block.timestamp >= (INTERVAL * startAt) + invokedTimestamp, "Can not claim");

        uint remaining = amountList[startAt];
        require(amount <= remaining, "More than the amount in the list");

        remaining -= amount;
        amountList[startAt] = remaining;
        if (remaining == 0) {
            startAt += 1;
        }
        lhc.transfer(to, amount);
        return amount;
    }

    function invoke(uint timestamp, address erc20) onlyOwner external {
        require(invokedTimestamp == 0, "It had invoked");
        invokedTimestamp = timestamp;
        lhc = IERC20(erc20);
    }

    function toWei(uint value) internal pure returns (uint) {
        return value * (10 ** 18);
    }

    function destroy() onlyOwner external {
        address owner = owner();
        selfdestruct(payable(owner));
    }
}