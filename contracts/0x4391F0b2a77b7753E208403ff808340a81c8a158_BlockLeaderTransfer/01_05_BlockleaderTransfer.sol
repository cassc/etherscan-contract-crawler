// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract BlockLeaderTransfer is Ownable{

    error InconsistentArrayLengths(uint array1, uint array2);
    error InvalidAmount();

    event MultiTransferNative(
        address indexed from, 
        address indexed to, 
        uint256 value
    );

    event MultiTransferERC20(
        address indexed token,
        address indexed from, 
        address indexed to, 
        uint256 value
    );

    constructor(){}

    function batchTransferERC20(
        address _token, 
        address[] calldata _receivers, 
        uint256[] calldata _amounts, 
        uint256 totalAmount) 
        external  
    {
        if (_receivers.length != _amounts.length) {
            revert InconsistentArrayLengths(_receivers.length, _amounts.length);
        }
        uint amount;
        for(uint x; x < _receivers.length; x++) {
            IERC20(_token).transferFrom(
                address(_msgSender()),
                address(_receivers[x]),
                _amounts[x]
            );
            amount += _amounts[x];
            
            emit MultiTransferERC20(_token, _msgSender(), _receivers[x], _amounts[x]);
        }  

        if (amount != totalAmount) {
            revert InvalidAmount();
        }
    }
    
    function batchTransferNative(
        address[] calldata _receivers, 
        uint256[] calldata _amounts)
        payable
        external  
    { 
        if (_receivers.length != _amounts.length) {
            revert InconsistentArrayLengths(_receivers.length, _amounts.length);
        }
        uint amount;
        for(uint x; x < _receivers.length; x++) {
            (bool success, ) = _receivers[x].call{value: _amounts[x]}("");
            require(success, "Transfer failed");
            amount += _amounts[x];

            emit MultiTransferNative(_msgSender(), _receivers[x], _amounts[x]);
        }  
        
        if (amount != msg.value) {
            revert InvalidAmount();
        }    
    }
}