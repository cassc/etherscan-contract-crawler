// SPDX-License-Identifier: None
pragma solidity = 0.8.17;

import "../libraries/ProofFactoryFees.sol";
interface IProofFactoryTokenCutter {
    function setBasicData(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 initialSupply,
        uint percentToLP,
        address owner,
        address reflectionToken,
        address routerAddress,
        address initialProofAdmin,
        ProofFactoryFees.allFees memory fees
    ) external;
}