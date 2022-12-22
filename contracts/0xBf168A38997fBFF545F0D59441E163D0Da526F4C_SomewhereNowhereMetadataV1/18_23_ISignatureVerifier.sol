// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './IRoles.sol';

interface ISignatureVerifier is IRoles {
    error SignatureIsNotValid();

    error SigningAddressIsZeroAddress();

    event SigningAddressUpdated(address indexed signingAddress);

    function setSigningAddress(address signingAddress) external;

    function getSigningAddress() external view returns (address);
}