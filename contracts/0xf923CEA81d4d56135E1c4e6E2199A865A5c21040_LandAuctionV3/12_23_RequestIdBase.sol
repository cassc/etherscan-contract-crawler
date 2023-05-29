// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title RequestIdBase
 *
 * @dev A contract used by ConsumerBase and Router to generate requestIds
 *
 */
contract RequestIdBase {

    /**
    * @dev makeRequestId generates a requestId
    *
    * @param _dataConsumer address of consumer contract
    * @param _dataProvider address of provider
    * @param _router address of Router contract
    * @param _requestNonce uint256 request nonce
    * @param _data bytes32 hex encoded data endpoint
    *
    * @return bytes32 requestId
    */
    function makeRequestId(
        address _dataConsumer,
        address _dataProvider,
        address _router,
        uint256 _requestNonce,
        bytes32 _data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_dataConsumer, _dataProvider, _router, _requestNonce, _data));
    }
}