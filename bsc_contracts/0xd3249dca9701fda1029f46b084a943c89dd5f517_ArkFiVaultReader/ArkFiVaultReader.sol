/**
 *Submitted for verification at BscScan.com on 2023-04-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVAULT {
    function getAvailableReward(address _address) external view returns (uint256);
    function principalBalance(address _address) external view returns (uint256);
    function airdropBalance(address _address) external view returns (uint256);
    function deposits(address _address) external view returns (uint256);
    function newDeposits(address _address) external view returns (uint256);
    function out(address _address) external view returns (uint256);
    function postTaxOut(address _address) external view returns (uint256);
    function roi(address _address) external view returns (uint256);
    function tax(address _address) external view returns (uint256);
    function cwr(address _address) external view returns (uint256);
    function maxCwr(address _address) external view returns (uint256);
    function penalized(address _address) external view returns (bool);
    function accountReachedMaxPayout(address _address) external view returns (bool);
    function doneCompounding(address _address) external view returns (bool);
    function lastAction(address _address) external view returns (uint256);
    function compounds(address _address) external view returns (uint256);
    function withdrawn(address _address) external view returns (uint256);
    function airdropped(address _address) external view returns (uint256);
    function airdropsReceived(address _address) external view returns (uint256);
    function roundRobinRewards(address _address) external view returns (uint256);
    function directRewards(address _address) external view returns (uint256);
    function timeOfEntry(address _address) external view returns (uint256);
    function referrerOf(address _address) external view returns (address);
    function roundRobinPosition(address _address) external view returns (uint256);
    function upline(address _address, uint i) external view returns (address);
    function checkNdv(address investor) external view returns(int256);
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ArkFiVaultReader {
    function getInvestorStats(address investor) public view returns(
        uint256 principalBalance, 
        uint256 availableRewards, 
        uint256 deposits,
        uint256 cwr,
        int256 ndv,
        uint256 roi,
        uint256 lastAction,
        uint256 withdrawn,
        uint256 walletBalance) {

        IVAULT arkFiVault = IVAULT(0xeB5f81A779BCcA0A19012d24156caD8f899F6452);
        IBEP20 ARK_TOKEN = IBEP20(0x111120a4cFacF4C78e0D6729274fD5A5AE2B1111);

        availableRewards = arkFiVault.getAvailableReward(investor);
        principalBalance = arkFiVault.principalBalance(investor);
        deposits = arkFiVault.deposits(investor);
        cwr = arkFiVault.cwr(investor);
        ndv = arkFiVault.checkNdv(investor);
        roi = arkFiVault.roi(investor);
        lastAction = arkFiVault.lastAction(investor);
        withdrawn = arkFiVault.withdrawn(investor);
        walletBalance = ARK_TOKEN.balanceOf(investor);
    }
}