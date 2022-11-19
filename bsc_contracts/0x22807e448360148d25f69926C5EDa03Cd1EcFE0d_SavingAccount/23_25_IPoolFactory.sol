// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

interface IPoolFactory {
    function poolRegistry() external view returns (address);

    function initialize(
        address _gemGlobalConfig,
        address _ubGlobalConfig,
        address _ubSavingAccount,
        address _ubBank,
        address _ubAccounts,
        address _ubTokenRegistry,
        address _ubClaim
    ) external;

    function createNewPool(uint256 _poolId)
        external
        returns (
            address globalConfig,
            address savingAccount,
            address bank,
            address accounts,
            address tokenRegistry,
            address claim
        );
}