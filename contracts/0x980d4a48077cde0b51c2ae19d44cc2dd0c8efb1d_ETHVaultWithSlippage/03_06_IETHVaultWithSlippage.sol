// SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

import "./IICHIVault.sol";

interface IETHVaultWithSlippage {

    // WETH address
    function wETH() external view returns(address);

    // Vault address
    function vault() external view returns(address);
    
    function depositETH(
        uint256 minimumProceeds,
        address to
    ) external payable returns (uint256 shares);

    event DeployETHVault(
        address indexed sender, 
        address indexed vault, 
        address wETH,
        bool isInverted);

    event DepositForwarded(
        address indexed sender,
        uint256 amount,
        uint256 shares,
        address to
    );

}