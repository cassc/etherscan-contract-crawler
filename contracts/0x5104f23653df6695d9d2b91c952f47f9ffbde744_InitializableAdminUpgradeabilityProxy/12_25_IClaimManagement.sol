// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

/**
 * @dev ClaimManagement contract interface. See {ClaimManagement}.
 * @author Alan
 */
 interface IClaimManagement {
    enum ClaimState { Filed, ForceFiled, Validated, Invalidated, Accepted, Denied }
    struct Claim {
        ClaimState state; // Current state of claim
        address filedBy; // Address of user who filed claim
        uint16 payoutNumerator; // Numerator of percent to payout
        uint16 payoutDenominator; // Denominator of percent to payout
        uint48 filedTimestamp; // Timestamp of submitted claim
        uint48 incidentTimestamp; // Timestamp of the incident the claim is filed for
        uint48 decidedTimestamp; // Timestamp when claim outcome is decided
        uint256 feePaid; // Fee paid to file the claim
    }

    function protocolClaims(address _protocol, uint256 _nonce, uint256 _index) external view returns (        
        ClaimState state,
        address filedBy,
        uint16 payoutNumerator,
        uint16 payoutDenominator,
        uint48 filedTimestamp,
        uint48 incidentTimestamp,
        uint48 decidedTimestamp,
        uint256 feePaid
    );
    
    function fileClaim(address _protocol, bytes32 _protocolName, uint48 _incidentTimestamp) external;
    function forceFileClaim(address _protocol, bytes32 _protocolName, uint48 _incidentTimestamp) external;
    
    // @dev Only callable by owner when auditor is voting
    function validateClaim(address _protocol, uint256 _nonce, uint256 _index, bool _claimIsValid) external;

    // @dev Only callable by approved decider
    function decideClaim(address _protocol, uint256 _nonce, uint256 _index, bool _claimIsAccepted, uint16 _payoutNumerator, uint16 _payoutDenominator) external;

    function getAllClaimsByState(address _protocol, uint256 _nonce, ClaimState _state) external view returns (Claim[] memory);
    function getAllClaimsByNonce(address _protocol, uint256 _nonce) external view returns (Claim[] memory);
    function getAddressFromFactory(bytes32 _protocolName) external view returns (address);
    function getProtocolNonce(address _protocol) external view returns (uint256);
    
    event ClaimFiled(
        bool indexed isForced,
        address indexed filedBy, 
        address indexed protocol, 
        uint48 incidentTimestamp,
        uint256 nonce, 
        uint256 index, 
        uint256 feePaid
    );
    event ClaimValidated(
        bool indexed claimIsValid,
        address indexed protocol, 
        uint256 nonce, 
        uint256 index
    );
    event ClaimDecided(
        bool indexed claimIsAccepted,
        address indexed protocol, 
        uint256 nonce, 
        uint256 index, 
        uint16 payoutNumerator, 
        uint16 payoutDenominator
    );
 }