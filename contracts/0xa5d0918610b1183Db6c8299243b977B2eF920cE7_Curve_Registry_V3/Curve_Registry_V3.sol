/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

// Sources flattened with hardhat v2.10.1 https://hardhat.org

// File contracts/libraries/Context.sol

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File contracts/libraries/Ownable.sol

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File contracts/libraries/Address.sol

pragma solidity ^0.8.0;

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


// File contracts/interfaces/IERC20.sol

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the decimals of the ERC20 token.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


// File contracts/libraries/SafeERC20.sol

pragma solidity ^0.8.0;


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}


// File contracts/CurveRegistryV3.sol

// Copyright (C) 2022 Zapper (Zapper.Fi)

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
// See theGNU Affero General Public License for more details.

///@author Zapper
///@notice Registry for Curve Pools with Utility functions.

// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;

interface ICurveAddressProvider {
    function get_registry() external view returns (address);

    function get_address(uint256 _id) external view returns (address);
}

interface ICurveRegistry {
    function get_pool_from_lp_token(address lpToken)
        external
        view
        returns (address);

    function get_lp_token(address swapAddress) external view returns (address);

    function get_n_coins(address _pool)
        external
        view
        returns (uint256[2] memory);

    function get_coins(address _pool) external view returns (address[8] memory);

    function get_underlying_coins(address _pool)
        external
        view
        returns (address[8] memory);
}

interface ICurveCryptoRegistry {
    function get_pool_from_lp_token(address lpToken)
        external
        view
        returns (address);

    function get_lp_token(address swapAddress) external view returns (address);

    function get_n_coins(address _pool) external view returns (uint256);

    function get_coins(address _pool) external view returns (address[8] memory);
}

interface ICurveFactoryRegistry {
    function get_n_coins(address _pool) external view returns (uint256);

    function get_coins(address _pool) external view returns (address[2] memory);

    function get_underlying_coins(address _pool)
        external
        view
        returns (address[8] memory);
}

interface ICurveV2Pool {
    function price_oracle(uint256 k) external view returns (uint256);
}




