// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IPIPXVaultFactory.sol";

interface IPIPXInventoryStaking {
    function pipxVaultFactory() external view returns (IPIPXVaultFactory);
    function vaultXToken(uint256 vaultId) external view returns (address);
    function xTokenAddr(address baseToken) external view returns (address);
    function xTokenShareValue(uint256 vaultId) external view returns (uint256);

    function __PIPXInventoryStaking_init(address pipxFactory) external;
    
    function deployXTokenForVault(uint256 vaultId) external;
    function receiveRewards(uint256 vaultId, uint256 amount) external returns (bool);
    function timelockMintFor(uint256 vaultId, uint256 amount, address to, uint256 timelockLength) external returns (uint256);
    function deposit(uint256 vaultId, uint256 _amount) external;
    function withdraw(uint256 vaultId, uint256 _share) external;
}