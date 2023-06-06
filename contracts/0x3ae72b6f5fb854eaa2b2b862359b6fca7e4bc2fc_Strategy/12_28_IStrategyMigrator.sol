// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {IFYToken} from "@yield-protocol/vault-v2/src/interfaces/IFYToken.sol";
import {IERC20} from "@yield-protocol/utils-v2/src/token/IERC20.sol";


/// @dev The Migrator contract poses as a Pool to receive all assets from a Strategy
/// during a roll operation.
/// @notice The Pool and fyToken must exist. The fyToken needs to be not mature, and the pool needs to have no fyToken in it.
/// There will be no state changes on pool or fyToken.
interface IStrategyMigrator is IERC20 {

    /// @dev Mock pool base - Must match that of the calling strategy
    function base() external view returns(IERC20);

    /// @dev Mock pool fyToken - Can be any address, including address(0)
    function fyToken() external view returns(IFYToken);

    /// @dev Mock pool init. Called within `invest`.
    function init(address) external returns (uint256, uint256, uint256);

    /// @dev Mock pool burn and make it revert so that `endPool`never suceeds, and `burnForBase` can never be called.
    function burn(address, address, uint256, uint256) external returns  (uint256, uint256, uint256);
}