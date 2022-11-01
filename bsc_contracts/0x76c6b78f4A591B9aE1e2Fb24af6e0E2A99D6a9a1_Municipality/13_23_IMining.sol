// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IMining {
    function deposit(address _user, uint256 _miner, uint256 _hashRate) external;
    function depositMiners(address _user, uint256 _firstMinerId, uint256 _minersCount, uint256 _hashRate) external;
    function withdraw(address _user,uint256 _miner) external;
    function applyVouchers(address _user, uint256[] calldata _minerIds) external;
    function getMinersCount(address _user) external view returns (uint256);
    function repairMiners(address _user) external;
}