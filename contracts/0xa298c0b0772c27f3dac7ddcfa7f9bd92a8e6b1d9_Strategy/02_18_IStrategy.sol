// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {IERC20} from 'src/interfaces/IERC20.sol';
import {IFYToken} from 'src/interfaces/IFYToken.sol';
import {IPool} from 'src/interfaces/IPool.sol';

/// @dev The Strategy contract allows liquidity providers to provide liquidity in underlying
/// and receive strategy tokens that represent a stake in a YieldSpace pool contract.
/// Upon maturity, the strategy can `divest` from the mature pool, becoming a proportional
/// ownership underlying vault. When not invested, the strategy can `invest` into a Pool using
/// all its underlying.
/// The strategy can also `eject` from a Pool before maturity, immediately converting its assets
/// to underlying as much as possible. If any fyToken can't be exchanged for underlying, the
/// strategy will hold them until maturity when `redeemEjected` can be used.
interface IStrategy {
    enum State {
        DEPLOYED,
        DIVESTED,
        INVESTED,
        EJECTED,
        DRAINED
    }

    function state() external view returns (State); // The state determines which functions are available

    function base() external view returns (IERC20); // Base token for this strategy

    function fyToken() external view returns (IFYToken); // Current fyToken for this strategy

    function pool() external view returns (IPool); // Current pool that this strategy invests in

    function maturity() external view returns (uint256); // Current maturity of the pool that this strategy investes in

    function baseCached() external view returns (uint256); // Base tokens owned by the strategy after the last operation

    function fyTokenCached() external view returns (uint256); // In emergencies, the strategy can keep fyToken of one series

    function poolCached() external view returns (uint256); // Pool tokens owned by the strategy during the investment period

    /// @dev Mint the first strategy tokens, without investing
    function init(address to) external returns (uint256 minted);

    /// @dev Start the strategy investments in the next pool
    /// @notice When calling this function for the first pool, some underlying needs to be transferred to the strategy first, using a batchable router.
    function invest(
        IPool pool_,
        uint256 initial_,
        uint256 ptsToSell_,
        uint256 minRatio_,
        uint256 maxRatio_,
        bytes[] calldata lends_
    ) external returns (uint256 poolTokensObtained);

    /// @dev Divest out of a pool once it has matured
    function divest() external returns (uint256 baseObtained);

    /// @dev Divest out of a pool at any time. If possible the pool tokens will be burnt for base and fyToken, the latter of which
    /// must be sold to return the strategy to a functional state. If the pool token burn reverts, the pool tokens will be transferred
    /// to the caller as a last resort.
    /// @notice The caller must take care of slippage when selling fyToken, if relevant.
    function eject()
        external
        returns (uint256 baseObtained, uint256 fyTokenObtained);

    /// @dev Buy ejected fyToken in the strategy at face value
    /// @param fyTokenTo Address to send the purchased fyToken to.
    /// @param baseTo Address to send any remaining base to.
    /// @return soldFYToken Amount of fyToken sold.
    /// @return returnedBase Amount of base unused and returned.
    function buyFYToken(
        address fyTokenTo,
        address baseTo
    ) external returns (uint256 soldFYToken, uint256 returnedBase);

    /// @dev If we ejected the pool tokens, we can recapitalize the strategy to avoid a forced migration
    function restart() external returns (uint256 baseIn);

    /// @dev Mint strategy tokens with pool tokens. It can be called only when invested.
    /// @notice The pool tokens that the user contributes need to have been transferred previously, using a batchable router.
    function mint(address to) external returns (uint256 minted);

    /// @dev Burn strategy tokens to withdraw pool tokens. It can be called only when invested.
    /// @notice The strategy tokens that the user burns need to have been transferred previously, using a batchable router.
    function burn(address to) external returns (uint256 poolTokensObtained);

    /// @dev Mint strategy tokens with base tokens. It can be called only when not invested and not ejected.
    /// @notice The base tokens that the user invests need to have been transferred previously, using a batchable router.
    function mintDivested(address to) external returns (uint256 minted);

    /// @dev Burn strategy tokens to withdraw base tokens. It can be called when not invested and not ejected.
    /// @notice The strategy tokens that the user burns need to have been transferred previously, using a batchable router.
    function burnDivested(
        address baseTo
    ) external returns (uint256 baseObtained);

    /// @dev Allows transfer of the admin
    function setAdmin(address) external;

    /// @dev Allows admin to set the lender
    function setLender(address) external;

    /// @dev Returns the admin
    function admin() external view returns (address);

    /// @dev Returns the lender
    function lender() external view returns (address);

    /// @dev Approves the usage of the lender's lend methods
    function approveUnderlying(address) external;
}