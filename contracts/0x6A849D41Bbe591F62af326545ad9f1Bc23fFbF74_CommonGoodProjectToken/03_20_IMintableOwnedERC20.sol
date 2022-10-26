// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../@openzeppelin/contracts/access/Ownable.sol";

import "../project/IProject.sol";

interface IMintableOwnedERC20 is IERC20 {

    function mint(address to, uint256 amount) external ;

    function getOwner() external view returns (address);

    function changeOwnership( address dest) external;

    function setConnectedProject( IProject project_) external;

    function performInitialMint( uint numTokens) external;
}