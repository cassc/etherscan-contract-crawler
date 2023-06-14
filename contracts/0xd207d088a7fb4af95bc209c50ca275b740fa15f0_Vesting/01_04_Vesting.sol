// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Vesting {
    using SafeERC20 for IERC20;

    IERC20 public immutable MCT;

    uint256[46] public TIMESTAMPS = [1652313600, 1654992000, 1657584000, 1660262400, 1662940800, 1665532800, 1668211200, 1670803200,
    1673481600, 1676160000, 1678579200, 1681257600, 1683849600, 1686528000, 1689120000, 1691798400, 1694476800, 1697068800, 1699747200, 1702339200,
    1705017600, 1707696000, 1710201600, 1712880000, 1715472000, 1718150400, 1720742400, 1723420800, 1726099200, 1728691200, 1731369600, 1733961600,
    1736640000, 1739318400, 1741737600, 1744416000, 1747008000, 1749686400, 1752278400, 1754956800, 1757635200, 1760227200, 1762905600, 1765497600,
    1768176000, 1770854400];

    mapping(address => uint8) public claimed;

    mapping(address => uint8) private strategy;
    mapping(address => uint8) private leftovers;
    mapping(address => bool) private negative;
    mapping(address => uint256) private amountPerMonth;

    constructor(IERC20 _mct, address[3] memory strategyOne, address[2] memory strategyTwo, address strategyThree, uint256[6] memory amounts, uint8[4] memory _leftovers) {
        MCT = _mct;
        for (uint8 i; i < 3; i++) {
            strategy[strategyOne[i]] = 1;
            amountPerMonth[strategyOne[i]] = amounts[i];
            leftovers[strategyOne[i]] = _leftovers[i];
        }
        claimed[strategyOne[2]] = 22;
        negative[strategyOne[2]] = true;
        for (uint8 i; i < 2; i++) {
            strategy[strategyTwo[i]] = 2;
            amountPerMonth[strategyTwo[i]] = amounts[i + 3];
        }
        strategy[strategyThree] = 3;
        amountPerMonth[strategyThree] = amounts[5];
        leftovers[strategyThree] = _leftovers[3];
        negative[strategyThree] = true;
    }

    function avaliableToClaim(address account) public view returns(uint8, uint256) {
        require(strategy[account] != 0, "Not a registered user");
        uint8 counter = claimed[account];
        uint8 maxCounter;
        if (strategy[account] == 2) {
            maxCounter = 30;
        }
        else {
            maxCounter = 46;
        }
        while (counter < maxCounter && TIMESTAMPS[counter] <= block.timestamp) {
            counter++;
        }
        maxCounter = counter;//34
        counter -= claimed[account];//6
        if (counter == 0) {
            return (0,0);
        }
        uint256 toTransfer;
        if (strategy[account] == 3) {
            uint8 toDecrease;
            if (maxCounter > 34) {
                uint8 toIncrease = maxCounter - 34;
                if (toIncrease > counter) {
                    toIncrease = counter;
                }
                toTransfer += toIncrease * 55555555;
            }
            if (claimed[account] < 34 && maxCounter > 28) {
                toDecrease = maxCounter - 28;
                if (toDecrease > 6) {
                    toDecrease = 6;
                }
            }
            toTransfer += amountPerMonth[account] * (counter - toDecrease);
            if (toDecrease < 6) {
                counter -= toDecrease;
            }
        }
        else {
            toTransfer += amountPerMonth[account] * counter;
        }
        if (maxCounter == 46) {
            if (negative[account]) {
                toTransfer -= leftovers[account];
            }
            else {
                toTransfer += leftovers[account];
            }
        }
        return (counter, toTransfer);
    }

    function claim() external {
        (uint8 counter, uint256 toTransfer) = avaliableToClaim(msg.sender);
        if (toTransfer > 0) {
            claimed[msg.sender] += counter;
            MCT.safeTransfer(msg.sender, toTransfer * (10**18));
        }
    }
}