// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.19;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;
}

contract ClaimPepeGpt is Ownable {
    uint256 public constant CLAIM_GRACE = 60 days;

    using SafeERC20 for IERC20Burnable;

    IERC20Burnable public immutable pepeGpt;
    bytes32 public immutable merkleRoot;

    mapping(address => bool) public hasClaimed;
    uint256 public immutable deployTime;
    uint256 public startTime;

    address public immutable treasury;

    error AlreadyClaimed();
    error NotInMerkle();
    error NotStarted();
    error ClaimGrace();
    error WithdrawingPepe();

    constructor(
        address _pepeGpt,
        bytes32 _merkleRoot,
        uint256 _startTime,
        address _treasury
    ) {
        merkleRoot = _merkleRoot;
        pepeGpt = IERC20Burnable(_pepeGpt);
        deployTime = block.timestamp;
        startTime = _startTime;
        treasury = _treasury;
    }

    event Claim(address indexed to, uint256 amount);

    function claim(
        address to,
        uint256 amount,
        bytes32[] calldata proof
    ) external {
        if (block.timestamp < startTime) revert NotStarted();
        if (hasClaimed[to]) revert AlreadyClaimed();

        bytes32 leaf = keccak256(abi.encodePacked(to, amount));
        bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
        if (!isValidLeaf) revert NotInMerkle();

        hasClaimed[to] = true;

        pepeGpt.safeTransfer(to, amount);

        emit Claim(to, amount);
    }

    function burnRemaining() external {
        if (block.timestamp < startTime + CLAIM_GRACE) revert ClaimGrace();

        uint256 balance = pepeGpt.balanceOf(address(this));
        pepeGpt.burn(balance);
    }

    // This function is used to withdraw unclaimed pepeGPT in an emergency.
    // Owner will be renounced once claims are verified.
    function withdraw() external onlyOwner {
        uint256 balance = pepeGpt.balanceOf(address(this));
        pepeGpt.safeTransfer(treasury, balance);
    }

    // This function is used to withdraw any other token accidentally sent to this contract.
    // It is sent to pepeGPT treasury.
    // Token might MAYBE be recoverable.
    function emergencyWithdraw(IERC20Burnable token) external {
        if (address(token) == address(pepeGpt)) revert WithdrawingPepe();

        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(treasury, balance);
    }

    // Update start time
    function updateStartTime(uint256 _startTime) external onlyOwner {
        require(block.timestamp < startTime, "Already started");
        startTime = _startTime;
    }
}