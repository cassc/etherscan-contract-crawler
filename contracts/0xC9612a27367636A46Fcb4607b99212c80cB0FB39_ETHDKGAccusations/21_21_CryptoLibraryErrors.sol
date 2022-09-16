// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library CryptoLibraryErrors {
    error EllipticCurveAdditionFailed();
    error EllipticCurveMultiplicationFailed();
    error ModularExponentiationFailed();
    error EllipticCurvePairingFailed();
    error HashPointNotOnCurve();
    error HashPointUnsafeForSigning();
    error PointNotOnCurve();
    error SignatureIndicesLengthMismatch(uint256 signaturesLength, uint256 indicesLength);
    error SignaturesLengthThresholdNotMet(uint256 signaturesLength, uint256 threshold);
    error InverseArrayIncorrect();
    error InvalidInverseArrayLength();
    error KMustNotEqualJ();
}