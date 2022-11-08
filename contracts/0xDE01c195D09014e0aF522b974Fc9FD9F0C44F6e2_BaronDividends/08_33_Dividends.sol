// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// This supports generic issuing of dividends
abstract contract Dividends {
    using MerkleProof for bytes32[];
    /**
     * @dev This contains the list of all dividends issued via {_issueDividend}.
     */
    mapping(uint256 => Dividend) public dividends;
    uint256 public dividendCount;

    /**
     * @dev This contains the state of a dividend that was issued via {_issueDividend}.
     */
    struct Dividend {
        // When we initiate a dividend this is the root of the tree containing all recipients.
        bytes32 recipientAmountMerkleRoot;
        // The total amount of the issued dividend.
        uint256 amountIssued;
        // The amount of the dividend that has been claimed.
        uint256 amountClaimed;
        // When the dividend was issued.
        uint256 issuedAt;
        // When the dividend expires (i.e. when issued amounts may be reclaimed if not claimed)
        uint256 withdrawDeadline;
        // This indicates when an address has claimed its dividend balance (or 0 if unclaimed).
        mapping(address => uint256) addressClaimedAt;
    }

    /**
     * @dev This specifies a recipients claim of funds from a dividend.
     */
    struct Claim {
        uint256 dividendId;
        address recipient;
        uint256 amount;
        bytes32[] proof;
    }

    /**
     * @dev Emitted by {_issueDividend} when a dividend for `amountIssued` identified by `id` is issued.
     */
    event DividendIssued(
        uint256 indexed dividendId,
        uint256 amountIssued,
        uint256 withdrawDeadline,
        string note
    );

    /**
     * @dev Emitted by {_claimMultipleDividendsOf} when `holder` claims their portion of dividend `id`.
     */
    event DividendClaimed(uint256 indexed dividendId, address indexed holder, uint256 amount);
    /**
     * @dev Emitted by {_withdrawExpiredDividends} when a dividend identified by `id` is reclaimed by the admin.
     */
    event DividendExpired(uint256 indexed dividendId, uint256 unclaimedAmount);

    // This should be called to issue a dividend.
    function _issueDividend(
        bytes32 recipientAmountMerkleRoot,
        uint256 amountIssued,
        uint256 withdrawDeadline,
        string calldata note
    ) internal {
        Dividend storage d = dividends[dividendCount];
        d.recipientAmountMerkleRoot = recipientAmountMerkleRoot;
        d.amountIssued = amountIssued;
        d.amountClaimed = 0;
        d.issuedAt = block.timestamp;
        d.withdrawDeadline = withdrawDeadline;
        emit DividendIssued(
            dividendCount,
            d.amountIssued,
            d.withdrawDeadline,
            note
        );
        dividendCount++;
    }

    // This returns dividend information.
    // Note: passing zero (0) as the `holder` will return just the generic info.
    function dividendInfoOfAt(uint256 dividendId, address holder)
        external
        view
        returns (
            uint256 amountIssued,
            uint256 amountClaimed,
            uint256 issuedAt,
            uint256 withdrawDeadline,
            uint256 holderClaimedAt
        )
    {
        require(dividendId < dividendCount, "bad dividend id");
        Dividend storage d = dividends[dividendId];
        amountIssued = d.amountIssued;
        amountClaimed = d.amountClaimed;
        issuedAt = d.issuedAt;
        withdrawDeadline = d.withdrawDeadline;
        holderClaimedAt = d.addressClaimedAt[holder];
    }

    // This claims multiple dividends on behalf of a single recipient.
    // It returns the total amount owed. The caller is expected to effect
    // the transfer of that balance to the `recipient`.
    function _claimMultipleDividendsOf(
        address recipient,
        Claim[] calldata claims
    ) internal virtual returns (uint256) {
        uint256 dividendBalance = 0;
        for (uint256 i = 0; i < claims.length; i++) {
            require(claims[i].recipient == recipient, "wrong recipient specified");
            _claimSingleDividend(claims[i]);
            dividendBalance += claims[i].amount;
        }
        return dividendBalance;
    }

    // This claims a single dividend.
    // It returns the total amount owed. The caller is expected to effect
    // the transfer of that balance to the `claim.recipient`.
    function _claimSingleDividend(
        Claim calldata claim
    ) internal virtual returns (uint256) {
        require(claim.amount > 0, "nothing to claim");
        require(claim.dividendId < dividendCount, "bad dividend id");
        Dividend storage d = dividends[claim.dividendId];
        require(block.timestamp <= d.withdrawDeadline, "deadline has passed");
        require(d.addressClaimedAt[claim.recipient] == 0, "already claimed");
        require(_verifyClaim(d.recipientAmountMerkleRoot, claim), "unable to verify recipient amount");
        d.amountClaimed += claim.amount;
        d.addressClaimedAt[claim.recipient] = block.timestamp;
        emit DividendClaimed(claim.dividendId, claim.recipient, claim.amount);
        return claim.amount;
    }

    // This verifies a claim. It returns whether the claim is valid against the provided root.
    // NOTE: the dividendId in the claim is ignored (this allows verifying samples before the dividend is issued).
    function _verifyClaim(
        bytes32 recipientAmountMerkleRoot,
        Claim calldata claim
    ) internal pure returns (bool) {
        return claim.proof.verify(
            recipientAmountMerkleRoot,
            keccak256(abi.encodePacked(claim.recipient, claim.amount))
        );
    }

    // This lets an admin reclaim all expired dividends.
    // It returns the total amount reclaimed. The caller is expected to
    // effect the transfer of that balance to the admin.
    // To inspect the balance without reclaiming, see expiredDividendsBalance().
    function _withdrawExpiredDividends() internal returns (uint256) {
        uint256 expiredBalance = 0;
        for (uint256 i = 0; i < dividendCount; i++) {
            Dividend storage d = dividends[i];
            uint256 unclaimedAmount = d.amountIssued - d.amountClaimed;
            if (block.timestamp > d.withdrawDeadline && unclaimedAmount > 0) {
                expiredBalance += unclaimedAmount;
                d.amountClaimed = d.amountIssued;
                emit DividendExpired(i, unclaimedAmount);
            }
        }
        return expiredBalance;
    }

    // This calculates the unclaimed balance of expired dividends.
    // It is the amount that the admin will received via _withdrawExpiredDividends()
    function expiredDividendsBalance() external view returns (uint256) {
        uint256 expiredBalance = 0;
        for (uint256 i = 0; i < dividendCount; i++) {
            Dividend storage d = dividends[i];
            uint256 unclaimedAmount = d.amountIssued - d.amountClaimed;
            if (block.timestamp > d.withdrawDeadline && unclaimedAmount > 0) {
                expiredBalance += unclaimedAmount;
            }
        }
        return expiredBalance;
    }
}