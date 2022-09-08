// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

/*
 * BNBPower 
 * App:             https://bnbpower.io
 * Twitter:         https://twitter.com/bnbpwr
 */

interface IReferrals {

    function addMember(address _member, address _parent) external;

    function updateEarn(address _member, uint256 _amount) external;
    
    function registerUser(address _member, address _sponsor) external;

    function countReferrals(address _member) external view returns (uint256[] memory);

    function getListReferrals(address _member) external view returns (address[] memory);
    
    function getSponsor(address account) external view returns (address);

    function isMember(address _user) external view returns (bool);

    function transfer(address _user, uint256 _amount) external;

}