// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./INFTCore.sol";

interface INFTCoreWithTransferHistory is INFTCore {
    struct TransferRecord {
        address from;
        address to;
        uint256 txHistoryTimeStamp;
    }

    function getAllTransferRecord(uint256 tokenId) external view returns (TransferRecord[] memory);

    function burnToken(uint256 tokenId) external;

    function getNextTokenId() external view returns (uint256);
}