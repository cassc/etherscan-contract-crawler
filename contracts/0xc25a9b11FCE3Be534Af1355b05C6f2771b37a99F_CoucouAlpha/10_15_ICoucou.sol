// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ICoucou {

    function freeMint(uint256 quantity, bytes32[] calldata merkleProof) external payable;

    function publicMint(uint256 quantity) external payable;

    function mintPrice() external pure returns (uint);

    function saleTime() external view returns (uint);

    function updateMerkleRoot(bytes32 _root) external;

    function updateSaleTime(uint _start) external;

    function withdrawFunds(address _to) external;

}