//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

interface IRenderer{
    function render(uint256 _tokenId, address _address) external view returns (string memory);
}