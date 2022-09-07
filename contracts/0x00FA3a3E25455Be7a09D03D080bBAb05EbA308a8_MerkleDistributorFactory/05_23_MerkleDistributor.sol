//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "../interfaces/IMerkleDistributor.sol";

contract MerkleDistributor is IMerkleDistributor, Ownable {
    error AlreadyClaimed();
    error TransferFailed();
    error InvalidMerkleProof();
    error ClaimPeriodExpired();
    error ClaimPeriodStillActive();
    error OwnerAlreadyInitialized();

    mapping(address => bool) public hasClaimed;
    address public ALBUM_SAFE;
    ERC20PresetMinterPauser public TOKEN;
    bytes32 public MERKLE_ROOT;
    uint256 claimExpiryTime;

    function isClaimExpired() public view override returns (bool) {
        return block.timestamp > claimExpiryTime;
    }

    function returnTokensToSafe() public override {
        if (!isClaimExpired()) revert ClaimPeriodStillActive();
        TOKEN.transfer(ALBUM_SAFE, TOKEN.balanceOf(address(this)));
        emit TokensReturned(ALBUM_SAFE, TOKEN.balanceOf(address(this)));
    }

    function initialize(
        address _owner,
        address albumSafe,
        address token,
        bytes32 merkleRoot,
        uint256 claimDuration
    ) public override {
        if (owner() != address(0)) revert OwnerAlreadyInitialized();
        _transferOwnership(_owner);
        ALBUM_SAFE = albumSafe;
        TOKEN = ERC20PresetMinterPauser(token);
        MERKLE_ROOT = merkleRoot;
        claimExpiryTime = block.timestamp + claimDuration;
    }

    // Claim the given amount of the token to the given address.
    // Reverts if the inputs are invalid.
    function claim(
        address to,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external override {
        if (isClaimExpired()) revert ClaimPeriodExpired();
        if (hasClaimed[to]) revert AlreadyClaimed();

        // Verify merkle proof, or revert if not in tree
        bytes32 leaf = keccak256(abi.encodePacked(to, amount));
        bool isValidLeaf = MerkleProof.verify(merkleProof, MERKLE_ROOT, leaf);
        if (!isValidLeaf) revert InvalidMerkleProof();

        // Set address to claimed
        hasClaimed[to] = true;

        // Transfer tokens to address from albumSafe, reverts if transfer fails.
        if (!TOKEN.transfer(to, amount)) revert TransferFailed();

        // Emit claim event
        emit Claimed(ALBUM_SAFE, to, amount);
    }
}