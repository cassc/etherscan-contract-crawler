/**
 *Submitted for verification at Etherscan.io on 2023-05-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract ApiShowETH {
    function reportBSCDeposit(bytes32 txHash, address from, address to, uint256 amount) external {}
    function checkBSCDeposit(bytes32 txHash, bytes32 checkHash) external {}
    function bridgeToBSC(address to, uint256 amount) external {}
    function applyFor(address to_, uint256 amount_, bytes memory reason_) external {}
    function bridgeToBSC(uint256 amount) external {}
    function bridgeToARB(uint256 amount, uint256 maxGas, uint256 gasPriceBid) external {}
    function bridgeFromARB(
        bytes32 l2TxId,
        bytes32[] calldata proof, 
        uint256 index, 
        address l2Sender, 
        address to, 
        uint256 l2Block, 
        uint256 l1Block, 
        uint256 l2Timestamp, 
        uint256 value,
        bytes calldata data
    ) external{}
    function applyMBOX(uint256 amount_) external {}
    function applyToken(address token_, uint256 amount_) external {}
}