// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma abicoder v2;

interface ITBCCFinanceFeeHandler {
    function getApesClaimAmount() external view returns (uint256);

    function apesClaim(
        address _holder,
        uint256 _tokenId
    ) external;
}