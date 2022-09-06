// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "../libraries/LoanLibrary.sol";

interface ISignatureVerifier {
    // ============== Collateral Verification ==============

    function verifyPredicates(bytes calldata predicates, address vault) external view returns (bool);
}