/*
TYKHE (Tyche) was the goddess of fortune, chance, providence and fate.
She was usually honoured in a more favourable light as Eutykhia (Eutychia),
goddess of good fortune, luck, success and prosperity.

she will help us to calculate and distribute the profits
fairly among all those who participated according
to the help they gave when we had nothing.

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {AutomationCompatible} from "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
// import "hardhat/console.sol";

contract TykheFortuneDistributor is OwnableUpgradeable, AutomationCompatible {
    address public feeTokenAddress;
    mapping(address => uint256) public totalFortune;
    mapping(address => uint32) public feePercentage;
    mapping(address => bool) private isReceiver;
    address[] private feeReceiver;
    uint256 private upkeepBalance;
    uint256 private lastUpkeep;
    uint32 private constant TAX_DIVISOR = 10000;

    function initialize(address _feeTokenAddress) public initializer {
        __Ownable_init();
        feeTokenAddress = _feeTokenAddress;
        upkeepBalance = 1 ether;
    }

    receive() external payable {}

    function feeReceivers() public view returns (address[] memory) {
        return feeReceiver;
    }

    function setFeeTokenAddress(address newAddress)
        public
        onlyOwner
    {
        feeTokenAddress = newAddress;
    }

    function initShare(
        address[] memory receivers,
        uint32[] memory percentages
    ) public onlyOwner {
        require(feeReceiver.length==0, "Already initialized");
        require(receivers.length > 0, "No receivers specified");
        require(receivers.length == percentages.length, "Different size");
        uint32 totalFeesPercentage = 0;
        for (uint256 index = 0; index < receivers.length; index++) {
            totalFeesPercentage += percentages[index];
            feePercentage[receivers[index]] = percentages[index];
            isReceiver[receivers[index]] = true;
            feeReceiver.push(receivers[index]);
        }
        require(
            totalFeesPercentage == TAX_DIVISOR,
            "all members fees should be 100%"
        );
    }

    function yieldShare(address account, uint32 percentage) public {
        require(feePercentage[msg.sender] >= percentage, "Insufficient share to yield");
        feePercentage[msg.sender] -= percentage;
        feePercentage[account] += percentage;
        if(isReceiver[account]==false)
            feeReceiver.push(account);
    }

    function distribute() public {
        require(feeReceiver.length > 0, "No fortune receivers");
        uint256 totalFee = 0;
        if(feeTokenAddress==address(0)) {
            totalFee = address(this).balance;
        } else {
            totalFee = IERC20(feeTokenAddress).balanceOf(address(this));
        }
        totalFortune[address(0)] += totalFee;
        for (uint256 index = 0; index < feeReceiver.length; index++) {
            if (feePercentage[feeReceiver[index]] > 0) {
                uint256 fee = totalFee * feePercentage[feeReceiver[index]] / TAX_DIVISOR;
                totalFortune[feeReceiver[index]] += fee;
                if(feeTokenAddress==address(0)) {
                    payable(feeReceiver[index]).transfer(fee);
                } else {
                    IERC20(feeTokenAddress).transfer(feeReceiver[index], fee);
                }
            }
        }
    }

    function checkUpkeep(bytes calldata)
        public
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory performData
        )
    {
        uint256 totalFee = 0;
        if(feeTokenAddress==address(0)) {
            totalFee = IERC20(feeTokenAddress).balanceOf(address(this));
        } else {
            totalFee = address(this).balance;
        }
        if(totalFee >= upkeepBalance) {
            upkeepNeeded = true;
            performData = bytes("");
        }
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) public override {
        distribute();
    }

    function withdraw(address tokenAddress) public onlyOwner {
        require(tokenAddress!=feeTokenAddress, "Cannot withdraw fee token");
        IERC20(tokenAddress).transfer(
            msg.sender,
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }
}