//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IGrayBoys_Mutants.sol";
import "./IGrayBoys_Science_Lab.sol";

contract GrayBoys_Mutator {
    /* Lab items */
    uint16 constant RED_SERUM_ID = 1;
    uint16 constant ANCIENT_CRYSTAL_ID = 4;
    uint16 constant GREEN_SERUM_ID = 5;

    /* Mutations */
    uint16 constant L1_MUTATION_ID = 0;
    uint16 constant L2_MUTATION_ID = 1;
    uint16 constant CRYSTAL_MUTATION_ID = 2;

    IGrayBoys_Mutants public mutantsContract;
    IGrayBoys_Science_Lab public scienceLabContract;

    constructor(address _mutantsContractAddress, address _scienceLabContractAddress) {
        mutantsContract = IGrayBoys_Mutants(_mutantsContractAddress);
        scienceLabContract = IGrayBoys_Science_Lab(_scienceLabContractAddress);
    }

    /* Basic mutations */
    function mutateL1(uint256[] calldata _fromTokenIds) external {
        uint256 count = _fromTokenIds.length;
        scienceLabContract.burnMaterialForOwnerAddress(RED_SERUM_ID, count, msg.sender);
        scienceLabContract.burnMaterialForOwnerAddress(GREEN_SERUM_ID, count, msg.sender);
        mutantsContract.mutate(msg.sender, L1_MUTATION_ID, _fromTokenIds);
    }

    function mutateL2(uint256[] calldata _fromTokenIds) external {
        uint256 count = _fromTokenIds.length;
        scienceLabContract.burnMaterialForOwnerAddress(RED_SERUM_ID, 2 * count, msg.sender);
        scienceLabContract.burnMaterialForOwnerAddress(GREEN_SERUM_ID, 2 * count, msg.sender);
        mutantsContract.mutate(msg.sender, L2_MUTATION_ID, _fromTokenIds);
    }

    /* Special mutations */
    function mutateCrystal(uint256 _count) external {
        scienceLabContract.burnMaterialForOwnerAddress(ANCIENT_CRYSTAL_ID, _count, msg.sender);
        mutantsContract.specialMutate(msg.sender, CRYSTAL_MUTATION_ID, _count);
    }
}