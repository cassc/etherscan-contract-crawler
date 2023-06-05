// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface ICerosRouterLs {

    // --- Events ---
    event Deposit(address indexed _account, address indexed _token, uint256 _amount, uint256 _profit);
    event Claim(address indexed _recipient, address indexed _token, uint256 _amount);
    event Withdrawal(address indexed _owner, address indexed _recipient, address indexed _token, uint256 _amount);
    event ChangeCeVault(address _vault);
    event ChangeDex(address _dex);
    event ChangePool(address _pool);
    event ChangeStrategy(address _strategy);
    event ChangePairFee(uint256 _fee);

    // --- Functions ---
    function deposit(uint256 _amount) external returns (uint256);
    function withdrawAMATICc(address _recipient, uint256 _amount) external returns (uint256);
    function claim(address _recipient) external returns (uint256);
    function claimProfit(address _recipient) external;
    function withdrawFor(address _recipient, uint256 _amount) external returns (uint256);   
    function getYieldFor(address _account) external view returns(uint256);
    function s_profits(address _account) external view returns(uint256);
}