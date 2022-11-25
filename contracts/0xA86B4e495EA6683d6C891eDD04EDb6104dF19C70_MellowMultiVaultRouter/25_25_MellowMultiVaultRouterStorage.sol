// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

import "../interfaces/IMellowMultiVaultRouter.sol";

contract MellowMultiVaultRouterStorageV1 {
    mapping (uint256 => IMellowMultiVaultRouter.BatchedDeposits) internal _batchedDeposits;
    IERC20Minimal internal _token;
    IWETH internal _weth;

    IERC20RootVault[] internal _vaults;
    mapping(uint256 => bool) internal _isVaultDeprecated;

    mapping(address => mapping(uint256 => uint256)) _managedLpTokens;
}

contract MellowMultiVaultRouterStorage is MellowMultiVaultRouterStorageV1 {
    // Reserve some storage for use in future versions, without creating conflicts
    // with other inheritted contracts
    uint256[69] private __gap; // total storage = 100 slots, including structs
}