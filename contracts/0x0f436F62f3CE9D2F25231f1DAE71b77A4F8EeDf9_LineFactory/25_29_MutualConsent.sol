// SPDX-License-Identifier: GPL-3.0
// Copyright: https://github.com/test-org2222/Line-Of-Credit/blog/master/COPYRIGHT.md

// forked from https://github.com/IndexCoop/index-coop-smart-contracts/blob/master/contracts/lib/MutualConsent.sol

 pragma solidity ^0.8.16;

/**
 * @title MutualConsent
 * @author Set Protocol
 *
 * The MutualConsent contract contains a modifier for handling mutual consents between two parties
 */
abstract contract MutualConsent {
    /* ============ State Variables ============ */

    // equivalent to longest msg.data bytes, ie addCredit
    uint256 constant MAX_DATA_LENGTH_BYTES = 164;

    // equivalent to any fn with no args, ie just a fn selector
    uint256 constant MIN_DATA_LENGTH_BYTES = 4;

    // Mapping of upgradable units and if consent has been initialized by other party
    mapping(bytes32 => address) public mutualConsentProposals;

    error Unauthorized();
    error InvalidConsent();
    error NotUserConsent();
    error NonZeroEthValue();

    // causes revert when the msg.data passed in has more data (ie arguments) than the largest known fn signature
    error UnsupportedMutualConsentFunction();

    /* ============ Events ============ */

    event MutualConsentRegistered(bytes32 proposalId, address taker);
    event MutualConsentRevoked(bytes32 proposalId);
    event MutualConsentAccepted(bytes32 proposalId);

    /* ============ Modifiers ============ */

    /**
     * @notice - allows a function to be called if only two specific stakeholders signoff on the tx data
     *         - signers can be anyone. only two signers per contract or dynamic signers per tx.
     */
    modifier mutualConsent(address _signerOne, address _signerTwo) {
        if (_mutualConsent(_signerOne, _signerTwo)) {
            // Run whatever code needed 2/2 consent
            _;
        }
    }

    /**
     *  @notice - allows a caller to revoke a previously created consent
     *  @dev    - MAX_DATA_LENGTH_BYTES is set at 164 bytes, which is the length of the msg.data
     *          - for the addCredit function. Anything over that is not valid and might be used in
     *          - an attempt to create a hash collision
     *  @param  _reconstrucedMsgData The reconstructed msg.data for the function call for which the
     *          original consent was created - comprised of the fn selector (bytes4) and abi.encoded
     *          function arguments.
     *
     */
    function revokeConsent(bytes calldata _reconstrucedMsgData) external {
        if (
            _reconstrucedMsgData.length > MAX_DATA_LENGTH_BYTES || _reconstrucedMsgData.length < MIN_DATA_LENGTH_BYTES
        ) {
            revert UnsupportedMutualConsentFunction();
        }

        bytes32 proposalIdToDelete = keccak256(abi.encodePacked(_reconstrucedMsgData, msg.sender));

        address consentor = mutualConsentProposals[proposalIdToDelete];

        if (consentor == address(0)) {
            revert InvalidConsent();
        }
        if (consentor != msg.sender) {
            revert NotUserConsent();
        } // note: cannot test, as no way to know what data (+msg.sender) would cause hash collision

        delete mutualConsentProposals[proposalIdToDelete];

        emit MutualConsentRevoked(proposalIdToDelete);
    }

    /* ============ Internal Functions ============ */

    function _mutualConsent(address _signerOne, address _signerTwo) internal returns (bool) {
        if (msg.sender != _signerOne && msg.sender != _signerTwo) {
            revert Unauthorized();
        }

        address nonCaller = _getNonCaller(_signerOne, _signerTwo);

        // The consent hash is defined by the hash of the transaction call data and sender of msg,
        // which uniquely identifies the function, arguments, and sender.
        bytes32 expectedProposalId = keccak256(abi.encodePacked(msg.data, nonCaller));

        if (mutualConsentProposals[expectedProposalId] == address(0)) {
            bytes32 newProposalId = keccak256(abi.encodePacked(msg.data, msg.sender));

            mutualConsentProposals[newProposalId] = msg.sender; // save caller's consent for nonCaller to accept

            emit MutualConsentRegistered(newProposalId, nonCaller);

            return false;
        }

        delete mutualConsentProposals[expectedProposalId];

        emit MutualConsentAccepted(expectedProposalId);

        return true;
    }

    function _getNonCaller(address _signerOne, address _signerTwo) internal view returns (address) {
        return msg.sender == _signerOne ? _signerTwo : _signerOne;
    }
}