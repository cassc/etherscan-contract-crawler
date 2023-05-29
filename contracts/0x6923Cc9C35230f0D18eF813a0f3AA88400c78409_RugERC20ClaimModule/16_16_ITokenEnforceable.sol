// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ITokenEnforceable {
    event PolicyUpdated(
        PolicyType indexed policy,
        address indexed implementation
    );

    function updateMintPolicy(address implementation) external;

    function updateBurnPolicy(address implementation) external;

    function updateTransferPolicy(address implementation) external;

    function isAllowed(
        address operator,
        address sender,
        address recipient,
        uint256 value // amount (ERC20) or tokenId (ERC721)
    ) external view returns (bool);
}

enum PolicyType {
    Mint,
    Burn,
    Transfer
}