contract Curve_Registry_V3 is Ownable {
    using SafeERC20 for IERC20;

    ICurveAddressProvider internal constant CurveAddressProvider =
        ICurveAddressProvider(0x0000000022D53366457F9d5E68Ec105046FC4383);

    ICurveRegistry public CurveRegistry;
    ICurveFactoryRegistry public FactoryRegistry;
    ICurveCryptoRegistry public CurveCryptoRegistry;

    address internal constant wbtcToken =
        0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address internal constant sbtcCrvToken =
        0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3;
    address internal constant ETHAddress =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    mapping(address => bool) public shouldAddUnderlying;
    mapping(address => address) private depositAddresses; // Mapping Pool -> Deposit Contract

    constructor() {
        CurveRegistry = ICurveRegistry(CurveAddressProvider.get_registry());
        FactoryRegistry = ICurveFactoryRegistry(
            CurveAddressProvider.get_address(3)
        );
        CurveCryptoRegistry = ICurveCryptoRegistry(
            CurveAddressProvider.get_address(5)
        );

        // Set mappings
        depositAddresses[
            0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51
        ] = 0xbBC81d23Ea2c3ec7e56D39296F0cbB648873a5d3;
        depositAddresses[
            0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56
        ] = 0xeB21209ae4C2c9FF2a86ACA31E123764A3B6Bc06;
        depositAddresses[
            0x52EA46506B9CC5Ef470C5bf89f17Dc28bB35D85C
        ] = 0xac795D2c97e60DF6a99ff1c814727302fD747a80;
        depositAddresses[
            0x06364f10B501e868329afBc005b3492902d6C763
        ] = 0xA50cCc70b6a011CffDdf45057E39679379187287;
        depositAddresses[
            0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27
        ] = 0xb6c057591E073249F2D9D88Ba59a46CFC9B59EdB;
        depositAddresses[
            0xA5407eAE9Ba41422680e2e00537571bcC53efBfD
        ] = 0xFCBa3E75865d2d561BE8D220616520c171F12851;

        shouldAddUnderlying[0xDeBF20617708857ebe4F679508E7b7863a8A8EeE] = true;
        shouldAddUnderlying[0xEB16Ae0052ed37f479f7fe63849198Df1765a733] = true;
        shouldAddUnderlying[0x2dded6Da1BF5DBdF597C45fcFaa3194e53EcfeAF] = true;
    }

    /**
    @notice Checks if the pool is an original (non-factory) pool
    @param swapAddress Curve swap address for the pool
    @return true if pool is a non-factory pool, false otherwise
    */
    function isCurvePool(address swapAddress) public view returns (bool) {
        if (CurveRegistry.get_lp_token(swapAddress) != address(0)) {
            return true;
        }
        return false;
    }

    /**
    @notice Checks if the pool is a factory pool
    @param swapAddress Curve swap address for the pool
    @return true if pool is a factory pool, false otherwise
    */
    function isFactoryPool(address swapAddress) public view returns (bool) {
        if (FactoryRegistry.get_coins(swapAddress)[0] != address(0)) {
            return true;
        }
        return false;
    }

    /**
    @notice Checks if the pool is a Crypto pool
    @param swapAddress Curve swap address for the pool
    @return true if pool is a crypto pool, false otherwise
    */
    function isCryptoPool(address swapAddress) public view returns (bool) {
        if (CurveCryptoRegistry.get_lp_token(swapAddress) != address(0)) {
            return true;
        }
        return false;
    }

    /**
    @notice Checks if the Pool is a metapool
    @notice All factory pools are metapools but not all metapools are factory pools! (e.g. dusd)
    @param swapAddress Curve swap address for the pool
    @return true if the pool is a metapool, false otherwise
    */
    function isMetaPool(address swapAddress) public view returns (bool) {
        if (isCurvePool(swapAddress)) {
            uint256[2] memory poolTokenCounts = CurveRegistry.get_n_coins(
                swapAddress
            );

            if (poolTokenCounts[0] == poolTokenCounts[1]) return false;
            else return true;
        }
        if (isCryptoPool(swapAddress)) {
            uint256 poolTokensCount = CurveCryptoRegistry.get_n_coins(
                swapAddress
            );
            address[8] memory poolTokens = CurveCryptoRegistry.get_coins(
                swapAddress
            );

            for (uint256 i = 0; i < poolTokensCount; i++) {
                if (isCurvePool(poolTokens[i])) return true;
            }
        }
        if (isFactoryPool(swapAddress)) return true;
        return false;
    }

    /**
    @notice Checks if the Pool is metapool of the Curve or Factory pool type
    @notice All factory pools are metapools but not all metapools are factory pools! (e.g. dusd)
    @param swapAddress Curve swap address for the pool
    @return 1 if Meta Curve Pool
            2 if Meta Factory Pool
            0 otherwise
    */
    function _isCurveFactoryMetaPool(address swapAddress)
        internal
        view
        returns (uint256)
    {
        if (isCurvePool(swapAddress)) {
            uint256[2] memory poolTokenCounts = CurveRegistry.get_n_coins(
                swapAddress
            );

            if (poolTokenCounts[0] == poolTokenCounts[1]) return 0;
            else return 1;
        }
        if (isFactoryPool(swapAddress)) return 2;
        return 0;
    }

    /**
    @notice Checks if the pool is a Curve V2 pool
    @param swapAddress Curve swap address for the pool
    @return true if pool is a V2 pool, false otherwise
    */
    function isV2Pool(address swapAddress) public view returns (bool) {
        try ICurveV2Pool(swapAddress).price_oracle(0) {
            return true;
        } catch {
            return false;
        }
    }

    /**
    @notice Gets the Curve pool deposit address
    @notice The deposit address is used for pools with wrapped (c, y) tokens
    @param swapAddress Curve swap address for the pool
    @return depositAddress Curve pool deposit address or the swap address if not mapped
    */
    function getDepositAddress(address swapAddress)
        external
        view
        returns (address depositAddress)
    {
        depositAddress = depositAddresses[swapAddress];
        if (depositAddress == address(0)) return swapAddress;
    }

    /**
    @notice Gets the Curve pool swap address
    @notice The token and swap address is the same for metapool/factory pools
    @param tokenAddress Curve swap address for the pool
    @return swapAddress Curve pool swap address or address(0) if pool doesnt exist
    */
    function getSwapAddress(address tokenAddress)
        external
        view
        returns (address swapAddress)
    {
        swapAddress = CurveRegistry.get_pool_from_lp_token(tokenAddress);
        if (swapAddress != address(0)) {
            return swapAddress;
        }
        swapAddress = CurveCryptoRegistry.get_pool_from_lp_token(tokenAddress);
        if (swapAddress != address(0)) {
            return swapAddress;
        }
        if (isFactoryPool(tokenAddress)) {
            return tokenAddress;
        }
        return address(0);
    }

    /**
    @notice Gets the Curve pool token address
    @notice The token and swap address is the same for metapool/factory pools
    @param swapAddress Curve swap address for the pool
    @return tokenAddress Curve pool token address or address(0) if pool doesnt exist
    */
    function getTokenAddress(address swapAddress)
        external
        view
        returns (address tokenAddress)
    {
        tokenAddress = CurveRegistry.get_lp_token(swapAddress);
        if (tokenAddress != address(0)) {
            return tokenAddress;
        }
        tokenAddress = CurveCryptoRegistry.get_lp_token(swapAddress);
        if (tokenAddress != address(0)) {
            return tokenAddress;
        }
        if (isFactoryPool(swapAddress)) {
            return swapAddress;
        }
        return address(0);
    }

    /**
    @notice Gets the number of non-underlying tokens in a pool
    @param swapAddress Curve swap address for the pool
    @return number of underlying tokens in the pool
    */
    function getNumTokens(address swapAddress) public view returns (uint256) {
        if (isCurvePool(swapAddress)) {
            return CurveRegistry.get_n_coins(swapAddress)[0];
        } else if (isCryptoPool(swapAddress)) {
            return CurveCryptoRegistry.get_n_coins(swapAddress);
        } else {
            return FactoryRegistry.get_n_coins(swapAddress);
        }
    }

    /**
    @notice Gets an array of underlying pool token addresses
    @param swapAddress Curve swap address for the pool
    @return poolTokens returns 4 element array containing the 
    * addresses of the pool tokens (0 address if pool contains < 4 tokens)
    */
    function getPoolTokens(address swapAddress)
        public
        view
        returns (address[4] memory poolTokens)
    {
        uint256 isCurveFactoryMetaPool = _isCurveFactoryMetaPool(swapAddress);
        if (isCurveFactoryMetaPool == 1) {
            address[8] memory poolUnderlyingCoins = CurveRegistry.get_coins(
                swapAddress
            );
            for (uint256 i = 0; i < 2; i++) {
                poolTokens[i] = poolUnderlyingCoins[i];
            }
        } else if (isCurveFactoryMetaPool == 2) {
            address[2] memory poolUnderlyingCoins = FactoryRegistry.get_coins(
                swapAddress
            );
            for (uint256 i = 0; i < 2; i++) {
                poolTokens[i] = poolUnderlyingCoins[i];
            }
        } else if (isCryptoPool(swapAddress)) {
            address[8] memory poolUnderlyingCoins = CurveCryptoRegistry
                .get_coins(swapAddress);

            for (uint256 i = 0; i < 4; i++) {
                poolTokens[i] = poolUnderlyingCoins[i];
            }
        } else {
            address[8] memory poolUnderlyingCoins;
            if (isBtcPool(swapAddress)) {
                poolUnderlyingCoins = CurveRegistry.get_coins(swapAddress);
            } else {
                poolUnderlyingCoins = CurveRegistry.get_underlying_coins(
                    swapAddress
                );
            }
            for (uint256 i = 0; i < 4; i++) {
                poolTokens[i] = poolUnderlyingCoins[i];
            }
        }
    }

    /**
    @notice Checks if the Curve pool contains WBTC
    @param swapAddress Curve swap address for the pool
    @return true if the pool contains WBTC, false otherwise
    */
    function isBtcPool(address swapAddress) public view returns (bool) {
        address[8] memory poolTokens = CurveRegistry.get_coins(swapAddress);
        for (uint256 i = 0; i < 4; i++) {
            if (poolTokens[i] == wbtcToken || poolTokens[i] == sbtcCrvToken)
                return true;
        }
        return false;
    }

    /**
    @notice Checks if the Curve pool contains ETH
    @param swapAddress Curve swap address for the pool
    @return true if the pool contains ETH, false otherwise
    */
    function isEthPool(address swapAddress) external view returns (bool) {
        address[4] memory poolTokens = getPoolTokens(swapAddress); // NOTE Small change to include alETH
        for (uint256 i = 0; i < 4; i++) {
            if (poolTokens[i] == ETHAddress) {
                return true;
            }
        }
        return false;
    }

    /**
    @notice Check if the pool contains the toToken
    @param swapAddress Curve swap address for the pool
    @param toToken contract address of the token
    @return true if the pool contains the token, false otherwise
    @return index of the token in the pool, 0 if pool does not contain the token
    */
    function isUnderlyingToken(address swapAddress, address toToken)
        external
        view
        returns (bool, uint256)
    {
        address[4] memory poolTokens = getPoolTokens(swapAddress);
        for (uint256 i = 0; i < 4; i++) {
            if (poolTokens[i] == address(0)) return (false, 0);
            if (poolTokens[i] == toToken) return (true, i);
        }
        return (false, 0);
    }

    /**
    @notice Updates to the latest Curve registry from the address provider
    */
    function update_curve_registry() external onlyOwner {
        address new_address = CurveAddressProvider.get_registry();

        require(address(CurveRegistry) != new_address, "Already updated");

        CurveRegistry = ICurveRegistry(new_address);
    }

    /**
    @notice Updates to the latest Curve factory registry from the address provider
    */
    function update_factory_registry() external onlyOwner {
        address new_address = CurveAddressProvider.get_address(3);

        require(address(FactoryRegistry) != new_address, "Already updated");

        FactoryRegistry = ICurveFactoryRegistry(new_address);
    }

    /**
    @notice Updates to the latest Curve crypto registry from the address provider
    */
    function update_crypto_registry() external onlyOwner {
        address new_address = CurveAddressProvider.get_address(5);

        require(address(CurveCryptoRegistry) != new_address, "Already updated");

        CurveCryptoRegistry = ICurveCryptoRegistry(new_address);
    }

    /**
    @notice Add new pools which use the _use_underlying bool
    @param swapAddresses Curve swap addresses for the pool
    @param addUnderlying True if underlying tokens are always added
    */
    function updateShouldAddUnderlying(
        address[] calldata swapAddresses,
        bool[] calldata addUnderlying
    ) external onlyOwner {
        require(
            swapAddresses.length == addUnderlying.length,
            "Mismatched arrays"
        );
        for (uint256 i = 0; i < swapAddresses.length; i++) {
            shouldAddUnderlying[swapAddresses[i]] = addUnderlying[i];
        }
    }

    /**
    @notice Add new pools which use amounts for add_liquidity
    @param swapAddresses Curve swap addresses to map from
    @param _depositAddresses Curve deposit addresses to map to
    */
    function updateDepositAddresses(
        address[] calldata swapAddresses,
        address[] calldata _depositAddresses
    ) external onlyOwner {
        require(
            swapAddresses.length == _depositAddresses.length,
            "Mismatched arrays"
        );
        for (uint256 i = 0; i < swapAddresses.length; i++) {
            depositAddresses[swapAddresses[i]] = _depositAddresses[i];
        }
    }

    /**
    @notice Withdraw stuck tokens
    */
    function withdrawTokens(address[] calldata tokens) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 qty;

            if (tokens[i] == ETHAddress) {
                qty = address(this).balance;
                Address.sendValue(payable(owner()), qty);
            } else {
                qty = IERC20(tokens[i]).balanceOf(address(this));
                IERC20(tokens[i]).safeTransfer(owner(), qty);
            }
        }
    }
}