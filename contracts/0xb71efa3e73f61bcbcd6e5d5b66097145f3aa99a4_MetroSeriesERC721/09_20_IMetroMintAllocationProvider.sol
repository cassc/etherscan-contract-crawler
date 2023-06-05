//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IMetroMintAllocationProvider
{
    function getRemainingAllocation(
        address _addr,
        bytes32[] calldata _proof,
        string memory extraData
    ) external view returns(uint256 allocation);

    function consumeAllocation(address add, string memory extraData) external;
}