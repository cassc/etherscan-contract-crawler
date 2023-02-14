// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IVoter {
    function vote(uint256 tokenId, address[] calldata poolVote, uint256[] calldata weights) external;
    function whitelist(address token, uint256 tokenId) external;
    function reset(uint256 tokenId) external;
    function gauges(address lp) external view returns (address);
    function _ve() external view returns (address);
    function minter() external view returns (address);
    function external_bribes(address _lp) external view returns (address);
    function internal_bribes(address _lp) external view returns (address);
    function votes(uint256 id, address lp) external view returns (uint256);
    function poolVote(uint256 id, uint256 index) external view returns (address);
    function lastVoted(uint256 id) external view returns (uint256);
    function weights(address lp) external view returns (uint256);
}