// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./ILiqdRentalVault.sol";

interface IInvokeVerifier {
    function verify(
        address target,
        uint256 value,
        bytes calldata data,
        address caller,
        address owner,
        ILiqdRentalVault.Rental memory rental
    ) external returns (bool);
}