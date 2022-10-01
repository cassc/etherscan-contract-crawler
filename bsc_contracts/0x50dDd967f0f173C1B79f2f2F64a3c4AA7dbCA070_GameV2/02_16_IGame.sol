// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


interface IGame{

    // uint256 constant QUOTA;

    function getSignupBurnAmount(address _token) external view returns(uint256);

    function getIsSignup(uint256 _id,address _account) external view returns(bool);

    function getSignupAddresses(uint256 _id) external view returns(address[] memory);

    function getFtBurnAmount()external view returns(uint256);

    function createConfig(uint256 _deposit,address _burnToken,uint256 _burnAmount) external;

    function batchSetWhitelist(address[] calldata _addresses,bool _v) external;


    // event Lottery(uint256 id,address winAddress,address[QUOTA-1] loseAddresses,uint256[QUOTA-1] rewards,uint256 burnAmount);
    // event Signup(uint256 id,address user);
    // event CreateConfig(uint256 id,address burnToken,uint256 burn,uint256 deposit);
}