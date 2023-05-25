// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/cryptography/MerkleProof.sol';

/** @notice
 * This is a rewards distributor contract which implements a tax model designed to incetivise
 * long term supporters of the protocol. Rewards are distributed by publishing merkle roots.
 * Users can submit merkle proofs to partially or fully withdraw their rewards at any time but
 * there is a `taxingPeriod` that applies to each merkle root. During this time rewards are
 * taxed in proportion to the time remaining until the end of the `taxingPeriod`:
 * tax = amount * (taxingPeriodEnd - now) / taxingPeriod
 * Collected taxes will be distributed back to the community via merkle roots.
 */
contract RewardsDistributor is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct MerkleClaim {
        bytes32 merkleRoot;
        uint256 amountAvailable;
        bytes32[] merkleProof;
    }

    struct Schedule {
        uint256 startTime;
        uint256 taxingPeriod;
    }

    event NewMerkleRoot(bytes32 merkleRoot, string reason);
    event Claim(address user, uint256 amountReceived, uint256 tax);

    address public immutable token;
    address public treasury;

    /// @notice Maps a merkle root to its taxing schedule (startTime, taxingPeriod)
    mapping(bytes32 => Schedule) public schedule;

    /// @dev (user => (merkleRoot => amount_claimed))
    mapping(address => mapping(bytes32 => uint256)) public userClaims;

    constructor(address _token) public Ownable() {
        token = _token;
        treasury = msg.sender;
    }

    /// @notice Publish a new merkle root with a taxingPeriod and reason
    function publishMerkleRoot(
        bytes32 newMerkleRoot,
        uint256 taxingPeriod,
        string calldata reason
    ) external onlyOwner {
        require(schedule[newMerkleRoot].startTime == 0, 'Merkle root duplicate');
        schedule[newMerkleRoot].startTime = now;
        schedule[newMerkleRoot].taxingPeriod = taxingPeriod;
        emit NewMerkleRoot(newMerkleRoot, reason);
    }

    /// @notice Claim up to maxAmount from claims, taxing if necessary
    function claim(uint256 maxAmount, MerkleClaim[] calldata claims)
        external
        returns (uint256 amountReceived, uint256 totalTax)
    {
        uint256 amountClaimed;
        for (uint256 i = 0; amountClaimed < maxAmount && i < claims.length; i++) {
            (uint256 amount, uint256 tax) = claimMerkleRoot(maxAmount - amountClaimed, claims[i]);
            amountClaimed = amountClaimed.add(amount);
            totalTax = totalTax.add(tax);
        }
        amountReceived = amountClaimed.sub(totalTax);

        IERC20(token).safeTransfer(msg.sender, amountReceived);
        IERC20(token).safeTransfer(treasury, totalTax);

        emit Claim(msg.sender, amountReceived, totalTax);
    }

    /// @dev Perform state changes for claiming up to `maxAmount` from `aClaim`
    function claimMerkleRoot(uint256 maxAmount, MerkleClaim calldata aClaim)
        private
        returns (uint256 amount, uint256 tax)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, aClaim.amountAvailable));
        require(MerkleProof.verify(aClaim.merkleProof, aClaim.merkleRoot, leaf), 'Invalid merkle proof');

        uint256 startTime = schedule[aClaim.merkleRoot].startTime;
        require(startTime != 0, 'This merkle root does not exist');

        uint256 alreadyClaimed = userClaims[msg.sender][aClaim.merkleRoot];
        require(alreadyClaimed < aClaim.amountAvailable, 'This merkle root was already claimed');

        uint256 amountRemaining = aClaim.amountAvailable - alreadyClaimed;
        amount = maxAmount < amountRemaining ? maxAmount : amountRemaining;
        userClaims[msg.sender][aClaim.merkleRoot] = alreadyClaimed.add(amount);

        uint256 taxingPeriod = schedule[aClaim.merkleRoot].taxingPeriod;
        uint256 taxingPeriodEnd = startTime.add(taxingPeriod);
        tax = now < taxingPeriodEnd ? amount.mul(taxingPeriodEnd - now).div(taxingPeriod) : 0;
    }

    /// @dev Added to support migrating the treasury
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), 'Cannot set treasury to 0');
        treasury = _treasury;
    }

    /// @dev Added to support recovering tokens sent by mistake or from airdrops
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
    }
}