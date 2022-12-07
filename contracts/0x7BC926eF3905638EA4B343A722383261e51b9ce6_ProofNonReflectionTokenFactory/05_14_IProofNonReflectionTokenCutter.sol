// SPDX-License-Identifier: None
pragma solidity = 0.8.17;

import "../libraries/ProofNonReflectionTokenFees.sol";
interface IProofNonReflectionTokenCutter {
    function setBasicData(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 initialSupply,
        uint percentToLP,
        address owner,
        address dev,
        address main,
        address routerAddress,
        address initialProofAdmin,
        ProofNonReflectionTokenFees.allFees memory fees
    ) external;
}