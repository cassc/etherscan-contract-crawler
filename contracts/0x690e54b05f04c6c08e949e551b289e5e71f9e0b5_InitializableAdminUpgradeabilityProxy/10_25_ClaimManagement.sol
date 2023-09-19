// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "./ClaimConfig.sol";
import "./interfaces/IProtocol.sol";
import "./interfaces/IProtocolFactory.sol";
import "./interfaces/IClaimManagement.sol";

/**
 * @title Claim Management for claims filed for a COVER supported protocol
 * @author Alan
 */
contract ClaimManagement is IClaimManagement, ClaimConfig {
    using SafeMath for uint256;

    // protocol => nonce => Claim[]
    mapping(address => mapping(uint256 => Claim[])) public override protocolClaims;

    modifier onlyApprovedDecider() {
        if (isAuditorVoting()) {
            require(msg.sender == auditor, "COVER_CM: !auditor");
        } else {
            require(msg.sender == governance, "COVER_CM: !governance");
        }
        _;
    }

    modifier onlyWhenAuditorVoting() {
        require(isAuditorVoting(), "COVER_CM: !isAuditorVoting");
        _;
    }

    /**
     * @notice Initialize governance and treasury addresses
     * @dev Governance address cannot be set to owner address; `_auditor` can be 0.
     * @param _governance address: address of the governance account
     * @param _auditor address: address of the auditor account
     * @param _treasury address: address of the treasury account
     * @param _protocolFactory address: address of the protocol factory
     */
    constructor(address _governance, address _auditor, address _treasury, address _protocolFactory) {
        require(
            _governance != msg.sender && _governance != address(0), 
            "COVER_CC: governance cannot be owner or 0"
        );
        require(_treasury != address(0), "COVER_CM: treasury cannot be 0");
        require(_protocolFactory != address(0), "COVER_CM: protocol factory cannot be 0");
        governance = _governance;
        auditor = _auditor;
        treasury = _treasury;
        protocolFactory = _protocolFactory;

        initializeOwner();
    }

    /**
     * @notice File a claim for a COVER-supported contract `_protocol` 
     * by paying the `protocolClaimFee[_protocol]` fee
     * @dev `_incidentTimestamp` must be within the past 14 days
     * @param _protocol address: contract address of the protocol that COVER supports
     * @param _protocolName bytes32: protocol name for `_protocol`
     * @param _incidentTimestamp uint48: timestamp of the claim incident
     * 
     * Emits ClaimFiled
     */ 
    function fileClaim(address _protocol, bytes32 _protocolName, uint48 _incidentTimestamp) 
        external 
        override 
    {
        require(_protocol != address(0), "COVER_CM: protocol cannot be 0");
        require(
            _protocol == getAddressFromFactory(_protocolName), 
            "COVER_CM: invalid protocol address"
        );
        require(
            block.timestamp.sub(_incidentTimestamp) <= getFileClaimWindow(_protocol),
            "COVER_CM: block.timestamp - incidentTimestamp > fileClaimWindow"
        );
        uint256 nonce = getProtocolNonce(_protocol);
        uint256 claimFee = getProtocolClaimFee(_protocol);
        protocolClaims[_protocol][nonce].push(Claim({
            state: ClaimState.Filed,
            filedBy: msg.sender,
            payoutNumerator: 0,
            payoutDenominator: 1,
            filedTimestamp: uint48(block.timestamp),
            incidentTimestamp: _incidentTimestamp,
            decidedTimestamp: 0,
            feePaid: claimFee
        }));
        feeCurrency.transferFrom(msg.sender, address(this), claimFee);
        _updateProtocolClaimFee(_protocol);
        emit ClaimFiled({
            isForced: false,
            filedBy: msg.sender,
            protocol: _protocol,
            incidentTimestamp: _incidentTimestamp,
            nonce: nonce,
            index: protocolClaims[_protocol][nonce].length - 1,
            feePaid: claimFee
        });
    }

    /**
     * @notice Force file a claim for a COVER-supported contract `_protocol`
     * that bypasses validateClaim by paying the `forceClaimFee` fee
     * @dev `_incidentTimestamp` must be within the past 14 days. 
     * Only callable when isAuditorVoting is true
     * @param _protocol address: contract address of the protocol that COVER supports
     * @param _protocolName bytes32: protocol name for `_protocol`
     * @param _incidentTimestamp uint48: timestamp of the claim incident
     * 
     * Emits ClaimFiled
     */
    function forceFileClaim(address _protocol, bytes32 _protocolName, uint48 _incidentTimestamp)
        external 
        override 
        onlyWhenAuditorVoting 
    {
        require(_protocol != address(0), "COVER_CM: protocol cannot be 0");
        require(
            _protocol == getAddressFromFactory(_protocolName), 
            "COVER_CM: invalid protocol address"
        );  
        require(
            block.timestamp.sub(_incidentTimestamp) <= getFileClaimWindow(_protocol),
            "COVER_CM: block.timestamp - incidentTimestamp > fileClaimWindow"
        );
        uint256 nonce = getProtocolNonce(_protocol);
        protocolClaims[_protocol][nonce].push(Claim({
            state: ClaimState.ForceFiled,
            filedBy: msg.sender,
            payoutNumerator: 0,
            payoutDenominator: 1,
            filedTimestamp: uint48(block.timestamp),
            incidentTimestamp: _incidentTimestamp,
            decidedTimestamp: 0,
            feePaid: forceClaimFee
        }));
        feeCurrency.transferFrom(msg.sender, address(this), forceClaimFee);
        emit ClaimFiled({
            isForced: true,
            filedBy: msg.sender,
            protocol: _protocol,
            incidentTimestamp: _incidentTimestamp,
            nonce: nonce,
            index: protocolClaims[_protocol][nonce].length - 1,
            feePaid: forceClaimFee
        });
    }

    /**
     * @notice Validates whether claim will be passed to approvedDecider to decideClaim
     * @dev Only callable if isAuditorVoting is true
     * @param _protocol address: contract address of the protocol that COVER supports
     * @param _nonce uint256: nonce of the protocol
     * @param _index uint256: index of the claim
     * @param _claimIsValid bool: true if claim is valid and passed to auditor, false otherwise
     *     
     * Emits ClaimValidated
     */
    function validateClaim(address _protocol, uint256 _nonce, uint256 _index, bool _claimIsValid)
        external 
        override 
        onlyGovernance
        onlyWhenAuditorVoting 
    {
        Claim storage claim = protocolClaims[_protocol][_nonce][_index];
        require(
            _nonce == getProtocolNonce(_protocol), 
            "COVER_CM: input nonce != protocol nonce"
            );
        require(claim.state == ClaimState.Filed, "COVER_CM: claim not filed");
        if (_claimIsValid) {
            claim.state = ClaimState.Validated;
            _resetProtocolClaimFee(_protocol);
        } else {
            claim.state = ClaimState.Invalidated;
            claim.decidedTimestamp = uint48(block.timestamp);
            feeCurrency.transfer(treasury, claim.feePaid);
        }
        emit ClaimValidated({
            claimIsValid: _claimIsValid,
            protocol: _protocol,
            nonce: _nonce,
            index: _index
        });
    }

    /**
     * @notice Decide whether claim for a protocol should be accepted(will payout) or denied
     * @dev Only callable by approvedDecider
     * @param _protocol address: contract address of the protocol that COVER supports
     * @param _nonce uint256: nonce of the protocol
     * @param _index uint256: index of the claim
     * @param _claimIsAccepted bool: true if claim is accepted and will payout, otherwise false
     * @param _payoutNumerator uint256: numerator of percent payout, 0 if _claimIsAccepted = false
     * @param _payoutDenominator uint256: denominator of percent payout
     *
     * Emits ClaimDecided
     */
    function decideClaim(
        address _protocol, 
        uint256 _nonce, 
        uint256 _index, 
        bool _claimIsAccepted, 
        uint16 _payoutNumerator, 
        uint16 _payoutDenominator
    )   
        external
        override 
        onlyApprovedDecider
    {
        require(
            _nonce == getProtocolNonce(_protocol), 
            "COVER_CM: input nonce != protocol nonce"
        );
        Claim storage claim = protocolClaims[_protocol][_nonce][_index];
        if (isAuditorVoting()) {
            require(
                claim.state == ClaimState.Validated || 
                claim.state == ClaimState.ForceFiled, 
                "COVER_CM: claim not validated or forceFiled"
            );
        } else {
            require(claim.state == ClaimState.Filed, "COVER_CM: claim not filed");
        }

        if (_isDecisionWindowPassed(claim)) {
            // Max decision claim window passed, claim is default to Denied
            _claimIsAccepted = false;
        }
        if (_claimIsAccepted) {
            require(_payoutNumerator > 0, "COVER_CM: claim accepted, but payoutNumerator == 0");
            if (allowPartialClaim) {
                require(
                    _payoutNumerator <= _payoutDenominator, 
                    "COVER_CM: payoutNumerator > payoutDenominator"
                );
            } else {
                require(
                    _payoutNumerator == _payoutDenominator, 
                    "COVER_CM: payoutNumerator != payoutDenominator"
                );
            }
            claim.state = ClaimState.Accepted;
            claim.payoutNumerator = _payoutNumerator;
            claim.payoutDenominator = _payoutDenominator;
            feeCurrency.transfer(claim.filedBy, claim.feePaid);
            _resetProtocolClaimFee(_protocol);
            IProtocol(_protocol).enactClaim(_payoutNumerator, _payoutDenominator, claim.incidentTimestamp, _nonce);
        } else {
            require(_payoutNumerator == 0, "COVER_CM: claim denied (default if passed window), but payoutNumerator != 0");
            claim.state = ClaimState.Denied;
            feeCurrency.transfer(treasury, claim.feePaid);
        }
        claim.decidedTimestamp = uint48(block.timestamp);
        emit ClaimDecided({
            claimIsAccepted: _claimIsAccepted, 
            protocol: _protocol, 
            nonce: _nonce, 
            index: _index, 
            payoutNumerator: _payoutNumerator, 
            payoutDenominator: _payoutDenominator
        });
    }

    /**
     * @notice Get all claims for protocol `_protocol` and nonce `_nonce` in state `_state`
     * @param _protocol address: contract address of the protocol that COVER supports
     * @param _nonce uint256: nonce of the protocol
     * @param _state ClaimState: state of claim
     * @return all claims for protocol and nonce in given state
     */
    function getAllClaimsByState(address _protocol, uint256 _nonce, ClaimState _state)
        external 
        view 
        override 
        returns (Claim[] memory) 
    {
        Claim[] memory allClaims = protocolClaims[_protocol][_nonce];
        uint256 count;
        Claim[] memory temp = new Claim[](allClaims.length);
        for (uint i = 0; i < allClaims.length; i++) {
            if (allClaims[i].state == _state) {
                temp[count] = allClaims[i];
                count++;
            }
        }
        Claim[] memory claimsByState = new Claim[](count);
        for (uint i = 0; i < count; i++) {
            claimsByState[i] = temp[i];
        }
        return claimsByState;
    }

    /**
     * @notice Get all claims for protocol `_protocol` and nonce `_nonce`
     * @param _protocol address: contract address of the protocol that COVER supports
     * @param _nonce uint256: nonce of the protocol
     * @return all claims for protocol and nonce
     */
    function getAllClaimsByNonce(address _protocol, uint256 _nonce) 
        external 
        view 
        override 
        returns (Claim[] memory) 
    {
        return protocolClaims[_protocol][_nonce];
    }

    /**
     * @notice Get the protocol address from the protocol factory
     * @param _protocolName bytes32: protocol name
     * @return address corresponding to the protocol name `_protocolName`
     */
    function getAddressFromFactory(bytes32 _protocolName) public view override returns (address) {
        return IProtocolFactory(protocolFactory).protocols(_protocolName);
    }

    /**
     * @notice Get the current nonce for protocol `_protocol`
     * @param _protocol address: contract address of the protocol that COVER supports
     * @return the current nonce for protocol `_protocol`
     */
    function getProtocolNonce(address _protocol) public view override returns (uint256) {
        return IProtocol(_protocol).claimNonce();
    }

    /**
     * The times passed since the claim was filed has to be less than the max claim decision window
     */
    function _isDecisionWindowPassed(Claim memory claim) private view returns (bool) {
        return block.timestamp.sub(claim.filedTimestamp) > maxClaimDecisionWindow.sub(1 hours);
    }
}