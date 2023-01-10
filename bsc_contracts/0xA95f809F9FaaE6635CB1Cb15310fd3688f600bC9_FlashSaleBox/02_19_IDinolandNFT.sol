// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IDinolandNFT{
    function createDino(uint256 _dinoGenes, address _ownerAddress, uint128 _gender, uint128 _generation) external returns(uint256);
    function getDinosByOwner(address _owner) external returns(uint256[] memory);
}