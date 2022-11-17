// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "vesper-pools/contracts/dependencies/openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEToken is IERC20 {
    /// @notice Balance of a particular account, in underlying units (increases as interest is earned)
    function balanceOfUnderlying(address account) external view returns (uint256);

    /// @notice Sum of all balances, in underlying units (increases as interest is earned)
    function totalSupplyUnderlying() external view returns (uint256);

    /// @notice Transfer underlying tokens from sender to the Euler pool, and increase account's eTokens
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param amount In underlying units (use max uint256 for full underlying token balance)
    function deposit(uint256 subAccountId, uint256 amount) external;

    /// @notice Transfer underlying tokens from Euler pool to sender, and decrease account's eTokens
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param amount In underlying units (use max uint256 for full pool balance)
    function withdraw(uint256 subAccountId, uint256 amount) external;
}

interface IDToken is IERC20 {
    /// @notice Debt owed by a particular account, in underlying units
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfer underlying tokens from the Euler pool to the sender, and increase sender's dTokens
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param amount In underlying units (use max uint256 for all available tokens)
    function borrow(uint256 subAccountId, uint256 amount) external;

    /// @notice Transfer underlying tokens from the sender to the Euler pool, and decrease sender's dTokens
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param amount In underlying units (use max uint256 for full debt owed)
    function repay(uint256 subAccountId, uint256 amount) external;
}

struct AssetConfig {
    address eTokenAddress;
    bool borrowIsolated;
    uint32 collateralFactor;
    uint32 borrowFactor;
    uint24 twapWindow;
}

interface IEulerMarkets {
    /// @notice Given an underlying, lookup the associated EToken
    /// @param underlying Token address
    /// @return EToken address, or address(0) if not activated
    function underlyingToEToken(address underlying) external view returns (address);

    /// @notice Given an underlying, lookup the associated DToken
    /// @param underlying Token address
    /// @return DToken address, or address(0) if not activated
    function underlyingToDToken(address underlying) external view returns (address);

    /// @notice Add an asset to the entered market list, or do nothing if already entered
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param newMarket Underlying token address
    function enterMarket(uint256 subAccountId, address newMarket) external;

    /// @notice Looks up the Euler-related configuration for a token, and resolves all default-value placeholders to their currently configured values.
    /// @param underlying Token address
    /// @return Configuration struct
    function underlyingToAssetConfig(address underlying) external view returns (AssetConfig memory);
}

interface IEulDistributor {
    /// @notice Claim distributed tokens
    /// @param account Address that should receive tokens
    /// @param token Address of token being claimed (ie EUL)
    /// @param proof Merkle proof that validates this claim
    /// @param stake If non-zero, then the address of a token to auto-stake to, instead of claiming
    function claim(
        address account,
        address token,
        uint256 claimable,
        bytes32[] calldata proof,
        address stake
    ) external;
}

interface IExec {
    function getPrice(address underlying) external returns (uint256 twap, uint256 twapPeriod);
}