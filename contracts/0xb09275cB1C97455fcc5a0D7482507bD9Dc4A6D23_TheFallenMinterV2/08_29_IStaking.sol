// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISamuraiStaking {
    function getStakeInfo(uint256 tokenId)
        external
        view
        returns (
            address, // owner
            uint256, // poolId
            uint256, // unlock date
            uint256 // reward date
        );
}

interface IOnnaStaking {
    function getStakeInfo(uint256 tokenId)
        external
        view
        returns (
            address, // owner
            uint256, // poolId
            uint256, // deposit date
            uint256, // unlock date
            uint256 // reward date
        );
}