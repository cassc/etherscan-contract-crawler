// SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

import "./IICHIVault.sol";

interface IETHVault {

    // WETH address
    function wETH() external view returns(address);

    // Vault address
    function vault() external view returns(address);
    
    function depositETH(
        address
    ) external payable returns (uint256);

    event DeployETHVault(
        address indexed sender, 
        address indexed vault, 
        address wETH,
        bool isInverted);

}