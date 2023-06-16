// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;



interface IVesting{
    function allocations(string memory, address) external view returns(uint256 allocated, uint256 claimed);
    function allocate(string memory _pool_id, address wallet,uint256 amount)external;
    function projectClaimedTotal(string memory) external view returns(uint256);
    function projectClaimedTotalByUser(string memory,address) external view returns(uint256);
}