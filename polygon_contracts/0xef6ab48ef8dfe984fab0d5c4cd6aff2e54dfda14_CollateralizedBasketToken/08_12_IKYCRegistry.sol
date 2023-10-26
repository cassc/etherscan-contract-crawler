// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Solid World
interface IKYCRegistry {
    error InvalidVerifier();
    error VerificationNotAuthorized(address caller);

    event VerifierUpdated(address indexed oldVerifier, address indexed newVerifier);
    event Verified(address indexed subject);
    event VerificationRevoked(address indexed subject);

    function setVerifier(address newVerifier) external;

    function registerVerification(address subject) external;

    function revokeVerification(address subject) external;

    function getVerifier() external view returns (address);

    function isVerified(address subject) external view returns (bool);
}