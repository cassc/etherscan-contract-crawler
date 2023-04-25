// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IWombatVoter.sol';
import './IWombatStakingReader.sol';
interface IWombatBribeManagerReader {

    struct Pool {
        address poolAddress;
        address rewarder;
        uint256 totalVoteInVlmgp;
        string name;
        bool isActive;
    }

    function poolInfos(address lpAddress) external view returns (address, address, uint256, string memory, bool);
    function getPoolsLength() external view returns (uint256);
    function pools(uint256 poolIndex)  external view returns (address);
    function voter() external view returns (IWombatVoter);
    function wombatStaking() external view returns (IWombatStakingReader);
    function getVoteForLp(address lp) external view returns (uint256);
    function totalVlMgpInVote() external view returns (uint256);
    function usedVote() external view returns (uint256);
    
}