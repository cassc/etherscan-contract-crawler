/**
 *Submitted for verification at Etherscan.io on 2022-08-31
*/

/** 
 *  SourceUnit: /Users/patrickmckelvy/code/defi/os/alchemix/alops/submodules/v2-foundry/src/adapters/rocket/RETHAdapterV1.sol
*/
            
pragma solidity >=0.5.0;

/// @title  IERC20Metadata
/// @author Alchemix Finance
interface IERC20Metadata {
    /// @notice Gets the name of the token.
    ///
    /// @return The name.
    function name() external view returns (string memory);

    /// @notice Gets the symbol of the token.
    ///
    /// @return The symbol.
    function symbol() external view returns (string memory);

    /// @notice Gets the number of decimals that the token has.
    ///
    /// @return The number of decimals.
    function decimals() external view returns (uint8);
}



/** 
 *  SourceUnit: /Users/patrickmckelvy/code/defi/os/alchemix/alops/submodules/v2-foundry/src/adapters/rocket/RETHAdapterV1.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}




/** 
 *  SourceUnit: /Users/patrickmckelvy/code/defi/os/alchemix/alops/submodules/v2-foundry/src/adapters/rocket/RETHAdapterV1.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: GPL-3.0-only
pragma solidity >=0.5.0;

interface IRocketStorage {
    function getDeployedStatus() external view returns (bool);
    function getGuardian() external view returns(address);
    function setGuardian(address value) external;
    function confirmGuardian() external;

    function getAddress(bytes32 key) external view returns (address);
    function getUint(bytes32 key) external view returns (uint);
    function getString(bytes32 key) external view returns (string memory);
    function getBytes(bytes32 key) external view returns (bytes memory);
    function getBool(bytes32 key) external view returns (bool);
    function getInt(bytes32 key) external view returns (int);
    function getBytes32(bytes32 key) external view returns (bytes32);

    function setAddress(bytes32 key, address value) external;
    function setUint(bytes32 key, uint value) external;
    function setString(bytes32 key, string calldata value) external;
    function setBytes(bytes32 key, bytes calldata value) external;
    function setBool(bytes32 key, bool value) external;
    function setInt(bytes32 key, int value) external;
    function setBytes32(bytes32 key, bytes32 value) external;

    function deleteAddress(bytes32 key) external;
    function deleteUint(bytes32 key) external;
    function deleteString(bytes32 key) external;
    function deleteBytes(bytes32 key) external;
    function deleteBool(bytes32 key) external;
    function deleteInt(bytes32 key) external;
    function deleteBytes32(bytes32 key) external;

    function addUint(bytes32 key, uint256 amount) external;
    function subUint(bytes32 key, uint256 amount) external;

    function getNodeWithdrawalAddress(address nodeAddress) external view returns (address);
    function getNodePendingWithdrawalAddress(address nodeAddress) external view returns (address);
    function setWithdrawalAddress(address nodeAddress, address newWithdrawalAddress, bool confirm) external;
    function confirmWithdrawalAddress(address nodeAddress) external;
}



/** 
 *  SourceUnit: /Users/patrickmckelvy/code/defi/os/alchemix/alops/submodules/v2-foundry/src/adapters/rocket/RETHAdapterV1.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: GPL-3.0-only
pragma solidity >=0.5.0;

////import {IERC20} from "../../../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

////import {IERC20Metadata} from "../../IERC20Metadata.sol";

interface IRETH is IERC20, IERC20Metadata {
    function getEthValue(uint256 amount) external view returns (uint256);
    function getRethValue(uint256 amount) external view returns (uint256);
    function getExchangeRate() external view returns (uint256);
    function getTotalCollateral() external view returns (uint256);
    function getCollateralRate() external view returns (uint256);
    function depositExcess() external payable;
    function depositExcessCollateral() external;
    function mint(uint256 amount, address receiver) external;
    function burn(uint256 amount) external;
}



/** 
 *  SourceUnit: /Users/patrickmckelvy/code/defi/os/alchemix/alops/submodules/v2-foundry/src/adapters/rocket/RETHAdapterV1.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED
pragma solidity >=0.8.4;

/// @notice An error used to indicate that an argument passed to a function is illegal or
///         inappropriate.
///
/// @param message The error message.
error IllegalArgument(string message);

/// @notice An error used to indicate that a function has encountered an unrecoverable state.
///
/// @param message The error message.
error IllegalState(string message);

/// @notice An error used to indicate that an operation is unsupported.
///
/// @param message The error message.
error UnsupportedOperation(string message);

/// @notice An error used to indicate that a message sender tried to execute a privileged function.
///
/// @param message The error message.
error Unauthorized(string message);



/** 
 *  SourceUnit: /Users/patrickmckelvy/code/defi/os/alchemix/alops/submodules/v2-foundry/src/adapters/rocket/RETHAdapterV1.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title  ISwapRouter
/// @author Uniswap Labs
///
/// @notice Functions for swapping tokens via Uniswap V3.
interface ISwapRouter {
  struct ExactInputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 deadline;
    uint256 amountIn;
    uint256 amountOutMinimum;
    uint160 sqrtPriceLimitX96;
  }

  /// @notice Swaps `amountIn` of one token for as much as possible of another token.
  ///
  /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata.
  ///
  /// @return amountOut The amount of the received token
  function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

  struct ExactInputParams {
    bytes path;
    address recipient;
    uint256 deadline;
    uint256 amountIn;
    uint256 amountOutMinimum;
  }

  /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path.
  ///
  /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata.
  ///
  /// @return amountOut The amount of the received token
  function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

  struct ExactOutputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 deadline;
    uint256 amountOut;
    uint256 amountInMaximum;
    uint160 sqrtPriceLimitX96;
  }

  /// @notice Swaps as little as possible of one token for `amountOut` of another token.
  ///
  /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata.
  ///
  /// @return amountIn The amount of the input token.
  function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

  struct ExactOutputParams {
    bytes path;
    address recipient;
    uint256 deadline;
    uint256 amountOut;
    uint256 amountInMaximum;
  }

  /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed).
  ///
  /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata.
  ///
  /// @return amountIn The amount of the input token
  function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}



/** 
 *  SourceUnit: /Users/patrickmckelvy/code/defi/os/alchemix/alops/submodules/v2-foundry/src/adapters/rocket/RETHAdapterV1.sol
*/
            
