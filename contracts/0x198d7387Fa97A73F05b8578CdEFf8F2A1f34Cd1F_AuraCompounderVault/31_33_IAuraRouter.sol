// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IAuraRouter {
    function deposit(uint256 _assets, bool _tokenized) external returns (uint256);
    function withdrawRequest(uint256 _shares, bool _tokenized) external;
    function withdraw(uint256 _assets, bool _tokenized) external returns (uint256);
    function rehypothecate(uint256 assets, bool _tokenized) external returns (uint256);

    function noTokenizedUserInfo(address _user) external view returns (uint128, uint64, uint64);
    function lsdUserInfo(address _user) external view returns (uint128, uint64, uint64);

    function totalWithdrawRequests() external view returns (uint256);
    function totalWithdrawRequestsLSD() external view returns (uint256);
    function totalWithdrawRequestsNoTokenized() external view returns (uint256);
}