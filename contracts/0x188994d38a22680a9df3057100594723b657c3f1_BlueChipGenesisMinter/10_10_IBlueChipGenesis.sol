// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBlueChipGenesis {
    function mint(address _to, uint256 _amount) external;

    //ERC721Psi
    function totalSupply() external view returns (uint256);
}