// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMarketplace {
    function toggleCollection(address collection, bool allowed) external;

    function setProtocolFeeRecipient(address recipient) external;

    function setMintFeeRecipient(address collection, address recipient) external;

    function pause() external;

    function unpause() external;

    function transferOwnership(address newOwner) external;
}