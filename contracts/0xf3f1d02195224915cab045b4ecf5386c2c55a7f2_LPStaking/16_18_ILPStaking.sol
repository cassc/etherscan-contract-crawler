// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface ILPStaking {
    function withdrawFromTo(address owner, uint256 _pid, uint256 _amount, address _to) external;
    function claim(address _from, uint256 _pid) external;
    function pendingrena(uint256 pid_, address account_) external view returns(uint256);
    function addPendingRewards() external;
    function massUpdatePools() external;      
}