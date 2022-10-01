// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ISynthReactor {
    function updateUserStakedNfts(address _user, uint256 _stakedNfts) external;
}