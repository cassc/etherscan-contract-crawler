// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "IERC721A.sol";

interface IFoundersKey is IERC721A {
    function tokenType(uint16 _tokenId) external view returns(uint8);
    function setStakingAddress(address _stakingAddress) external; 
}