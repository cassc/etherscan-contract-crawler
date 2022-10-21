// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWombatStaking {

    function convertWOM(uint256 amount) external returns(uint256);

    function masterWombat() external view returns (address);

    function deposit(address _lpToken, uint256 _amount, uint256 _minAmount, address _for, address _from) external;

    function depositLP(address _lpToken, uint256 _lpAmount, address _for) external;

    function withdraw(address _lpToken, uint256 _amount, uint256 _minAmount, address _sender) external;

    function getPoolLp(address _lpToken) external view returns (address);

    function harvest(address _lpToken) external;

    function burnReceiptToken(address _lpToken, uint256 _amount) external;
}