//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IGrayBoys_Mutants {
    //Create mutations from GBs
    function mutate(address _ownerAddress, uint256 _typeId, uint256[] calldata _fromTokenIds) external;

    //Create special mutations (do not require GBs)
    function specialMutate(address _ownerAddress, uint256 _typeId, uint256 _count) external;
}