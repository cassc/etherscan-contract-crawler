// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
The ResearchTokenFactory contract creates cloned ResearchToken contracts. It 
uses clone2 and is deterministic conditioned on minting address and research 
identifier.
*/

import "@openzeppelin/contracts/access/Ownable.sol";

import "../libraries/Clones.sol";
import "./MerkleDistribution.sol";
import "./ResearchTokenInput.sol";
import "./ResearchToken.sol";

contract ResearchTokenFactory is Ownable {
    using Clones for address;

    address immutable impl;

    error ResearchIdentifierEmpty();

    constructor() {
        impl = address(new ResearchToken());
    }

    event CreateResearchToken(address token);

    /*
        This function returns the salt used for clone2.
        Args:
            researchIdentifier: the research identifier.
            minter: the minter address.
        Returns:
            the salt.
    */
    function _getSalt(
        string memory researchIdentifier,
        address minter
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    type(ResearchToken).creationCode,
                    researchIdentifier,
                    minter
                )
            );
    }

    /*
        This function creates a research token.
        Args:
            minter: The address recipient, likely minter, so referred to as such.
            input: A ResearchTokenInput.sol struct.
        Returns:
            the address of the cloned research token.
    */
    function createResearchToken(
        address minter,
        ResearchTokenInput memory input
    ) external onlyOwner returns (address) {
        if (bytes(input.researchIdentifier).length == 0) {
            revert ResearchIdentifierEmpty();
        }
        bytes32 salt = _getSalt(input.researchIdentifier, minter);
        address payable clone = payable(impl.cloneDeterministic(salt));
        ResearchToken(clone).initialize(input, minter);
        emit CreateResearchToken(clone);
        return clone;
    }

    /*
        This function returns the predicted clone2 address of a research token 
        given the research identifier and minter.
        Args:
            researchIdentifier: the research identifier.
            minter: the minter address.
        Returns:
            the predicted clone2 address.
    */
    function getResearchTokenPredictedAddress(
        string memory researchIdentifier,
        address minter
    ) external view returns (address) {
        bytes32 salt = _getSalt(researchIdentifier, minter);
        return impl.predictDeterministicAddress(salt);
    }
}