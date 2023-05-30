// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface ChainFacesHDRendererInterface {
    function tokenURI(uint256 _id) external view returns (string memory);

    function image(uint256 _id) external view returns (string memory);
}