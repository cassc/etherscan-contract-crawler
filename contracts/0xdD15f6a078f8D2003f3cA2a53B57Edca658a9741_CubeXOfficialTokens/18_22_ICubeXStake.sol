// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

interface ICubeXStake {
    struct Stake {
        address owner;
        uint256 tokenId;
        uint256 timestamp;
    }

    function getStakes(address _address) external view returns (Stake[] memory);
}