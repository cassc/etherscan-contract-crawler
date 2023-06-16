// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC20.sol";

interface IFloppy  is IERC20{
       
    function mint(address acount_ ,uint256 amount_ ) external ;

    function burn(uint256 amount_ ) external ;


}