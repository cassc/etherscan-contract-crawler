// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IOmniseaONFT721Psi {
    function mint(address minter, uint24 quantity, bytes32[] memory _merkleProof, uint8 _phaseId) external;
    function mintPrice(uint8 _phaseId) external view returns (uint256);
    function getOwner() external view returns (address);
}