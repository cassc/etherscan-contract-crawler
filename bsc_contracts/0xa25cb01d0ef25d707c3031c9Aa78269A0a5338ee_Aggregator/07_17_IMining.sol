// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IMining {

    struct UserInfo {
        uint256 totalHashRate;
        uint256 minersCount; // depricated, is not updating 
        uint256 totalClaims;
    }
    
    function deposit(address _user, uint256 _hashRate, bool _isWeb2) external;
    function withdraw(address _user,uint256 _hashRate) external;
    function getMinersCount(address _user) external view returns (uint256);
    function repairMiners(address _user) external;
    function pendingReward(address _user) external view returns (uint256);
    function totalHashRate() external view returns (uint256);
    function userInfo(address _user) external view returns(UserInfo memory);

}