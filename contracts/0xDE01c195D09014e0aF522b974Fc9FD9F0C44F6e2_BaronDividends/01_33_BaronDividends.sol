// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./lib/Dividends.sol";
import "./lib/BaronBase.sol";

contract BaronDividends is BaronBase, Dividends, ReentrancyGuard {
    using Address for address payable;
    using SafeMath for uint256;

    // This allows recipients to claim their dividends.
    function claimDividends(
        Claim[] calldata claims
    ) external nonReentrant whenNotPaused {
        uint256 balance = _claimMultipleDividendsOf(
            msg.sender,
            claims
        );
        require(balance > 0, "no dividend balance to claim");
        payable(msg.sender).sendValue(balance);
    }

    // This allows a caller to initiate claiming of dividends on behalf of `recipients`.
    // NOTE: the recipient receives the dividend value, not the caller.
    // NOTE: for a single recipient, this is less efficient than having them call claimDividends().
    function claimDividendsFor(
        Claim[] calldata claims
    ) external nonReentrant whenNotPaused {
        // TODO PERF(gas): consider batching sendValue calls by recipient
        // TODO PERF(gas): consider batching dividend state updates by dividendId
        // TODO: consider permitting only the operator to call
        for (uint256 i = 0; i < claims.length; i++) {
            _claimSingleDividend(claims[i]);
            payable(claims[i].recipient).sendValue(claims[i].amount);
        }
    }

    // Admin Methods

    // This allows the Baron to issue a dividend.
    // For safety, this also receives sample claims for verification.
    function issueDividend(
        bytes32 recipientAmountMerkleRoot,
        uint256 withdrawDeadline,
        Claim[] calldata samples,
        string calldata note
    ) external payable onlyOperator {
        require(msg.value > 0, "the dividend cannot have zero value");

        // Verify that all of the samples are in the tree as expected.
        for (uint256 i = 0; i < samples.length; i++) {
            require(
                _verifyClaim(recipientAmountMerkleRoot, samples[i]),
                "unable to verify sample claim"
            );
        }

        _issueDividend(
            recipientAmountMerkleRoot,
            msg.value,
            withdrawDeadline,
            note
        );
    }

    // This allows the Baron to reclaim any unclaimed dividends after expiry.
    function withdrawExpiredDividends() external onlyOperator {
        uint256 balance = _withdrawExpiredDividends();
        require(balance > 0, "no expired dividend balance to withdraw");
        treasury.sendValue(balance);
    }
}