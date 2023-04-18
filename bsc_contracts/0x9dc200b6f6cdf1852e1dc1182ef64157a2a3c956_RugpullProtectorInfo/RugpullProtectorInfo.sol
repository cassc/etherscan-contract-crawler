/**
 *Submitted for verification at BscScan.com on 2023-04-17
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

enum RequestStatus {
    Completed,
    Canceled,
    Pending,
    Liquidated
}

enum RequestAction {
    Any,
    Approve,
    Transfer,
    TransferFrom,
    SwapExactTokensForTokens,
    SwapExactNativeForTokens,
    RemoveLiquidity,
    RemoveLiquidityWithPermit,
    NativeTransfer
}

struct Condition {
    RequestAction action;
    address sender;
    address receiver;
    uint256 value;
    uint256 initialNonce;
    address from;
    address to;
    address assetA;
    address assetB;
    address router;
    uint256 assetAAmount;
    uint256 assetAAmountMin;
    uint256 assetBAmount;
    uint256 assetBAmountMin;
    uint256 liquidityAmount;
    bool approveMax;
}

enum ResponseAction {
    TransferFrom,
    SwapExactTokensForTokens,
    SwapExactTokensForNative,
    RemoveLiquidity
}

struct Response {
    ResponseAction action;
    address from;
    address to;
    address assetA;
    address assetB;
    address router;
    uint256 liquidityAmount;
    uint256 assetAAmount;
    uint256 assetAAmountMin;
    uint256 assetBAmount;
    uint256 assetBAmountMin;
    uint256 deadline;
    bool approveMax;
    uint8 v;
    bytes32 r;
    bytes32 s;
}

struct RequiredCondition {
    bool senderRequired;
    bool receiverRequired;
    bool valueRequired;
    bool initialNonceRequired;
    bool fromRequired;
    bool toRequired;
    bool assetARequired;
    bool assetBRequired;
    bool routerRequired;
    bool assetAAmountRequired;
    bool assetAAmountMinRequired;
    bool assetBAmountRequired;
    bool assetBAmountMinRequired;
    bool liquidityAmountRequired;
    bool approveMaxRequired;
}

struct Request {
    uint256 id;
    address requester;
    address rewardAsset;
    uint256 rewardAmount;
    uint256 deadline;
    Condition condition;
    RequiredCondition requiredCondition;
    Response response;
    RequestStatus status;
}

interface IRugpullProtectorInfo {
    function addToActiveRequests(uint256 requestId, address user) external;
    function removeFromActiveRequests(uint256 requestId, address user) external;
    function addToAllowedTokens(address token) external;
    function removeFromAllowedTokensList(address token) external;
}

interface IRugpullProtector {
    function requests(uint256 id) external view returns(Request memory);
}

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
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
        return msg.data;
    }
}

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev Collection of functions related to the address type
 */
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
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

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
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

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
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

