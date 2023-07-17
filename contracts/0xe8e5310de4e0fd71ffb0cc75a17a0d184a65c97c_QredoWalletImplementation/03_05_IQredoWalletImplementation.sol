// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

interface IQredoWalletImplementation {
    function init(address _walletOwner) external;
    function invoke(bytes memory signature, address _to, uint256 _value, bytes calldata _data) external returns (bytes memory _result);
    function getBalance(address tokenAddress) external view returns(uint256 _balance);
    function getNonce() external view returns(uint256 nonce);
    function getWalletOwnerAddress() external view returns(address _walletOwner);
    
    event Invoked(address indexed sender, address indexed target, uint256 value, uint256 indexed nonce, bytes data);
    event Received(address indexed sender, uint indexed value, bytes data);
    event Fallback(address indexed sender, uint indexed value, bytes data);
}