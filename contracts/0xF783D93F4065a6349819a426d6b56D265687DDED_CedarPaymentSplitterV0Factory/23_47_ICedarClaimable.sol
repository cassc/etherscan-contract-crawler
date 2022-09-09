// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import "./ICedarIssuance.sol";

interface ICedarClaimableV0 {
    // Whitelist mint
    // Claim using merkle proof
    function claim(
        uint256 quantity,
        address recipient,
        bytes32[] calldata proof
    ) external;

    struct ClaimRequest {
        ICedarIssuanceV0.AuthType authType;
        uint256 quantity;
        address recipient;
        address erc20TokenContract;
        bytes32[] proof;
    }

    function claim(ClaimRequest calldata claimRequest, bytes calldata signature) external;
}