contract RugpullProtectorInfo is IRugpullProtectorInfo, Ownable {
    address public protector;
    
    /// @notice allowed tokens for request reward
    address[] public allowedTokensList;

    /// @notice active requests array
    uint256[] private _activeRequestsIds;

    /// @notice mapping request id -> request index in active requests array
    mapping(uint256 => uint256) private _activeRequestIndex;

    /// @notice active requests array created by specific user
    mapping(address => uint256[]) private _userActiveRequestsIds;

    /// @notice mapping allowed token address -> token index in allowed tokens array
    mapping(address => uint256) private _allowedTokensIndex;

    /// @notice mapping request id -> request index in active requests array created by specific user
    mapping(address => mapping(uint256 => uint256)) private _userActiveRequestIndex;

    error NotAContract();
    error NotAllowed();

    modifier onlyProtector {
        if(msg.sender != protector) revert NotAllowed();
        _;
    }

    /// @notice Returns array of active request ids
    /// @return Array of active request ids
    function getActiveRequestsIds() external view returns (uint256[] memory) {
        return _activeRequestsIds;
    }

    /// @notice Returns array of active request ids
    /// @dev Page counter starts with 0
    /// @dev If active request count less than requested page size, function will returns array with all active requests on this page
    /// @param page - number of requested page
    /// @param size - size of the requested page
    /// @return result - array of active requests data
    function getActiveRequestsPage(uint256 page, uint256 size) external view returns (Request[] memory result) {
        uint256 activeRequestCount = _activeRequestsIds.length;
        uint256 offset = page * size;

        if(activeRequestCount > offset) {
            uint256 count = activeRequestCount - offset;

            result = count >= size ? new Request[](size) : new Request[](count);

            uint256 resultLength = result.length;
            
            for(uint256 i; i < resultLength;) {
                result[i] = IRugpullProtector(protector).requests(_activeRequestsIds[i + offset]); 
                unchecked{ i++; }
            }
        }
    }

    /// @notice Returns array of active request ids created by specified user
    /// @param user - address that used for request filtering
    /// @return Array of active request ids created by specified user
    function getUserActiveRequestsIds(address user) external view returns (uint256[] memory) {
        return _userActiveRequestsIds[user];
    }

    /// @notice Returns array of user active request ids
    /// @dev Page counter starts with 0
    /// @dev If active request count less than requested page size, function will returns array with all active requests on this page
    /// @param page - user that requests should be filtered by
    /// @param page - number of requested page
    /// @param size - size of the requested page
    /// @return result - array of active requests data
    function getUserActiveRequestsPage(address user, uint256 page, uint256 size) external view returns (Request[] memory result) {
        uint256 userActiveRequestCount = _userActiveRequestsIds[user].length;
        uint256 offset = page * size;

        if(userActiveRequestCount > offset) {
            uint256 count = userActiveRequestCount - offset;

            result = count >= size ? new Request[](size) : new Request[](count);

            uint256 resultLength = result.length;
            
            for(uint256 i; i < resultLength;) {
                result[i] = IRugpullProtector(protector).requests(_userActiveRequestsIds[user][i + offset]); 
                unchecked{ i++; }
            }
        }
    }
    
    /// @notice Adds request id to active requests array
    /// @param requestId - active request identifier
    function addToActiveRequests(uint256 requestId, address user) external onlyProtector {
        _activeRequestIndex[requestId] = _activeRequestsIds.length;
        _activeRequestsIds.push(requestId);
        _userActiveRequestIndex[user][requestId] = _userActiveRequestsIds[user].length;
        _userActiveRequestsIds[user].push(requestId);
    }

    /// @notice Removes request id from active requests array
    /// @param requestId - cancelled or completed request identifier
    function removeFromActiveRequests(uint256 requestId, address user) external onlyProtector {
        uint256 lastRequestIndex = _activeRequestsIds.length - 1;
        uint256 requestIndex = _activeRequestIndex[requestId];
        uint256 lastRequestId = _activeRequestsIds[lastRequestIndex];
        _activeRequestsIds[requestIndex] = lastRequestId;
        _activeRequestIndex[lastRequestId] = requestIndex;
        delete _activeRequestIndex[requestId];
        _activeRequestsIds.pop();

        uint256 lastUserRequestIndex = _userActiveRequestsIds[user].length - 1;
        uint256 userRequestIndex = _userActiveRequestIndex[user][requestId];
        uint256 lastUserRequestId = _userActiveRequestsIds[user][lastUserRequestIndex];
        _userActiveRequestsIds[user][userRequestIndex] = lastUserRequestId;
        _userActiveRequestIndex[user][lastUserRequestId] = userRequestIndex;
        delete _userActiveRequestIndex[user][requestId];
        _userActiveRequestsIds[user].pop();
    }

    /// @notice Adds token address to allowed tokens array
    /// @param token - active request identifier
    function addToAllowedTokens(address token) external onlyProtector {
        _allowedTokensIndex[token] = allowedTokensList.length;
        allowedTokensList.push(token);
    }

    /// @notice Removes token address from allowed tokens array
    /// @param token - address of removed allowed token
    function removeFromAllowedTokensList(address token) external onlyProtector {
        uint256 lastTokenIndex = allowedTokensList.length - 1;
        uint256 tokenIndex = _allowedTokensIndex[token];
        address lastToken = allowedTokensList[lastTokenIndex];
        allowedTokensList[tokenIndex] = lastToken;
        _allowedTokensIndex[lastToken] = tokenIndex;
        delete _allowedTokensIndex[token];
        _activeRequestsIds.pop();
    }
    
    /// @notice Set Rugpull Protector contract address to the contract state
    /// @param _protector - address of the Rugpull Protector contract
    function setProtector(address _protector) external onlyOwner {
        if(!Address.isContract(_protector)) revert NotAContract();

        protector = _protector;
    }
}