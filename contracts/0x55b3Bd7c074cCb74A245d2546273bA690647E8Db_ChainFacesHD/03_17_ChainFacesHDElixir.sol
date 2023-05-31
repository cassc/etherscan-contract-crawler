// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface ChainFacesHDElixirInterface {
    function consume(address _owner, uint256 _id, uint256 _amount) external;
    function mint(address _owner, uint256 _id, uint256 _amount) external;
}