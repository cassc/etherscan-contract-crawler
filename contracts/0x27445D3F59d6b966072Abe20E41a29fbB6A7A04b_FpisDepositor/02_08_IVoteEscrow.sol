// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IVoteEscrow {
    function locked(address) external view returns(uint256);
    function locked__end(address) external view returns(uint256);
    function create_lock(uint256, uint256) external;
    function increase_amount(uint256) external;
    function increase_unlock_time(uint256) external;
    function withdraw() external;
    function checkpoint() external;
    function admin() external view returns (address);
    function smart_wallet_checker() external view returns (address);
    function commit_smart_wallet_checker(address _checker) external;
    function apply_smart_wallet_checker() external;
}