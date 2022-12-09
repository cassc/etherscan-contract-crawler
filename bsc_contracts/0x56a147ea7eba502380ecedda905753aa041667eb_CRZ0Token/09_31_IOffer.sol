// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

interface IOffer {
    function getInitialized() external view returns (bool);
    
    function getFinished() external view returns (bool);

    function getSuccess() external view returns (bool);

    function initialize() external;

    function cashoutTokens(address _investor) external returns (bool);

    function getTotalBought(address _investor) external view returns(uint256);
    
    function getTotalCashedOut(address _investor) external view returns(uint256);

    function getFinishDate() external view returns (uint256);
}