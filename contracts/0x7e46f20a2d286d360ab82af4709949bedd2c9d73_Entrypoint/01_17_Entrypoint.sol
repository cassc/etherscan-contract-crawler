// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
This Entrypoint contract is what the website uses to interact with the rest of
the system. Users may interact with other contracts directly.
*/

import "../token/ResearchTokenFactory.sol";
import "../token/ResearchTokenInput.sol";
import "../distributor/DistributorV2Factory.sol";

contract Entrypoint {
    DistributorV2Factory immutable distributorFactory;
    ResearchTokenFactory immutable tokenFactory;

    constructor(address researchPortfolioGnosis) {
        // The researchPortfolioGnosis should be one of the following:
        // Goerli: 0x6f07856f4974A32a54A0A0045eDfAEd97Cc78136
        // Mainnet: 0xAAbF8DC8c8208e023c5D8e2d0e3dd30415559E0E
        distributorFactory = new DistributorV2Factory(researchPortfolioGnosis);
        tokenFactory = new ResearchTokenFactory();
    }

    error IncompatibleSizeInputs(uint256 addressSize, uint256 amountSize);

    event CreateResearchTokenAndDistributor(address token, address distributor);
    event CreateDistributorV2(address distributor);

    // This function creates a ResearchToken, then mints it to recipients and
    // distributes it to claimers.
    // Args:
    //  input: A ResearchTokenInput struct.
    //  merkleDistribution: A MerkleDistribution struct.
    //  addresses: a list of addresses to distribute to.
    //  amounts: a list of amounts to distribute; same length as addresses.
    // Returns:
    //  the address of the research token.
    //  the address of the distributor, possibly 0x0 if nothing to distribute.
    function createAndDistributeResearchToken(
        ResearchTokenInput memory input,
        MerkleDistribution memory merkleDistribution,
        address[] memory addresses,
        uint256[] memory amounts
    ) external returns (address, address) {
        if (addresses.length != amounts.length) {
            revert IncompatibleSizeInputs(addresses.length, amounts.length);
        }

        address minter = msg.sender;

        address token = tokenFactory.createResearchToken(minter, input);

        address distributor;
        if (merkleDistribution.amount > 0) {
            // The returnTokenAddress is here for safety purposes. It should be
            // the Research Portfolio gnosis address for the network this is on.
            // If going through the Research Portfolio website, this is what 
            // happens. If manually creating a token with Entrypoint contract,
            // then the funder has the choice of what to use. We recommend using
            // the same gnosis address in order to remain in good standing with
            // the community.
            distributor = distributorFactory.createDistributorV2(
                merkleDistribution.merkleRoot,
                merkleDistribution.manifest,
                merkleDistribution.returnTokenAddress
            );
            ResearchToken(token).mint(distributor, merkleDistribution.amount);
            DistributorV2(distributor).setToken(address(token));
        }

        uint256 addressesLength = addresses.length;
        for (uint i = 0; i < addressesLength; i++) {
            ResearchToken(token).mint(addresses[i], amounts[i]);
        }

        ResearchToken(token).freezeMinting();

        emit CreateResearchTokenAndDistributor(token, distributor);

        return (token, distributor);
    }

    function claimForAccountFromDistributorV2(
        address distributor,
        uint256 index,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        IDistributorV2 md = IDistributorV2(distributor);
        md.claimForAccount(index, amount, msg.sender, merkleProof);
    }

    function createDistributorV2(
        bytes32 merkleRoot,
        string calldata manifest,
        address tokenAddress,
        address returnTokenAddress
    ) external returns (address) {
        address distributor = distributorFactory.createDistributorV2(
            merkleRoot, manifest, returnTokenAddress);
        DistributorV2(distributor).setToken(tokenAddress);
        emit CreateDistributorV2(distributor);
        return distributor;
    }
}