pragma solidity >=0.5.0;

////import "../../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

////import "../IERC20Metadata.sol";

/// @title IWETH9
interface IWETH9 is IERC20, IERC20Metadata {
  /// @notice Deposits `msg.value` ethereum into the contract and mints `msg.value` tokens.
  function deposit() external payable;

  /// @notice Burns `amount` tokens to retrieve `amount` ethereum from the contract.
  ///
  /// @dev This version of WETH utilizes the `transfer` function which hard codes the amount of gas
  ///      that is allowed to be utilized to be exactly 2300 when receiving ethereum.
  ///
  /// @param amount The amount of tokens to burn.
  function withdraw(uint256 amount) external;
}



/** 
 *  SourceUnit: /Users/patrickmckelvy/code/defi/os/alchemix/alops/submodules/v2-foundry/src/adapters/rocket/RETHAdapterV1.sol
*/
            
pragma solidity >=0.5.0;

/// @title  ITokenAdapter
/// @author Alchemix Finance
interface ITokenAdapter {
    /// @notice Gets the current version.
    ///
    /// @return The version.
    function version() external view returns (string memory);

    /// @notice Gets the address of the yield token that this adapter supports.
    ///
    /// @return The address of the yield token.
    function token() external view returns (address);

    /// @notice Gets the address of the underlying token that the yield token wraps.
    ///
    /// @return The address of the underlying token.
    function underlyingToken() external view returns (address);

    /// @notice Gets the number of underlying tokens that a single whole yield token is redeemable
    ///         for.
    ///
    /// @return The price.
    function price() external view returns (uint256);

    /// @notice Wraps `amount` underlying tokens into the yield token.
    ///
    /// @param amount    The amount of the underlying token to wrap.
    /// @param recipient The address which will receive the yield tokens.
    ///
    /// @return amountYieldTokens The amount of yield tokens minted to `recipient`.
    function wrap(uint256 amount, address recipient)
        external
        returns (uint256 amountYieldTokens);

    /// @notice Unwraps `amount` yield tokens into the underlying token.
    ///
    /// @param amount    The amount of yield-tokens to redeem.
    /// @param recipient The recipient of the resulting underlying-tokens.
    ///
    /// @return amountUnderlyingTokens The amount of underlying tokens unwrapped to `recipient`.
    function unwrap(uint256 amount, address recipient)
        external
        returns (uint256 amountUnderlyingTokens);
}



/** 
 *  SourceUnit: /Users/patrickmckelvy/code/defi/os/alchemix/alops/submodules/v2-foundry/src/adapters/rocket/RETHAdapterV1.sol
*/
            
