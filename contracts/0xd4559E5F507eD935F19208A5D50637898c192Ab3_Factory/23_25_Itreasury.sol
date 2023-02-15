// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


interface Itreasury{

  
  
  function setOperator(address _op) external;
    
    function withdrawTo(IERC20 _asset, uint256 _amount, address _to) external; 

    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external returns (bool, bytes memory);     


    function approveTo(IERC20 _asset, uint256 _amount, address _to) external; 
    function initialize(address _operator) external;
}