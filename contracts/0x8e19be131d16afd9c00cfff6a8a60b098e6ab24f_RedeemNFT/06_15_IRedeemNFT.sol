// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

// Allows anyone to redeem tokens from the platform.
interface IRedeemNFT {
    
    // Redeems digital points in change of ERC20 tokens.
    function claim(
        address sender,
        address signer,
        uint256 nonce,
        uint256 qty,
        uint256 internalId,
        bytes calldata signature
    ) external;

    // Verify whether a nonce value was used or not for a given signer account.
    function isUsedNonce(address signer, uint256 nonce) external view returns (bool);

    // This event is triggered whenever a call to #redeem succeeds.
    event TokensRedeemed(
        address indexed account,
        address indexed signer,
        uint256 internalId,
        uint256 qty
    );
}