// SPDX-License-Identifier: NONE
pragma solidity ^0.8.0;

//https://github.com/ethereum/EIPs/blob/master/EIPS/eip-900.md
interface IERC900 {
    event Staked(address indexed addr, uint256 amount, uint256 total, bytes data);
    event Unstaked(address indexed addr, uint256 amount, uint256 total, bytes data);

    function stake(uint256 amount, bytes calldata data) external;
    function stakeFor(address addr, uint256 amount, bytes calldata data) external;
    function unstake(uint256 amount, bytes calldata data) external;
    function totalStakedFor(address addr) external view returns (uint256);
    function totalStaked() external view returns (uint256);
    function token() external view returns (address);
    function supportsHistory() external pure returns (bool);

    // optional
    //function lastStakedFor(address addr) public view returns (uint256);
    //function totalStakedForAt(address addr, uint256 blockNumber) public view returns (uint256);
    //function totalStakedAt(uint256 blockNumber) public view returns (uint256);
}