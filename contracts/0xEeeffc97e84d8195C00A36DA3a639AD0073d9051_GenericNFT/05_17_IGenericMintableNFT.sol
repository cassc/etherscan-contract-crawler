// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IGenericMintableNFT {
    function mint(uint256 _quantity, address _receiver) external;
    function numberMinted(address _owner) external view returns (uint256);
    function totalMinted() external view returns (uint256);
}