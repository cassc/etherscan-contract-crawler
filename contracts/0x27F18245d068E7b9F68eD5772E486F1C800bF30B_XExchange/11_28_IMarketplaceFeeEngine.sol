// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMarketplaceFeeEngine {
    function setFeeReceipient(address payable _feeRecipient) external;

    function getMarketplaceFee(
        bytes32 id,
        address collection,
        uint256 value
    ) external view returns (address payable[] memory, uint256[] memory);
}