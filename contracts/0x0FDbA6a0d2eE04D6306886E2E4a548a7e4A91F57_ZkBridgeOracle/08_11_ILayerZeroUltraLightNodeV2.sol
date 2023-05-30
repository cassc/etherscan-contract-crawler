// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILayerZeroUltraLightNodeV2 {
    // an Oracle delivers the block data using updateHash()
    function updateHash(uint16 _srcChainId, bytes32 _lookupHash, uint _confirmations, bytes32 _blockData) external;

    // can only withdraw the receivable of the msg.sender
    function withdrawNative(address payable _to, uint _amount) external;

    function hashLookup(address _oracle, uint16 _srcChainId,bytes32 _blockHash,bytes32 _receiptsHash) external view returns(uint256);

    function accruedNativeFee(address _address) external view returns (uint);
}