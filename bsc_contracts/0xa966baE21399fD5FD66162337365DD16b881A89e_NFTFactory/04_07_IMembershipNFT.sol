//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

interface IMembershipNFT {
    function ownerOf(uint256) external view returns (address);
    function belongsTo(address) external view returns (uint256);
    function tier(uint256) external view returns(uint256);
    function issueNFT(address, string memory) external returns (uint256);
    function changeURI(uint256, string memory) external;
}