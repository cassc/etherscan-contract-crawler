//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;
import {DashboardStake,DashboardPair} from "../structs/Structs.sol";

interface IERC721Minimal {
    function ownerOf(uint tokenId) external view returns (address);
    function transferFrom(address from, address to, uint tokenId) external;
}


interface IApeCoinStakingMinimal {
    function depositSelfApeCoin(uint256 _amount) external;
    function getApeCoinStake(address _address) external view returns (DashboardStake memory);
    function pendingRewards(uint256 _poolId, address _address, uint256 _tokenId) external view returns (uint256);
    function withdrawApeCoin(uint256 _amount, address _recipient) external;
    function withdrawSelfApeCoin(uint256 _amount) external;
    function claimApeCoin(address _recipient) external;
    function claimSelfApeCoin() external;
    // function
}