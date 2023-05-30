// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IONFTReceiver {
    /**
     * @dev Called by the ONFT contract when tokens are received from source chain.
     * @param _srcChainId The chain id of the source chain.
     * @param _srcAddress The address of the ONFT token contract on the source chain.
     * @param _from The address of the account that received the tokens.
     * @param _tokenIds The IDs of tokens.
     * @param _payload Additional data with no specified format.
     */
    function onONFTReceived(uint16 _srcChainId, bytes calldata _srcAddress, address _from, uint[] memory _tokenIds, bytes calldata _payload) external;
}