pragma solidity >=0.5.0;

////import {IRETH} from "../interfaces/external/rocket/IRETH.sol";
////import {IRocketStorage} from "../interfaces/external/rocket/IRocketStorage.sol";

library RocketPool {
    /// @dev Gets the current rETH contract.
    ///
    /// @param self The rocket storage contract to read from.
    ///
    /// @return The current rETH contract.
    function getRETH(IRocketStorage self) internal view returns (IRETH) {
        return IRETH(self.getAddress(
            keccak256(abi.encodePacked("contract.address", "rocketTokenRETH"))
        ));
    }
}



/** 
 *  SourceUnit: /Users/patrickmckelvy/code/defi/os/alchemix/alops/submodules/v2-foundry/src/adapters/rocket/RETHAdapterV1.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: AGPL-3.0-only
pragma solidity >=0.8.4;

////import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

////import {IllegalState} from "../base/ErrorMessages.sol";

////import {IERC20Metadata} from "../interfaces/IERC20Metadata.sol";

/// @title  SafeERC20
/// @author Alchemix Finance
library SafeERC20 {
    /// @notice An error used to indicate that a call to an ERC20 contract failed.
    ///
    /// @param target  The target address.
    /// @param success If the call to the token was a success.
    /// @param data    The resulting data from the call. This is error data when the call was not a
    ///                success. Otherwise, this is malformed data when the call was a success.
    error ERC20CallFailed(address target, bool success, bytes data);

    /// @dev A safe function to get the decimals of an ERC20 token.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the query fails or returns an
    ///      unexpected value.
    ///
    /// @param token The target token.
    ///
    /// @return The amount of decimals of the token.
    function expectDecimals(address token) internal view returns (uint8) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20Metadata.decimals.selector)
        );

        if (!success || data.length < 32) {
            revert ERC20CallFailed(token, success, data);
        }

        return abi.decode(data, (uint8));
    }

    /// @dev Transfers tokens to another address.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the transfer failed or returns an
    ///      unexpected value.
    ///
    /// @param token     The token to transfer.
    /// @param recipient The address of the recipient.
    /// @param amount    The amount of tokens to transfer.
    function safeTransfer(address token, address recipient, uint256 amount) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, recipient, amount)
        );

        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert ERC20CallFailed(token, success, data);
        }
    }

    /// @dev Approves tokens for the smart contract.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the approval fails or returns an
    ///      unexpected value.
    ///
    /// @param token   The token to approve.
    /// @param spender The contract to spend the tokens.
    /// @param value   The amount of tokens to approve.
    function safeApprove(address token, address spender, uint256 value) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.approve.selector, spender, value)
        );

        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert ERC20CallFailed(token, success, data);
        }
    }

    /// @dev Transfer tokens from one address to another address.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the transfer fails or returns an
    ///      unexpected value.
    ///
    /// @param token     The token to transfer.
    /// @param owner     The address of the owner.
    /// @param recipient The address of the recipient.
    /// @param amount    The amount of tokens to transfer.
    function safeTransferFrom(address token, address owner, address recipient, uint256 amount) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, owner, recipient, amount)
        );

        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert ERC20CallFailed(token, success, data);
        }
    }
}



/** 
 *  SourceUnit: /Users/patrickmckelvy/code/defi/os/alchemix/alops/submodules/v2-foundry/src/adapters/rocket/RETHAdapterV1.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: GPL-2.0-or-later
pragma solidity 0.8.13;

////import {IllegalState} from "./ErrorMessages.sol";

/// @title  Mutex
/// @author Alchemix Finance
///
/// @notice Provides a mutual exclusion lock for implementing contracts.
abstract contract MutexLock {
    enum State {
        RESERVED,
        UNLOCKED,
        LOCKED
    }

    /// @notice The lock state.
    State private _lockState = State.UNLOCKED;

    /// @dev A modifier which acquires the mutex.
    modifier lock() {
        _claimLock();

        _;

        _freeLock();
    }

    /// @dev Gets if the mutex is locked.
    ///
    /// @return if the mutex is locked.
    function _isLocked() internal view returns (bool) {
        return _lockState == State.LOCKED;
    }

    /// @dev Claims the lock. If the lock is already claimed, then this will revert.
    function _claimLock() internal {
        // Check that the lock has not been claimed yet.
        if (_lockState != State.UNLOCKED) {
            revert IllegalState("Lock already claimed");
        }

        // Claim the lock.
        _lockState = State.LOCKED;
    }

    /// @dev Frees the lock.
    function _freeLock() internal {
        _lockState = State.UNLOCKED;
    }
}

/** 
 *  SourceUnit: /Users/patrickmckelvy/code/defi/os/alchemix/alops/submodules/v2-foundry/src/adapters/rocket/RETHAdapterV1.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: GPL-3.0-or-later
pragma solidity 0.8.13;

////import {IERC20} from "../../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

////import {
//     IllegalArgument,
//     IllegalState,
//     Unauthorized,
//     UnsupportedOperation
// } from "../../base/ErrorMessages.sol";

////import {MutexLock} from "../../base/MutexLock.sol";

////import {SafeERC20} from "../../libraries/SafeERC20.sol";
////import {RocketPool} from "../../libraries/RocketPool.sol";

////import {ITokenAdapter} from "../../interfaces/ITokenAdapter.sol";
////import {IWETH9} from "../../interfaces/external/IWETH9.sol";
////import {IRETH} from "../../interfaces/external/rocket/IRETH.sol";
////import {IRocketStorage} from "../../interfaces/external/rocket/IRocketStorage.sol";
////import {ISwapRouter} from "../../interfaces/external/uniswap/ISwapRouter.sol";

struct InitializationParams {
    address alchemist;
    address token;
    address underlyingToken;
}

contract RETHAdapterV1 is ITokenAdapter, MutexLock {
    using RocketPool for IRocketStorage;

    address constant uniswapRouterV3 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    string public override version = "1.1.0";

    address public immutable alchemist;
    address public immutable override token;
    address public immutable override underlyingToken;

    constructor(InitializationParams memory params) {
        alchemist       = params.alchemist;
        token           = params.token;
        underlyingToken = params.underlyingToken;
    }

    /// @dev Checks that the message sender is the alchemist that the adapter is bound to.
    modifier onlyAlchemist() {
        if (msg.sender != alchemist) {
            revert Unauthorized("Not alchemist");
        }
        _;
    }

    receive() external payable {
        if (msg.sender != underlyingToken && msg.sender != token) {
            revert Unauthorized("Payments only permitted from WETH or rETH");
        }
    }

    /// @inheritdoc ITokenAdapter
    function price() external view returns (uint256) {
        return IRETH(token).getEthValue(10**SafeERC20.expectDecimals(token));
    }

    /// @inheritdoc ITokenAdapter
    function wrap(
        uint256 amount,
        address recipient
    ) external onlyAlchemist returns (uint256) {
        amount; recipient; // Silence, compiler!

        // NOTE: Wrapping is currently unsupported because the Rocket Pool requires that all
        //       addresses that mint rETH to wait approximately 24 hours before transferring
        //       tokens. In the future when the minting restriction is removed, an adapter
        //       that supports this operation will be written.
        //
        //       We had considered exchanging ETH for rETH here, however, the liquidity on the
        //       majority of the pools is too limited. Also, the landscape of those pools are very
        //       likely to change in the coming months. We recommend that users exchange for
        //       rETH on a pool of their liking or mint rETH and then deposit it at a later time.
        revert UnsupportedOperation("Wrapping is not supported");
    }

    // @inheritdoc ITokenAdapter
    function unwrap(
        uint256 amount,
        address recipient
    ) external lock onlyAlchemist returns (uint256) {
        // Transfer the rETH from the message sender.
        SafeERC20.safeTransferFrom(token, msg.sender, address(this), amount);

        uint256 receivedEth = 0;

        uint256 ethValue = IRETH(token).getEthValue(amount);
        if (IRETH(token).getTotalCollateral() >= ethValue) {
            // Burn the rETH to receive ETH.
            uint256 startingEthBalance = address(this).balance;
            IRETH(token).burn(amount);
            receivedEth = address(this).balance - startingEthBalance;

            // Wrap the ETH that we received from the burn.
            IWETH9(underlyingToken).deposit{value: receivedEth}();
        } else {
            // Set up and execute uniswap exchange
            SafeERC20.safeApprove(token, uniswapRouterV3, amount);
            ISwapRouter.ExactInputSingleParams memory params =
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: token,
                    tokenOut: underlyingToken,
                    fee: 3000,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: amount,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });

            receivedEth = ISwapRouter(uniswapRouterV3).exactInputSingle(params);
        }

        // Transfer the tokens to the recipient.
        SafeERC20.safeTransfer(underlyingToken, recipient, receivedEth);

        return receivedEth;
    }
}