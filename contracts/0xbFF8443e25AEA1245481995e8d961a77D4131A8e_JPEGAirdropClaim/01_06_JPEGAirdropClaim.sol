// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/ITokenVesting.sol";

/// @title JPEGAirdropClaim
/// @notice {JPEG} airdrop claim contract, whitelisted users can claim aJPEG, which is a vested airdrop token
/// which can be burnt to claim JPEG linearly. The vesting schedule is set by the owner
/// @dev This contract uses a merkle tree based whitelist.
contract JPEGAirdropClaim is Ownable {
    /// @dev see {setAirdropSchedule}
    struct AirdropSchedule {
        uint256 startTimestamp;
        uint256 cliffDuration;
        uint256 duration;
        uint256 airdropAmount;
    }

    /// @notice Root of the merkle tree used for the airdrop whitelist.
    bytes32 public immutable merkleRoot;

    ITokenVesting public immutable aJPEG;

    /// @notice The airdrop's schedule.
    AirdropSchedule public airdropSchedule;

    mapping(address => bool) public hasClaimed;

    constructor(ITokenVesting vestingToken, bytes32 root) {
        merkleRoot = root;
        aJPEG = vestingToken;
        
        IERC20(vestingToken.token()).approve(address(vestingToken), 2 ** 256 - 1);
    }

    /// @notice Allows the owner to set the airdrop's schedule. Can only be called once. Can only be called by the owner.
    /// @param startTimestamp The vesting's start timestamp. Has to be greater 0. Can be less than `block.timestamp`.
    /// @param cliffDuration The vesting's cliff duration. Can be 0.
    /// @param duration The vesting's duration. Has to be greater than `cliffDuration`.
    /// @param airdropAmount The amount of tokens to be airdropped, per address. Has to be greater than 0.
    function setAidropSchedule(
        uint256 startTimestamp,
        uint256 cliffDuration,
        uint256 duration,
        uint256 airdropAmount
    ) external onlyOwner {
        require(airdropSchedule.startTimestamp == 0, "SCHEDULE_ALREADY_SET");
        require(startTimestamp > 0, "INVALID_START_TIMESTAMP");
        require(duration > cliffDuration, "INVALID_END_TIMESTAMP");
        require(airdropAmount > 0, "INVALID_AIRDROP_AMOUNT");

        airdropSchedule.startTimestamp = startTimestamp;
        airdropSchedule.cliffDuration = cliffDuration;
        airdropSchedule.duration = duration;
        airdropSchedule.airdropAmount = airdropAmount;
    }

    /// @notice Allows whitelisted users to claim their airdrop.
    /// @param merkleProof The merkle proof to verify.
    function claimAirdrop(bytes32[] calldata merkleProof) external {
        require(airdropSchedule.startTimestamp > 0, "SCHEDULE_NOT_SET");

        require(!hasClaimed[msg.sender], "ALREADY_CLAIMED");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, leaf),
            "INVALID_PROOF"
        );

        aJPEG.vestTokens(
            msg.sender,
            airdropSchedule.airdropAmount,
            airdropSchedule.startTimestamp,
            airdropSchedule.cliffDuration,
            airdropSchedule.duration
        );

        hasClaimed[msg.sender] = true;
    }

    /// @notice Withdraws tokens from this contract. Can only be called by the owner.
    /// @param token The token to withdraw.
    /// @param amount The amount of `token` to withdraw
    function rescueToken(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(owner(), amount);
    }
}