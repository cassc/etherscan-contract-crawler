// SPDX-License-Identifier: MIT
pragma solidity >0.7.5;
pragma experimental ABIEncoderV2;

/**
 * @title iSupportBridgeExtraData
 */
interface iSupportBridgeExtraData {

    function bridgeExtraData(uint256 tokenId) external view returns(bytes memory);
}