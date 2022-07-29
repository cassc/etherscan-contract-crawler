pragma solidity 0.8.15;

//SPDX-License-Identifier: MIT

interface IORCPass {
    function ownerOfERC721Like(uint256 id) external view returns (address);
}