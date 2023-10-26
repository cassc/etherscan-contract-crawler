// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
The DistributorV2Factory contract creates cloned DistributorV2 contracts.
*/

import "@openzeppelin/contracts/access/Ownable.sol";

import "../libraries/Clones.sol";
import "./DistributorV2.sol";

contract DistributorV2Factory is Ownable {
    using Clones for address;

    address immutable impl;
    // The researchPortfolioGnosis should be one of the following:
    // Goerli: 0x6f07856f4974A32a54A0A0045eDfAEd97Cc78136
    // Mainnet: 0xAAbF8DC8c8208e023c5D8e2d0e3dd30415559E0E
    address public researchPortfolioGnosis;

    constructor(address researchPortfolioGnosis_) {
        researchPortfolioGnosis = researchPortfolioGnosis_;
        impl = address(new DistributorV2());
    }

    function createDistributorV2(
        bytes32 merkleRoot,
        string calldata manifest,
        address returnTokenAddress
    ) external onlyOwner returns (address) {
        address payable clone = payable(impl.clone());
        DistributorV2(clone).initialize(merkleRoot, manifest, 
            returnTokenAddress, researchPortfolioGnosis);
        return clone;
    }
}