// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

abstract contract IRNG {

    function requestRandomNumber() external virtual returns (bytes32 requestId) ;

    function requestRandomNumberWithCallback( ) external virtual returns (bytes32) ;

    function isRequestComplete(bytes32 requestId) external virtual view returns (bool isCompleted) ; 

    function randomNumber(bytes32 requestId) external view virtual returns (uint256 randomNum) ;

}