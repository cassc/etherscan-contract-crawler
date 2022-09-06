// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IHandlerAdapter{
    function deposit(address _token, uint256 fullAmount, uint256 leaveInPool) external;
    function withdraw (address _user, address _token, uint256 _amount ) external;
    function getAdapterAmount () external view returns ( uint256 );
    function getCoreTokens () external view returns ( address liquidToken, address primaryToken );
    
    function setSlippage ( uint64 _newSlippage ) external;
    function setWallet ( address _newWallet ) external;
}