pragma experimental ABIEncoderV2;
pragma solidity ^0.7.6;

interface IOVLTransferHandler {
    function handleTransfer(address sender, address recipient, uint256 amount) external;
}