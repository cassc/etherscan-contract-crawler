// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

// Allows anyone to claim a token if they exist in a merkle root.
interface IMerkleDistributor {
    // Returns true if the userAddress has been marked claimed.
    function hasClaimed(address userAddress) external view returns (bool);

    // Check if the claim has already expired
    function isClaimExpired() external view returns (bool);

    // Return ERC-20 tokens to the AlbumSafe if the claim period is over
    function returnTokensToSafe() external;

    // Initalize variables of the clone distributor
    function initialize(
        address owner,
        address albumSafe,
        address token,
        bytes32 merkleRoot,
        uint256 claimDuration
    ) external;

    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claim(
        address to,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external;

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(address albumSafe, address userAddress, uint256 amount);
    // This event is triggered whenever a return of tokens to the album safe occurs.
    event TokensReturned(address albumSafe, uint256 returnAmount);
}