// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


/** @title Custom Interface for Curve BoostV2 contract  */
interface IBoostV2 {

    function balanceOf(address _user) external view returns(uint256);
    function allowance(address _user, address _spender) external view returns(uint256);

    function adjusted_balance_of(address _user) external view returns(uint256);
    function delegated_balance(address _user) external view returns(uint256);
    function received_balance(address _user) external view returns(uint256);
    function delegable_balance(address _user) external view returns(uint256);

    function checkpoint_user(address _user) external;
    function approve(address _spender, uint256 _value) external;
    function boost(address _to, uint256 _amount, uint256 _endtime, address _from) external;
}