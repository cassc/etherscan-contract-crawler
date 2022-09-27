// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.15;

interface IBridgeAdapter {
    function bridge(
        uint64 _dstChainId,
        // the address that the fund is transfered to on the destination chain
        address _receiver,
        uint256 _amount,
        address _token,
        // Bridge transfers quoted and abi encoded by chainhop backend server.
        // Bridge adapter implementations need to decode this themselves.
        bytes memory _bridgeParams,
        // The message to be bridged alongside the transfer.
        // Note if the bridge adapter doesn't support message passing, the call should revert when
        // this field is set.
        bytes memory _requestMessage
    ) external payable returns (bytes memory bridgeResp);
}