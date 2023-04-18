/**
 *Submitted for verification at BscScan.com on 2023-04-17
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

struct Transaction {
    uint256 gasPrice;
    uint256 gasLimit;
    uint256 value;
    uint256 nonce;
    bytes data;
    address to;
    address from;
    uint8 v;
    bytes32 r;
    bytes32 s;
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

interface ITransactionValidator {
    function validateTransaction(
        Condition memory condition, 
        RequiredCondition memory requiredCondition, 
        Transaction calldata transaction
    ) external view returns(bool);
}

interface ITransactionSenderVerifier {
    function getTransactionSender(
        uint256 gasPrice, 
        uint256 gasLimit, 
        uint256 value, 
        uint256 nonce, 
        bytes memory data, 
        address to, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external view returns(address);
}

pragma solidity ^0.8.1;

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

/// @title On-chain transaction data decoder
/// @author P. Zibarov
/// @notice You can use this contract to get transaction call arguments from transaction data
/// @dev This contract is on development stage, functions can have side-effects
contract TransactionValidator is ITransactionValidator {
    string constant APPROVE_SELECTOR = "approve(address,uint256)";
    string constant TRANSFER_SELECTOR = "transfer(address,uint256)";
    string constant TRANSFER_FROM_SELECTOR = "transferFrom(address,address,uint256)";
    string constant SWAP_EXACT_ETH_FOR_TOKENS_SELECTOR = "swapExactETHForTokens(uint256,address[],address,uint256)";
    string constant SWAP_EXACT_TOKENS_FOR_TOKENS_SELECTOR = "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)";
    string constant REMOVE_LIQUIDITY_SELECTOR = "removeLiquidity(address,address,uint256,uint256,uint256,address,uint256)";
    string constant REMOVE_LIQUIDITY_WITH_PERMIT_SELECTOR = "removeLiquidityWithPermit(address,address,uint256,uint256,uint256,address,uint256,bool,uint8,bytes32,bytes32)";

    /// @notice address of on-chain transaction sender verifier 
    address public verifier;

    error NotAContract();
    error InvalidRequestAction();

    error IncorrectSelector(bytes4 required, bytes4 actual);

    error SenderNotVerified(address required, address recovered);
    error TransactionNonceMissmatch(uint256 required, uint256 actual);
    error TransactionSenderMissmatch(address required, address actual);
    error TransactionReceiverMissmatch(address required, address actual);
    error TransactionValueMissmatch(uint256 required, uint256 actual);

    error ApprovalToMissmatch(address required, address actual);
    error ApprovalAmountMissmatch(uint256 required, uint256 actual);

    error TransferFromMissmatch(address required, address actual);
    error TransferToMissmatch(address required, address actual);
    error TransferAmountMissmatch(uint256 required, uint256 actual);

    error SwapAssetAMissmatch(address required, address actual);
    error SwapAssetBMissmatch(address required, address actual);
    error SwapAssetAAmountMissmatch(uint256 required, uint256 actual);
    error SwapAssetBAmountMissmatch(uint256 required, uint256 actual);
    error SwapAssetAAmountMinMissmatch(uint256 required, uint256 actual);
    error SwapAssetBAmountMinMissmatch(uint256 required, uint256 actual);
    error SwapReceiverMissmatch(address required, address actual);

    error RemoveLiquidityAssetAMissmatch(address required, address actual);
    error RemoveLiquidityAssetBMissmatch(address required, address actual);
    error RemoveLiquidityAmountMissmatch(uint256 required, uint256 actual);
    error RemoveLiquidityAssetAAmountMinMissmatch(uint256 required, uint256 actual);
    error RemoveLiquidityAssetBAmountMinMissmatch(uint256 required, uint256 actual);
    error RemoveLiquidityReceiverMissmatch(address required, address actual);
    error RemoveLiquidityApproveMaxMissmatch(bool required, bool actual);

    constructor(address _verifier) {
        if(!Address.isContract(_verifier)) revert NotAContract();

        verifier = _verifier;
    }
    
    /// @notice Validates proposed transaction data based on conditions and function selector 
    /// @param condition - id of the request that conditions should match with proposed transaction
    /// @param requiredCondition -
    /// @param transaction -
    function validateTransaction(
        Condition memory condition, 
        RequiredCondition memory requiredCondition, 
        Transaction calldata transaction
    ) external view returns(bool) {
        address sender = ITransactionSenderVerifier(verifier).getTransactionSender(
            transaction.gasPrice, 
            transaction.gasLimit, 
            transaction.value, 
            transaction.nonce, 
            transaction.data, 
            transaction.to, 
            transaction.v, 
            transaction.r, 
            transaction.s
        );

        if(sender != condition.sender) revert TransactionSenderMissmatch({ required: condition.sender, actual: sender });
        if(transaction.to != condition.receiver) revert TransactionReceiverMissmatch({ required: condition.sender, actual: sender });
        if(transaction.nonce < condition.initialNonce) revert TransactionNonceMissmatch({ required: condition.initialNonce, actual: transaction.nonce });

        return validateTransactionData(condition, requiredCondition, transaction);
    }

    function validateTransactionData(
        Condition memory condition, 
        RequiredCondition memory requiredCondition, 
        Transaction calldata transaction
    ) public pure returns(bool) {
        if(condition.action == RequestAction.Any) {
            return validateAny();
        } else if(condition.action == RequestAction.Approve) {
            return validateApprovalParameters(condition, requiredCondition, transaction);
        } else if(condition.action == RequestAction.Transfer) {
            return validateTransferParameters(condition, requiredCondition, transaction);
        } else if(condition.action == RequestAction.TransferFrom) {
            return validateTransferFromParameters(condition, requiredCondition, transaction);
        } else if(condition.action == RequestAction.SwapExactTokensForTokens) {
            return validateSwapExactTokensForTokensParameters(condition, requiredCondition, transaction);
        } else if(condition.action == RequestAction.SwapExactNativeForTokens) {
            return validateSwapExactNativeForTokensParameters(condition, requiredCondition, transaction);
        } else if(condition.action == RequestAction.RemoveLiquidity) {
            return validateRemoveLiquidityParameters(condition, requiredCondition, transaction);
        } else if(condition.action == RequestAction.RemoveLiquidityWithPermit) {
            return validateRemoveLiquidityWithPermitParameters(condition, requiredCondition, transaction);
        } else if(condition.action == RequestAction.NativeTransfer) {
            return validateNativeTransfer(condition, requiredCondition, transaction);
        }

        revert InvalidRequestAction();
    }

    function validateAny() public pure returns(bool) {
        return true;
    }

    function validateApprovalParameters(
        Condition memory condition, 
        RequiredCondition memory requiredCondition, 
        Transaction calldata transaction
    ) public pure returns(bool) {
        (address approvalTo, uint256 approvalAmount) = decodeApprove(transaction.data);
        
        if(approvalTo != condition.to) revert ApprovalToMissmatch({ required: condition.to, actual: approvalTo });

        if(requiredCondition.assetAAmountRequired) {
            if(condition.assetAAmount > approvalAmount) revert ApprovalAmountMissmatch({ required: condition.assetAAmount, actual: approvalAmount });
        } 

        return true;
    }

    function validateTransferParameters(
        Condition memory condition, 
        RequiredCondition memory requiredCondition, 
        Transaction calldata transaction
    ) public pure returns(bool) {
        (address transferTo, uint256 transferAmount) = decodeTransfer(transaction.data);
        
        if(transferTo != condition.to) revert TransferToMissmatch({ required: condition.to, actual: transferTo });

        if(requiredCondition.assetAAmountRequired) {
            if(condition.assetAAmount > transferAmount) revert TransferAmountMissmatch({ required: condition.assetAAmount, actual: transferAmount });
        } 

        return true;
    }

    function validateTransferFromParameters(
        Condition memory condition, 
        RequiredCondition memory requiredCondition, 
        Transaction calldata transaction
    ) public pure returns(bool) {
        (address transferFrom, address transferTo, uint256 transferAmount) = decodeTransferFrom(transaction.data);
        
        if(requiredCondition.fromRequired) {
            if(transferFrom != condition.from) revert TransferFromMissmatch({ required: condition.from, actual: transferFrom });
        }

        if(requiredCondition.toRequired) {
            if(transferTo != condition.to) revert TransferToMissmatch({ required: condition.to, actual: transferTo });
        }

        if(requiredCondition.assetAAmountRequired) {
            if(condition.assetAAmount > transferAmount) revert TransferAmountMissmatch({ required: condition.assetAAmount, actual: transferAmount });
        } 

        return true;
    }

    function validateSwapExactTokensForTokensParameters(
        Condition memory condition, 
        RequiredCondition memory requiredCondition, 
        Transaction calldata transaction
    ) public pure returns(bool) {
        (uint256 amountIn, uint256 amountOutMin, address[] memory path, address assetBReceiver,) = decodeSwapExactTokensForTokens(transaction.data);

        if(path[0] != condition.assetA) revert SwapAssetAMissmatch({ required: condition.assetA, actual: path[0] });
        
        if(requiredCondition.assetBRequired) {
            if(path[path.length - 1] != condition.assetB) revert SwapAssetBMissmatch({ required: condition.assetB, actual: path[path.length - 1] });
        }

        if(requiredCondition.assetAAmountRequired) {
            if(condition.assetAAmount > amountIn) revert SwapAssetAAmountMissmatch({ required: condition.assetAAmount, actual: amountIn });
        }

        if(requiredCondition.assetBAmountMinRequired) {
            if(condition.assetBAmountMin > amountOutMin) revert SwapAssetBAmountMinMissmatch({ required: condition.assetBAmountMin, actual: amountOutMin });
        }

        if(requiredCondition.toRequired) {
            if(assetBReceiver != condition.to) revert SwapReceiverMissmatch({ required: condition.to, actual: assetBReceiver });
        }

        return true;
    }

    function validateSwapExactNativeForTokensParameters(
        Condition memory condition, 
        RequiredCondition memory requiredCondition, 
        Transaction calldata transaction
    ) public pure returns(bool) {
        (uint256 amountOutMin, address[] memory path, address assetBReceiver,) = decodeSwapExactETHForTokens(transaction.data);
        
        if(requiredCondition.assetBRequired) {
            if(path[path.length - 1] != condition.assetB) revert SwapAssetBMissmatch({ required: condition.assetB, actual: path[path.length - 1] });
        }

        if(requiredCondition.assetAAmountRequired) {
            if(condition.assetAAmount > transaction.value) revert SwapAssetAAmountMissmatch({ required: condition.assetAAmount, actual: transaction.value });
        }

        if(requiredCondition.assetBAmountMinRequired) {
            if(condition.assetBAmountMin > amountOutMin) revert SwapAssetBAmountMinMissmatch({ required: condition.assetBAmountMin, actual: amountOutMin });
        }

        if(requiredCondition.toRequired) {
            if(assetBReceiver != condition.to) revert SwapReceiverMissmatch({ required: condition.to, actual: assetBReceiver });
        }

        return true;
    }

    function validateRemoveLiquidityParameters(
        Condition memory condition, 
        RequiredCondition memory requiredCondition, 
        Transaction calldata transaction
    ) public pure returns(bool) {
        (address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to,) = decodeRemoveLiqudity(transaction.data);

        if(tokenA != condition.assetA) revert RemoveLiquidityAssetAMissmatch({ required: condition.assetA, actual: tokenA });
        if(tokenB != condition.assetB) revert RemoveLiquidityAssetBMissmatch({ required: condition.assetB, actual: tokenB });
        
        if(requiredCondition.liquidityAmountRequired) {
            if(condition.liquidityAmount > liquidity) revert RemoveLiquidityAmountMissmatch({ required: condition.liquidityAmount, actual: liquidity });
        }

        if(requiredCondition.assetAAmountMinRequired) {
            if(condition.assetAAmountMin > amountAMin) revert RemoveLiquidityAssetAAmountMinMissmatch({ required: condition.assetAAmountMin, actual: amountAMin });
        }

        if(requiredCondition.assetBAmountMinRequired) {
            if(condition.assetBAmountMin > amountBMin) revert RemoveLiquidityAssetBAmountMinMissmatch({ required: condition.assetBAmountMin, actual: amountBMin });
        }

        if(requiredCondition.toRequired) {
            if(to != condition.to) revert RemoveLiquidityReceiverMissmatch({ required: condition.to, actual: to });
        }

        return true;
    }

    function validateRemoveLiquidityWithPermitParameters(
        Condition memory condition, 
        RequiredCondition memory requiredCondition, 
        Transaction calldata transaction
    ) public pure returns(bool) {
        (address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to,, bool approveMax) = decodeRemoveLiqudityWithPermit(transaction.data);

        if(tokenA != condition.assetA) revert RemoveLiquidityAssetAMissmatch({ required: condition.assetA, actual: tokenA });
        if(tokenB != condition.assetB) revert RemoveLiquidityAssetBMissmatch({ required: condition.assetB, actual: tokenB });
        
        if(requiredCondition.liquidityAmountRequired) {
            if(condition.liquidityAmount > liquidity) revert RemoveLiquidityAmountMissmatch({ required: condition.liquidityAmount, actual: liquidity });
        }

        if(requiredCondition.assetAAmountRequired) {
            if(condition.assetAAmountMin > amountAMin) revert RemoveLiquidityAssetAAmountMinMissmatch({ required: condition.assetAAmountMin, actual: amountAMin });
        }

        if(requiredCondition.assetBAmountRequired) {
            if(condition.assetBAmountMin > amountBMin) revert RemoveLiquidityAssetBAmountMinMissmatch({ required: condition.assetBAmountMin, actual: amountBMin });
        }

        if(requiredCondition.toRequired) {
            if(to != condition.to) revert RemoveLiquidityReceiverMissmatch({ required: condition.to, actual: to });
        }

        if(requiredCondition.approveMaxRequired) {
            if(approveMax != condition.approveMax) revert RemoveLiquidityApproveMaxMissmatch({ required: condition.approveMax, actual: approveMax });
        }

        return true;
    }

    function validateNativeTransfer(
        Condition memory condition, 
        RequiredCondition memory requiredCondition, 
        Transaction calldata transaction
    ) public pure returns(bool) {
        if(requiredCondition.valueRequired) {
            if(transaction.value < condition.value) revert TransactionValueMissmatch({ required: condition.value, actual: transaction.value });
        }

        return true;
    }

    /// @notice Decode and parce ERC20 approve function call data
    /// @param data - transaction data
    /// @return to - token approve receiver address
    /// @return amount - approve amount
    function decodeApprove(bytes calldata data) public pure returns(address to, uint256 amount) {
        if(bytes4(data) != bytes4(keccak256(bytes(APPROVE_SELECTOR)))) 
            revert IncorrectSelector({ required: bytes4(keccak256(bytes(APPROVE_SELECTOR))), actual: bytes4(data)});

        (to, amount) = abi.decode(data[4:], (address, uint256));
    }

    /// @notice Decode and parce ERC20 transfer function call data
    /// @param data - transaction data
    /// @return to - token receiver address
    /// @return amount - transfer amount
    function decodeTransfer(bytes calldata data) public pure returns(address to, uint256 amount) {
        if(bytes4(data) != bytes4(keccak256(bytes(TRANSFER_SELECTOR)))) 
            revert IncorrectSelector({ required: bytes4(keccak256(bytes(TRANSFER_SELECTOR))), actual: bytes4(data)});
            
        (to, amount) = abi.decode(data[4:], (address, uint256));
    }

    /// @notice Decode and parce ERC20 transfer from function call data
    /// @param data - transaction data
    /// @return from - token holder address
    /// @return to - token receiver address
    /// @return amount - transfer amount
    function decodeTransferFrom(bytes calldata data) public pure returns(address from, address to, uint256 amount) {
        if(bytes4(data) != bytes4(keccak256(bytes(TRANSFER_FROM_SELECTOR)))) 
            revert IncorrectSelector({ required: bytes4(keccak256(bytes(TRANSFER_FROM_SELECTOR))), actual: bytes4(data)});

        (from, to, amount) = abi.decode(data[4:], (address, address, uint256));
    }

    /// @notice Decode and parce router SwapExactTokensForTokens function call data
    /// @param data - transaction data
    /// @return amountIn - input token amount
    /// @return amountOutMin - minimum output token amount
    /// @return path - tokens addresses as swap direction
    /// @return to - output token amount receiver address
    /// @return deadline - swap deadline
    function decodeSwapExactTokensForTokens(bytes calldata data) public pure returns(
        uint256 amountIn, 
        uint256 amountOutMin, 
        address[] memory path, 
        address to, 
        uint256 deadline
    ) {
        if(bytes4(data) != bytes4(keccak256(bytes(SWAP_EXACT_TOKENS_FOR_TOKENS_SELECTOR)))) 
            revert IncorrectSelector({ required: bytes4(keccak256(bytes(SWAP_EXACT_TOKENS_FOR_TOKENS_SELECTOR))), actual: bytes4(data)});

        (amountIn, amountOutMin, path, to, deadline) = abi.decode(data[4:], (uint256, uint256, address[], address, uint256));
    }

    /// @notice Decode and parce router SwapExactETHForTokens function call data
    /// @dev Used in RugpullProtector smart contract for request filtering
    /// @param data - transaction data
    /// @return amountOutMin - minimum output token amount
    /// @return path - tokens addresses as swap direction
    /// @return to - output token amount receiver address
    /// @return deadline - operation deadline
    function decodeSwapExactETHForTokens(bytes calldata data) public pure returns(
        uint256 amountOutMin, 
        address[] memory path, 
        address to, 
        uint256 deadline
    ) {
        if(bytes4(data) != bytes4(keccak256(bytes(SWAP_EXACT_ETH_FOR_TOKENS_SELECTOR)))) 
            revert IncorrectSelector({ required: bytes4(keccak256(bytes(SWAP_EXACT_ETH_FOR_TOKENS_SELECTOR))), actual: bytes4(data)});

        (amountOutMin, path, to, deadline) = abi.decode(data[4:], (uint256, address[], address, uint256));
    }

    /// @notice Decode and parce router RemoveLiquidity function call data
    /// @dev Used in RugpullProtector smart contract for request filtering
    /// @param data - transaction data
    /// @return tokenA - first token address
    /// @return tokenB - second token address
    /// @return liquidity - liquidity amount
    /// @return amountAMin - minimum output first token amount
    /// @return amountBMin - minimum output second token amount
    /// @return to - liquidity amount receiver address
    /// @return deadline - operation deadline
    function decodeRemoveLiqudity(bytes calldata data) public pure returns(
        address tokenA, 
        address tokenB, 
        uint256 liquidity, 
        uint256 amountAMin, 
        uint256 amountBMin, 
        address to, 
        uint256 deadline
    ) {
        if(bytes4(data) != bytes4(keccak256(bytes(REMOVE_LIQUIDITY_SELECTOR)))) 
            revert IncorrectSelector({ required: bytes4(keccak256(bytes(REMOVE_LIQUIDITY_SELECTOR))), actual: bytes4(data)});

        (tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline) = abi.decode(data[4:], (
            address, 
            address, 
            uint256, 
            uint256, 
            uint256, 
            address, 
            uint256
        ));
    }

    /// @notice Decode and parce router RemoveLiquidityWithPermit function call data
    /// @dev Used in RugpullProtector smart contract for request filtering
    /// @param data - transaction data
    /// @return tokenA - first token address
    /// @return tokenB - second token address
    /// @return liquidity - liquidity amount
    /// @return amountAMin - minimum output first token amount
    /// @return amountBMin - minimum output second token amount
    /// @return to - liquidity amount receiver address
    /// @return deadline - operation deadline
    /// @return approveMax - allowance for all liquidity amount
    function decodeRemoveLiqudityWithPermit(bytes calldata data) public pure returns(
        address tokenA, 
        address tokenB, 
        uint256 liquidity, 
        uint256 amountAMin, 
        uint256 amountBMin, 
        address to, 
        uint256 deadline,
        bool approveMax
    ) {
        if(bytes4(data) != bytes4(keccak256(bytes(REMOVE_LIQUIDITY_WITH_PERMIT_SELECTOR)))) 
            revert IncorrectSelector({ required: bytes4(keccak256(bytes(REMOVE_LIQUIDITY_WITH_PERMIT_SELECTOR))), actual: bytes4(data)});

        (tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline, approveMax) = abi.decode(data[4:], (
            address, 
            address, 
            uint256, 
            uint256, 
            uint256, 
            address, 
            uint256,
            bool
        ));
    }
}