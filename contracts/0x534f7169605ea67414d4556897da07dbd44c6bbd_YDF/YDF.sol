/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

/**

         __  . .* ,
       ~#@#%(" .,$ @
       ."^ ';"
      ..
     ;. :                                   . .
     ;==:                     ,,   ,[email protected]#(&*.;'
     ;. :                   .;#$% & ^^&
     ;==:                   &  ......
     ;. :                   ,,;      :
     ;==:  ._______.       ;  ;      :
     ;. :  ;    ###:__.    ;  ;      :
____.'  `._;       :  :__.' .'        `._________


Website: https://yieldfactory.club
Twitter: https://twitter.com/yieldfactory
Telegram: https://t.me/yieldfactory


 */
pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File: YLD/interfaces/IStakeRewards.sol


pragma solidity ^0.8.4;

interface IStakeRewards {
  function claimReward(bool compound) external;

  function depositRewards() external payable;

  function getShares(address wallet) external view returns (uint256);

  function setShare(
    address shareholder,
    uint256 balanceUpdate,
    bool isRemoving
  ) external;
}
// File: YLD/interfaces/IYDFVester.sol


pragma solidity ^0.8.9;

/**
 * @dev YDF token vester interface
 */

interface IYDFVester {
  function createVest(address user, uint256 amount) external;
}
// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;



/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: YLD/StakeRewards.sol

/******************************************************************************************************
YIELDFACTORY Staking Rewards

Website: https://yieldfactory.club
Twitter: https://twitter.com/yieldfactory
Telegram: https://t.me/yieldfactory
******************************************************************************************************/

pragma solidity ^0.8.9;







contract StakeRewards is IStakeRewards, Ownable {
  address public ydf;
  IERC721 private sYDF;
  IERC721 private slYDF;
  IUniswapV2Router02 private uniswapV2Router;

  uint256 public compoundBuySlippage = 2;

  uint256 public totalStakedUsers;
  uint256 public totalSharesDeposited;

  struct Share {
    uint256 amount;
    uint256 stakedTime;
  }
  struct Reward {
    uint256 totalExcluded;
    uint256 totalRealised;
  }
  mapping(address => Share) private shares;
  mapping(address => Reward) public rewards;

  uint256 public totalRewards;
  uint256 public totalDistributed;
  uint256 public rewardsPerShare;

  uint256 private constant ACC_FACTOR = 10**36;

  event AddShares(address indexed user, uint256 amount);
  event RemoveShares(address indexed user, uint256 amount);
  event ClaimReward(address user);
  event DistributeReward(address indexed user, uint256 amount);
  event DepositRewards(address indexed user, uint256 amountTokens);

  modifier onlyToken() {
    require(
      msg.sender == address(sYDF) || msg.sender == address(slYDF),
      'must be stake token'
    );
    _;
  }

  constructor(address _ydf, address _dexRouter) {
    ydf = _ydf;
    uniswapV2Router = IUniswapV2Router02(_dexRouter);
  }

  function setShare(
    address shareholder,
    uint256 balanceUpdate,
    bool isRemoving
  ) external override onlyToken {
    if (isRemoving) {
      _removeShares(shareholder, balanceUpdate);
      emit RemoveShares(shareholder, balanceUpdate);
    } else {
      _addShares(shareholder, balanceUpdate);
      emit AddShares(shareholder, balanceUpdate);
    }
  }

  function _addShares(address shareholder, uint256 amount) private {
    if (shares[shareholder].amount > 0) {
      _distributeReward(shareholder, false);
    }

    uint256 sharesBefore = shares[shareholder].amount;

    totalSharesDeposited += amount;
    shares[shareholder].amount += amount;
    shares[shareholder].stakedTime = block.timestamp;
    if (sharesBefore == 0 && shares[shareholder].amount > 0) {
      totalStakedUsers++;
    }
    rewards[shareholder].totalExcluded = getCumulativeRewards(
      shares[shareholder].amount
    );
  }

  function _removeShares(address shareholder, uint256 amount) private {
    require(
      shares[shareholder].amount > 0 &&
        (amount == 0 || amount <= shares[shareholder].amount),
      'you can only unstake if you have some staked'
    );
    _distributeReward(shareholder, false);

    uint256 removeAmount = amount == 0 ? shares[shareholder].amount : amount;

    totalSharesDeposited -= removeAmount;
    shares[shareholder].amount -= removeAmount;
    rewards[shareholder].totalExcluded = getCumulativeRewards(
      shares[shareholder].amount
    );
  }

  function depositRewards() external payable override {
    uint256 _amount = msg.value;
    require(_amount > 0, 'must provide ETH to deposit for rewards');
    require(totalSharesDeposited > 0, 'must be shares to distribute rewards');

    totalRewards += _amount;
    rewardsPerShare += (ACC_FACTOR * _amount) / totalSharesDeposited;
    emit DepositRewards(msg.sender, _amount);
  }

  function _distributeReward(address shareholder, bool compound) internal {
    if (shares[shareholder].amount == 0) {
      return;
    }

    uint256 amount = getUnpaid(shareholder);
    rewards[shareholder].totalRealised += amount;
    rewards[shareholder].totalExcluded = getCumulativeRewards(
      shares[shareholder].amount
    );

    if (amount > 0) {
      totalDistributed += amount;
      uint256 _balBefore = address(this).balance;
      if (compound) {
        uint256 _tokensToReceiveNoSlip = _getTokensToReceiveOnBuyNoSlippage(
          amount
        );
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = ydf;
        uniswapV2Router.swapExactETHForTokens{ value: amount }(
          (_tokensToReceiveNoSlip * (100 - compoundBuySlippage)) / 100, // handle slippage
          path,
          shareholder,
          block.timestamp
        );
      } else {
        payable(shareholder).call{ value: amount }('');
      }
      require(address(this).balance >= _balBefore - amount, 'took too much');
      emit DistributeReward(shareholder, amount);
    }
  }

  function _getTokensToReceiveOnBuyNoSlippage(uint256 _amountETH)
    internal
    view
    returns (uint256)
  {
    address pairAddy = IUniswapV2Factory(uniswapV2Router.factory()).getPair(
      uniswapV2Router.WETH(),
      ydf
    );
    IUniswapV2Pair pair = IUniswapV2Pair(pairAddy);
    (uint112 _r0, uint112 _r1, ) = pair.getReserves();
    if (pair.token0() == uniswapV2Router.WETH()) {
      return (_amountETH * _r1) / _r0;
    } else {
      return (_amountETH * _r0) / _r1;
    }
  }

  function claimReward(bool _compound) external override {
    _distributeReward(msg.sender, _compound);
    emit ClaimReward(msg.sender);
  }

  // returns the unpaid rewards
  function getUnpaid(address shareholder) public view returns (uint256) {
    if (shares[shareholder].amount == 0) {
      return 0;
    }

    uint256 earnedRewards = getCumulativeRewards(shares[shareholder].amount);
    uint256 rewardsExcluded = rewards[shareholder].totalExcluded;
    if (earnedRewards <= rewardsExcluded) {
      return 0;
    }

    return earnedRewards - rewardsExcluded;
  }

  function getCumulativeRewards(uint256 share) internal view returns (uint256) {
    return (share * rewardsPerShare) / ACC_FACTOR;
  }

  function getShares(address user) external view override returns (uint256) {
    return shares[user].amount;
  }

  function getsYDF() external view returns (address) {
    return address(sYDF);
  }

  function getslYDF() external view returns (address) {
    return address(slYDF);
  }

  function setCompoundBuySlippage(uint8 _slippage) external onlyOwner {
    require(_slippage <= 100, 'cannot be more than 100% slippage');
    compoundBuySlippage = _slippage;
  }

  function setsYDF(address _sYDF) external onlyOwner {
    sYDF = IERC721(_sYDF);
  }

  function setslYDF(address _slYDF) external onlyOwner {
    slYDF = IERC721(_slYDF);
  }
}
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/interfaces/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;


// File: YLD/interfaces/IYDF.sol


pragma solidity ^0.8.9;


/**
 * @dev YDF token interface
 */

interface IYDF is IERC20 {
  function addToBuyTracker(address _user, uint256 _amount) external;

  function burn(uint256 _amount) external;

  function stakeMintToVester(uint256 _amount) external;
}
// File: YLD/YDFVester.sol

/******************************************************************************************************
YIELDFACTORY Vesting Contract

Website: https://yieldfactory.club
Twitter: https://twitter.com/yieldfactory
Telegram: https://t.me/yieldfactory
******************************************************************************************************/

pragma solidity ^0.8.9;



contract YDFVester is Ownable {
  IYDF private _ydf;

  uint256 public fullyVestedPeriod = 90 days;
  uint256 public withdrawsPerPeriod = 10;

  struct TokenVest {
    uint256 start;
    uint256 end;
    uint256 totalWithdraws;
    uint256 withdrawsCompleted;
    uint256 amount;
  }
  mapping(address => TokenVest[]) public vests;
  address[] public stakeContracts;

  event CreateVest(address indexed user, uint256 amount);
  event Withdraw(address indexed user, uint256 index, uint256 amountWithdrawn);

  modifier onlyStake() {
    bool isStake;
    for (uint256 i = 0; i < stakeContracts.length; i++) {
      if (msg.sender == stakeContracts[i]) {
        isStake = true;
        break;
      }
    }
    require(isStake, 'not a staking contract');
    _;
  }

  constructor(address _token) {
    _ydf = IYDF(_token);
  }

  // we expect the staking contract (re: the owner) to transfer tokens to
  // this contract, so no need to transferFrom anywhere
  function createVest(address _user, uint256 _amount) external onlyStake {
    vests[_user].push(
      TokenVest({
        start: block.timestamp,
        end: block.timestamp + fullyVestedPeriod,
        totalWithdraws: withdrawsPerPeriod,
        withdrawsCompleted: 0,
        amount: _amount
      })
    );
    emit CreateVest(_user, _amount);
  }

  function withdraw(uint256 _index) external {
    address _user = msg.sender;
    TokenVest storage _vest = vests[_user][_index];
    require(_vest.amount > 0, 'vest does not exist');
    require(
      _vest.withdrawsCompleted < _vest.totalWithdraws,
      'already withdrew all tokens'
    );

    uint256 _tokensPerWithdrawPeriod = _vest.amount / _vest.totalWithdraws;
    uint256 _withdrawsAllowed = getWithdrawsAllowed(_user, _index);

    // make sure the calculated allowed amount doesn't exceed total amount for vest
    _withdrawsAllowed = _withdrawsAllowed > _vest.totalWithdraws
      ? _vest.totalWithdraws
      : _withdrawsAllowed;

    require(
      _vest.withdrawsCompleted < _withdrawsAllowed,
      'currently vesting, please wait for next withdrawable time period'
    );

    uint256 _withdrawsToComplete = _withdrawsAllowed - _vest.withdrawsCompleted;

    _vest.withdrawsCompleted = _withdrawsAllowed;
    _ydf.transfer(_user, _tokensPerWithdrawPeriod * _withdrawsToComplete);
    _ydf.addToBuyTracker(
      _user,
      _tokensPerWithdrawPeriod * _withdrawsToComplete
    );

    // clean up/remove vest entry if it's completed
    if (_vest.withdrawsCompleted == _vest.totalWithdraws) {
      vests[_user][_index] = vests[_user][vests[_user].length - 1];
      vests[_user].pop();
    }

    emit Withdraw(
      _user,
      _index,
      _tokensPerWithdrawPeriod * _withdrawsToComplete
    );
  }

  function getWithdrawsAllowed(address _user, uint256 _index)
    public
    view
    returns (uint256)
  {
    TokenVest memory _vest = vests[_user][_index];
    uint256 _secondsPerWithdrawPeriod = (_vest.end - _vest.start) /
      _vest.totalWithdraws;
    return (block.timestamp - _vest.start) / _secondsPerWithdrawPeriod;
  }

  function getUserVests(address _user)
    external
    view
    returns (TokenVest[] memory)
  {
    return vests[_user];
  }

  function getYDF() external view returns (address) {
    return address(_ydf);
  }

  function addStakingContract(address _contract) external onlyOwner {
    stakeContracts.push(_contract);
  }
}
// File: YLD/YDFStake.sol

/******************************************************************************************************
YDFStake Inheritable Contract for staking NFTs

Website: https://yieldfactory.club
Twitter: https://twitter.com/yieldfactory
Telegram: https://t.me/yieldfactory
******************************************************************************************************/

pragma solidity ^0.8.9;









contract YDFStake is ERC721Enumerable, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  uint256 private constant ONE_YEAR = 365 days;
  uint256 private constant ONE_WEEK = 7 days;
  uint16 private constant PERCENT_DENOMENATOR = 10000;

  IERC20 internal stakeToken;
  IYDF internal ydf;
  IYDFVester internal vester;
  IStakeRewards internal rewards;

  struct AprLock {
    uint16 apr;
    uint256 lockTime;
  }
  AprLock[] internal _aprLockOptions;

  struct Stake {
    uint256 created;
    uint256 amountStaked;
    uint256 amountYDFBaseEarn;
    uint16 apr;
    uint256 lockTime;
  }
  // tokenId => Stake
  mapping(uint256 => Stake) public stakes;
  // tokenId => amount
  mapping(uint256 => uint256) public yieldClaimed;
  // tokenId => timestamp
  mapping(uint256 => uint256) public lastClaim;
  // tokenId => boolean
  mapping(uint256 => bool) public isBlacklisted;

  Counters.Counter internal _ids;
  string private baseTokenURI; // baseTokenURI can point to IPFS folder like https://ipfs.io/ipfs/{cid}/ while
  address public paymentAddress;
  address public royaltyAddress;

  // Royalties basis points (percentage using 2 decimals - 1000 = 100, 500 = 50, 0 = 0)
  uint256 private royaltyBasisPoints = 50; // 5%

  // array of all the NFT token IDs owned by a user
  mapping(address => uint256[]) public allUserOwned;
  // the index in the token ID array at allUserOwned to save gas on operations
  mapping(uint256 => uint256) public ownedIndex;

  mapping(uint256 => uint256) public tokenMintedAt;
  mapping(uint256 => uint256) public tokenLastTransferred;

  event StakeTokens(
    address indexed user,
    uint256 indexed tokenId,
    uint256 amountStaked,
    uint256 lockOptionIndex
  );
  event UnstakeTokens(address indexed user, uint256 indexed tokenId);
  event SetAnnualApr(uint256 indexed newApr);
  event SetPaymentAddress(address indexed user);
  event SetRoyaltyAddress(address indexed user);
  event SetRoyaltyBasisPoints(uint256 indexed _royaltyBasisPoints);
  event SetBaseTokenURI(string indexed newUri);
  event AddAprLockOption(uint16 indexed apr, uint256 lockTime);
  event RemoveAprLockOption(
    uint256 indexed index,
    uint16 indexed apr,
    uint256 lockTime
  );
  event UpdateAprLockOption(
    uint256 indexed index,
    uint16 indexed oldApr,
    uint256 oldLockTime,
    uint16 newApr,
    uint256 newLockTime
  );
  event SetTokenBlacklist(uint256 indexed tokenId, bool isBlacklisted);

  constructor(
    string memory _name,
    string memory _symbol,
    address _stakeToken,
    address _ydf,
    address _vester,
    address _rewards,
    string memory _baseTokenURI
  ) ERC721(_name, _symbol) {
    stakeToken = IERC20(_stakeToken);
    ydf = IYDF(_ydf);
    vester = IYDFVester(_vester);
    rewards = IStakeRewards(_rewards);
    baseTokenURI = _baseTokenURI;
  }

  function stake(uint256 _amount, uint256 _lockOptIndex) external virtual {
    _stake(msg.sender, _amount, _amount, _lockOptIndex, true);
  }

  function _stake(
    address _user,
    uint256 _amountStaked,
    uint256 _amountYDFBaseEarn,
    uint256 _lockOptIndex,
    bool _transferStakeToken
  ) internal {
    require(_lockOptIndex < _aprLockOptions.length, 'invalid lock option');
    _amountStaked = _amountStaked == 0
      ? stakeToken.balanceOf(_user)
      : _amountStaked;
    _amountYDFBaseEarn = _amountYDFBaseEarn == 0
      ? _amountStaked
      : _amountYDFBaseEarn;
    require(
      _amountStaked > 0 && _amountYDFBaseEarn > 0,
      'must stake and be earning at least some tokens'
    );
    if (_transferStakeToken) {
      stakeToken.transferFrom(_user, address(this), _amountStaked);
    }

    _ids.increment();
    stakes[_ids.current()] = Stake({
      created: block.timestamp,
      amountStaked: _amountStaked,
      amountYDFBaseEarn: _amountYDFBaseEarn,
      apr: _aprLockOptions[_lockOptIndex].apr,
      lockTime: _aprLockOptions[_lockOptIndex].lockTime
    });
    _safeMint(_user, _ids.current());
    tokenMintedAt[_ids.current()] = block.timestamp;

    emit StakeTokens(_user, _ids.current(), _amountStaked, _lockOptIndex);
  }

  function unstake(uint256 _tokenId) public {
    address _user = msg.sender;
    Stake memory _tokenStake = stakes[_tokenId];
    require(
      _user == ownerOf(_tokenId),
      'only the owner of the staked tokens can unstake'
    );
    bool _isUnstakingEarly = block.timestamp <
      _tokenStake.created + _tokenStake.lockTime;

    // send back original tokens staked
    // if unstaking early based on lock period, only get a portion back
    if (_isUnstakingEarly) {
      uint256 _timeStaked = block.timestamp - _tokenStake.created;
      uint256 _earnedAmount = (_tokenStake.amountStaked * _timeStaked) /
        _tokenStake.lockTime;
      stakeToken.transfer(_user, _earnedAmount);
      if (address(stakeToken) == address(ydf)) {
        ydf.burn(_tokenStake.amountStaked - _earnedAmount);
      } else {
        stakeToken.transfer(owner(), _tokenStake.amountStaked - _earnedAmount);
      }
    } else {
      stakeToken.transfer(_user, _tokenStake.amountStaked);
    }

    // check and create new vest if yield available to be claimed
    uint256 _totalEarnedAmount = getTotalEarnedAmount(_tokenId);
    if (_totalEarnedAmount > yieldClaimed[_tokenId]) {
      _createVestAndMint(_user, _totalEarnedAmount - yieldClaimed[_tokenId]);
    }

    // this NFT is useless after the user unstakes
    _burn(_tokenId);

    emit UnstakeTokens(_user, _tokenId);
  }

  function unstakeMulti(uint256[] memory _tokenIds) external {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      unstake(_tokenIds[i]);
    }
  }

  function claimAndVestRewards(uint256 _tokenId) public {
    require(!isBlacklisted[_tokenId], 'blacklisted NFT');

    // user can only claim and vest rewards up to once a week
    require(block.timestamp > lastClaim[_tokenId] + ONE_WEEK);
    lastClaim[_tokenId] = block.timestamp;

    uint256 _totalEarnedAmount = getTotalEarnedAmount(_tokenId);
    require(
      _totalEarnedAmount > yieldClaimed[_tokenId],
      'must have some yield to claim'
    );
    _createVestAndMint(
      ownerOf(_tokenId),
      _totalEarnedAmount - yieldClaimed[_tokenId]
    );
    yieldClaimed[_tokenId] = _totalEarnedAmount;
  }

  function claimAndVestRewardsMulti(uint256[] memory _tokenIds) external {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      claimAndVestRewards(_tokenIds[i]);
    }
  }

  function _createVestAndMint(address _user, uint256 _amount) internal {
    // store metadata for earned tokens in vesting contract for user who is unstaking
    vester.createVest(_user, _amount);
    // mint earned tokens to vesting contract
    ydf.stakeMintToVester(_amount);
  }

  // Support royalty info - See {EIP-2981}: https://eips.ethereum.org/EIPS/eip-2981
  function royaltyInfo(uint256, uint256 _salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    return (royaltyAddress, (_salePrice * royaltyBasisPoints) / 1000);
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(_tokenId), 'token does not exist');
    return string(abi.encodePacked(_baseURI(), _tokenId.toString(), '.json'));
  }

  // Contract metadata URI - Support for OpenSea: https://docs.opensea.io/docs/contract-level-metadata
  function contractURI() public view returns (string memory) {
    return string(abi.encodePacked(_baseURI(), 'contract.json'));
  }

  // Override supportsInterface - See {IERC165-supportsInterface}
  function supportsInterface(bytes4 _interfaceId)
    public
    view
    virtual
    override(ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(_interfaceId);
  }

  function getLastMintedTokenId() external view returns (uint256) {
    return _ids.current();
  }

  function isTokenMinted(uint256 _tokenId) external view returns (bool) {
    return _exists(_tokenId);
  }

  function setPaymentAddress(address _address) external onlyOwner {
    paymentAddress = _address;
    emit SetPaymentAddress(_address);
  }

  function setRoyaltyAddress(address _address) external onlyOwner {
    royaltyAddress = _address;
    emit SetRoyaltyAddress(_address);
  }

  function setRoyaltyBasisPoints(uint256 _points) external onlyOwner {
    royaltyBasisPoints = _points;
    emit SetRoyaltyBasisPoints(_points);
  }

  function setBaseURI(string memory _uri) external onlyOwner {
    baseTokenURI = _uri;
    emit SetBaseTokenURI(_uri);
  }

  function getAllUserOwned(address _user)
    external
    view
    returns (uint256[] memory)
  {
    return allUserOwned[_user];
  }

  function getTotalEarnedAmount(uint256 _tokenId)
    public
    view
    returns (uint256)
  {
    Stake memory _tokenStake = stakes[_tokenId];
    uint256 _secondsStaked = block.timestamp - _tokenStake.created;
    return
      (_tokenStake.amountYDFBaseEarn * _tokenStake.apr * _secondsStaked) /
      PERCENT_DENOMENATOR /
      ONE_YEAR;
  }

  function getAllLockOptions() external view returns (AprLock[] memory) {
    return _aprLockOptions;
  }

  function addAprLockOption(uint16 _apr, uint256 _lockTime) external onlyOwner {
    _addAprLockOption(_apr, _lockTime);
    emit AddAprLockOption(_apr, _lockTime);
  }

  function _addAprLockOption(uint16 _apr, uint256 _lockTime) internal {
    _aprLockOptions.push(AprLock({ apr: _apr, lockTime: _lockTime }));
  }

  function removeAprLockOption(uint256 _index) external onlyOwner {
    AprLock memory _option = _aprLockOptions[_index];
    _aprLockOptions[_index] = _aprLockOptions[_aprLockOptions.length - 1];
    _aprLockOptions.pop();
    emit RemoveAprLockOption(_index, _option.apr, _option.lockTime);
  }

  function updateAprLockOption(
    uint256 _index,
    uint16 _apr,
    uint256 _lockTime
  ) external onlyOwner {
    AprLock memory _option = _aprLockOptions[_index];
    _aprLockOptions[_index] = AprLock({ apr: _apr, lockTime: _lockTime });
    emit UpdateAprLockOption(
      _index,
      _option.apr,
      _option.lockTime,
      _apr,
      _lockTime
    );
  }

  function setIsBlacklisted(uint256 _tokenId, bool _isBlacklisted)
    external
    onlyOwner
  {
    isBlacklisted[_tokenId] = _isBlacklisted;
    emit SetTokenBlacklist(_tokenId, _isBlacklisted);
  }

  function _baseURI() internal view override returns (string memory) {
    return baseTokenURI;
  }

  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) internal virtual override(ERC721Enumerable) {
    require(!isBlacklisted[_tokenId], 'blacklisted NFT');
    tokenLastTransferred[_tokenId] = block.timestamp;

    super._beforeTokenTransfer(_from, _to, _tokenId);
  }

  function _afterTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) internal virtual override(ERC721) {
    Stake memory _tokenStake = stakes[_tokenId];

    // if from == address(0), token is being minted
    if (_from != address(0)) {
      uint256 _currIndex = ownedIndex[_tokenId];
      uint256 _tokenIdMovingIndices = allUserOwned[_from][
        allUserOwned[_from].length - 1
      ];
      allUserOwned[_from][_currIndex] = allUserOwned[_from][
        allUserOwned[_from].length - 1
      ];
      allUserOwned[_from].pop();
      ownedIndex[_tokenIdMovingIndices] = _currIndex;
      rewards.setShare(_from, _tokenStake.amountYDFBaseEarn, true);
    }

    // if to == address(0), token is being burned
    if (_to != address(0)) {
      ownedIndex[_tokenId] = allUserOwned[_to].length;
      allUserOwned[_to].push(_tokenId);
      rewards.setShare(_to, _tokenStake.amountYDFBaseEarn, false);
    }

    super._afterTokenTransfer(_from, _to, _tokenId);
  }
}
// File: YLD/slYDF.sol

/******************************************************************************************************
Staked YIELDFACTORY Liquidity (slYDF)

Website: https://yieldfactory.club
Twitter: https://twitter.com/yieldfactory
Telegram: https://t.me/yieldfactory
******************************************************************************************************/

pragma solidity ^0.8.9;




contract slYDF is YDFStake {
  address private _uniswapRouter;
  uint8 public zapBuySlippage = 2; // 2%
  uint8 public zapSellSlippage = 25; // 25%

  event StakeLiquidity(address indexed user, uint256 amountUniLPStaked);
  event ZapETHOnly(
    address indexed user,
    uint256 amountETH,
    uint256 amountUniLPStaked
  );
  event ZapYDFOnly(
    address indexed user,
    uint256 amountYDF,
    uint256 amountUniLPStaked
  );
  event ZapETHAndYDF(
    address indexed user,
    uint256 amountETH,
    uint256 amountYDF,
    uint256 amountUniLPStaked
  );

  constructor(
    address _pair,
    address _router,
    address _ydf,
    address _vester,
    address _rewards,
    string memory _baseTokenURI
  )
    YDFStake(
      'Staked YIELDFACTORY Liquidity',
      'slYDF',
      _pair,
      _ydf,
      _vester,
      _rewards,
      _baseTokenURI
    )
  {
    _uniswapRouter = _router;
    _addAprLockOption(5000, 0);
    _addAprLockOption(7500, 14 days);
    _addAprLockOption(15000, 120 days);
    _addAprLockOption(22500, 240 days);
    _addAprLockOption(30000, 360 days);
  }

  function stake(uint256 _amount, uint256 _lockOptIndex) external override {
    _stakeLp(msg.sender, _amount, _lockOptIndex, true);
    emit StakeLiquidity(msg.sender, _amount);
  }

  function zapAndStakeETHOnly(uint256 _lockOptIndex) external payable {
    require(msg.value > 0, 'need to provide ETH to zap');

    uint256 _ethBalBefore = address(this).balance - msg.value;
    uint256 _ydfBalanceBefore = ydf.balanceOf(address(this));
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_uniswapRouter);

    // swap half the ETH for YDF
    uint256 _tokensToReceiveNoSlip = _getTokensToReceiveOnBuyNoSlippage(
      msg.value / 2
    );
    address[] memory path = new address[](2);
    path[0] = _uniswapV2Router.WETH();
    path[1] = address(ydf);
    _uniswapV2Router.swapExactETHForTokens{ value: msg.value / 2 }(
      (_tokensToReceiveNoSlip * (100 - zapBuySlippage)) / 100, // handle slippage
      path,
      address(this),
      block.timestamp
    );

    uint256 _lpBalBefore = stakeToken.balanceOf(address(this));
    _addLp(ydf.balanceOf(address(this)) - _ydfBalanceBefore, msg.value / 2);
    uint256 _lpBalanceToStake = stakeToken.balanceOf(address(this)) -
      _lpBalBefore;
    _stakeLp(msg.sender, _lpBalanceToStake, _lockOptIndex, false);

    _returnExcessETH(msg.sender, _ethBalBefore);
    _returnExcessYDF(msg.sender, _ydfBalanceBefore);

    emit ZapETHOnly(msg.sender, msg.value, _lpBalanceToStake);
  }

  function zapAndStakeETHAndYDF(uint256 _amountYDF, uint256 _lockOptIndex)
    external
    payable
  {
    require(msg.value > 0, 'need to provide ETH to zap');

    uint256 _ethBalBefore = address(this).balance - msg.value;
    uint256 _ydfBalBefore = ydf.balanceOf(address(this));
    ydf.transferFrom(msg.sender, address(this), _amountYDF);
    uint256 _ydfToProcess = ydf.balanceOf(address(this)) - _ydfBalBefore;

    uint256 _lpBalBefore = stakeToken.balanceOf(address(this));
    _addLp(_ydfToProcess, msg.value);
    uint256 _lpBalanceToStake = stakeToken.balanceOf(address(this)) -
      _lpBalBefore;
    _stakeLp(msg.sender, _lpBalanceToStake, _lockOptIndex, false);

    _returnExcessETH(msg.sender, _ethBalBefore);
    _returnExcessYDF(msg.sender, _ydfBalBefore);

    emit ZapETHAndYDF(msg.sender, msg.value, _amountYDF, _lpBalanceToStake);
  }

  function zapAndStakeYDFOnly(uint256 _amountYDF, uint256 _lockOptIndex)
    external
  {
    require(
      _aprLockOptions[_lockOptIndex].lockTime > 0,
      'cannot zap and stake YDF only without lockup period'
    );
    uint256 _ethBalBefore = address(this).balance;
    uint256 _ydfBalBefore = ydf.balanceOf(address(this));
    ydf.transferFrom(msg.sender, address(this), _amountYDF);
    uint256 _ydfToProcess = ydf.balanceOf(address(this)) - _ydfBalBefore;

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_uniswapRouter);

    // swap half the YDF for ETH
    uint256 _ethToReceiveNoSlip = _getETHToReceiveOnSellNoSlippage(
      _ydfToProcess / 2
    );
    address[] memory path = new address[](2);
    path[0] = address(ydf);
    path[1] = _uniswapV2Router.WETH();
    ydf.approve(address(_uniswapV2Router), _ydfToProcess / 2);
    _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      _ydfToProcess / 2,
      (_ethToReceiveNoSlip * (100 - zapSellSlippage)) / 100, // handle slippage
      path,
      address(this),
      block.timestamp
    );

    uint256 _lpBalBefore = stakeToken.balanceOf(address(this));
    _addLp(_ydfToProcess / 2, address(this).balance - _ethBalBefore);
    uint256 _lpBalanceToStake = stakeToken.balanceOf(address(this)) -
      _lpBalBefore;
    _stakeLp(msg.sender, _lpBalanceToStake, _lockOptIndex, false);

    _returnExcessETH(msg.sender, _ethBalBefore);
    _returnExcessYDF(msg.sender, _ydfBalBefore);

    emit ZapYDFOnly(msg.sender, _amountYDF, _lpBalanceToStake);
  }

  function _addLp(uint256 tokenAmount, uint256 ethAmount) private {
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_uniswapRouter);
    ydf.approve(address(_uniswapV2Router), tokenAmount);
    _uniswapV2Router.addLiquidityETH{ value: ethAmount }(
      address(ydf),
      tokenAmount,
      0,
      0,
      address(this),
      block.timestamp
    );
  }

  function _getTokensToReceiveOnBuyNoSlippage(uint256 _amountETH)
    internal
    view
    returns (uint256)
  {
    IUniswapV2Pair pair = IUniswapV2Pair(address(stakeToken));
    (uint112 _r0, uint112 _r1, ) = pair.getReserves();
    if (pair.token0() == IUniswapV2Router02(_uniswapRouter).WETH()) {
      return (_amountETH * _r1) / _r0;
    } else {
      return (_amountETH * _r0) / _r1;
    }
  }

  function _getETHToReceiveOnSellNoSlippage(uint256 _amountYDF)
    internal
    view
    returns (uint256)
  {
    IUniswapV2Pair pair = IUniswapV2Pair(address(stakeToken));
    (uint112 _r0, uint112 _r1, ) = pair.getReserves();
    if (pair.token0() == IUniswapV2Router02(_uniswapRouter).WETH()) {
      return (_amountYDF * _r0) / _r1;
    } else {
      return (_amountYDF * _r1) / _r0;
    }
  }

  function _stakeLp(
    address _user,
    uint256 _amountStakeToken,
    uint256 _lockOptIndex,
    bool _transferStakeToken
  ) internal {
    IUniswapV2Pair pair = IUniswapV2Pair(address(stakeToken));
    _amountStakeToken = _amountStakeToken == 0
      ? pair.balanceOf(_user)
      : _amountStakeToken;
    (uint112 res0, uint112 res1, ) = pair.getReserves();
    address t0 = pair.token0();
    uint256 ydfReserves = t0 == address(ydf) ? res0 : res1;
    uint256 singleSideTokenAmount = (_amountStakeToken * ydfReserves) /
      stakeToken.totalSupply();

    // need to multiply the earned amount by 2 since when providing LP
    // the user provides both sides of the pair, so we account for both
    // sides of the pair by multiplying by 2
    _stake(
      _user,
      _amountStakeToken,
      singleSideTokenAmount * 2,
      _lockOptIndex,
      _transferStakeToken
    );
  }

  function _returnExcessETH(address _user, uint256 _initialBal) internal {
    if (address(this).balance > _initialBal) {
      payable(_user).call{ value: address(this).balance - _initialBal }('');
      require(address(this).balance >= _initialBal, 'took too much');
    }
  }

  function _returnExcessYDF(address _user, uint256 _initialBal) internal {
    uint256 _currentBal = ydf.balanceOf(address(this));
    if (_currentBal > _initialBal) {
      ydf.transfer(_user, _currentBal - _initialBal);
      require(ydf.balanceOf(address(this)) >= _initialBal, 'took too much');
    }
  }

  function setZapBuySlippage(uint8 _slippage) external onlyOwner {
    require(_slippage <= 100, 'cannot be more than 100% slippage');
    zapBuySlippage = _slippage;
  }

  function setZapSellSlippage(uint8 _slippage) external onlyOwner {
    require(_slippage <= 100, 'cannot be more than 100% slippage');
    zapSellSlippage = _slippage;
  }

  receive() external payable {}
}
// File: YLD/sYDF.sol

/******************************************************************************************************
Staked YIELDFACTORY (sYDF)

Website: https://yieldfactory.club
Twitter: https://twitter.com/yieldfactory
Telegram: https://t.me/yieldfactory
******************************************************************************************************/

pragma solidity ^0.8.9;


contract sYDF is YDFStake {
  constructor(
    address _ydf,
    address _vester,
    address _rewards,
    string memory _baseTokenURI
  )
    YDFStake(
      'Staked YIELDFACTORY',
      'sYDF',
      _ydf,
      _ydf,
      _vester,
      _rewards,
      _baseTokenURI
    )
  {
    _addAprLockOption(2500, 0);
    _addAprLockOption(5000, 14 days);
    _addAprLockOption(10000, 120 days);
    _addAprLockOption(15000, 240 days);
    _addAprLockOption(20000, 360 days);
  }
}
// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: YLD/YDF.sol

/******************************************************************************************************
YIELDFACTORY (YDF)

Website: https://yieldfactory.club
Twitter: https://twitter.com/yieldfactory
Telegram: https://t.me/yieldfactory
******************************************************************************************************/

pragma solidity ^0.8.9;










contract YDF is IYDF, ERC20, Ownable {
  uint256 private constant EARLY_SELL_EXPIRATION = 90 days;
  uint256 private constant SET_AND_LOCK_TAXES = 30 days;
  uint256 private constant LAUNCH_MAX_TXN_PERIOD = 30 minutes;

  // at launch, a higher marketing+rewards tax will support initial capital generated
  // for hiring and paying for an initial marketing blitz. After 30 days the contract
  // reduces the marketing percent to 1%, which it can no longer be adjusted.
  uint256 public taxMarketingPerc = 600; // 6%
  uint256 public taxRewardsPerc = 300; // 3%
  uint256 public taxEarlyPerc = 600; // 6%

  sYDF private _stakedYDF;
  slYDF private _stakedYDFLP;
  YDFVester private _vester;
  StakeRewards private _rewards;

  address public treasury;
  uint256 public launchBlock;
  uint256 public launchTime;

  mapping(address => bool) public isTaxExcluded;

  IUniswapV2Router02 public uniswapV2Router;
  address public uniswapV2Pair;
  mapping(address => bool) public mmPairs; // market making pairs

  // the following are used to track logic for the time-decaying sell tax.
  // buyTracker and sellTracker will be appended to each buy/sell respectively,
  // where as lastBuyTimestamp is reset each buy. As long as the buyTracker
  // exceeds the sellTracker, the decaying sell tax will reduce continuously
  // against the lastBuyTimestamp, but at the moment the user sells and
  // the sellTracker exceeds the buyTracker, all are reset which will mean
  // the sell tax will be no longer decaying for this wallet until the wallet
  // buys again and everything starts from scratch again.
  //
  // IMPORTANT: the time-decay tax is measured against lastBuyTimestamp, meaning
  // each time a wallet buys, their time decay is reset back to the beginning.
  mapping(address => uint256) public buyTracker;
  mapping(address => uint256) public lastBuyTimestamp;
  mapping(address => uint256) public sellTracker;

  mapping(address => bool) private _isBot;

  bool private _swapping = false;
  bool private _swapEnabled = true;

  modifier onlyStake() {
    require(
      address(_stakedYDF) == _msgSender() ||
        address(_stakedYDFLP) == _msgSender(),
      'not a staking contract'
    );
    _;
  }

  modifier onlyVest() {
    require(address(_vester) == _msgSender(), 'not vesting contract');
    _;
  }

  modifier swapLock() {
    _swapping = true;
    _;
    _swapping = false;
  }

  event SetMarketMakingPair(address indexed pair, bool isPair);
  event SetTreasury(address indexed newTreasury);
  event StakeMintToVester(uint256 amount);
  event Burn(address indexed user, uint256 amount);
  event ResetBuySellMetadata(address indexed user);
  event SetTaxExclusion(address indexed user, bool isExcluded);

  constructor() ERC20('YIELDFACTORY', 'YFY') {
    _mint(msg.sender, 696_900_000 * 10**18);

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
      0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
      address(this),
      _uniswapV2Router.WETH()
    );

    _vester = new YDFVester(address(this));
    _rewards = new StakeRewards(address(this), address(_uniswapV2Router));

    _stakedYDF = new sYDF(
      address(this),
      address(_vester),
      address(_rewards),
      'https://api.yieldfactory.club/sydf/metadata/'
    );
    _stakedYDF.setPaymentAddress(msg.sender);
    _stakedYDF.setRoyaltyAddress(msg.sender);
    _stakedYDF.transferOwnership(msg.sender);

    _stakedYDFLP = new slYDF(
      uniswapV2Pair,
      address(_uniswapV2Router),
      address(this),
      address(_vester),
      address(_rewards),
      'https://api.yieldfactory.club/slydf/metadata/'
    );
    _stakedYDFLP.setPaymentAddress(msg.sender);
    _stakedYDFLP.setRoyaltyAddress(msg.sender);
    _stakedYDFLP.transferOwnership(msg.sender);

    _vester.addStakingContract(address(_stakedYDF));
    _vester.addStakingContract(address(_stakedYDFLP));
    _vester.transferOwnership(msg.sender);

    _rewards.setsYDF(address(_stakedYDF));
    _rewards.setslYDF(address(_stakedYDFLP));
    _rewards.transferOwnership(msg.sender);

    mmPairs[uniswapV2Pair] = true;
    uniswapV2Router = _uniswapV2Router;
    treasury = msg.sender;

    isTaxExcluded[address(this)] = true;
    isTaxExcluded[address(_stakedYDFLP)] = true; // allow zapping without taxes
    isTaxExcluded[msg.sender] = true;
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual override {
    bool _isBuy = mmPairs[sender] && recipient != address(uniswapV2Router);
    bool _isSell = mmPairs[recipient];

    if (_isBuy) {
      require(launchBlock > 0, 'not launched yet');

      buyTracker[recipient] += amount;
      lastBuyTimestamp[recipient] = block.timestamp;
      if (block.number <= launchBlock + 2) {
        _isBot[recipient] = true;
      } else if (block.timestamp < launchTime + LAUNCH_MAX_TXN_PERIOD) {
        require(
          balanceOf(recipient) + amount <= (totalSupply() * 1) / 100,
          'at launch max wallet is up to 1% supply'
        );
      }
    } else {
      require(!_isBot[recipient], 'sorry bot');
      require(!_isBot[sender], 'sorry bot');
      require(!_isBot[_msgSender()], 'sorry bot');
    }

    uint256 contractBalance = balanceOf(address(this));
    uint256 _swapAmount = (balanceOf(uniswapV2Pair) * 5) / 1000; // 0.5% pair balance
    bool _overMinimum = contractBalance >= _swapAmount && _swapAmount > 0;
    if (!_swapping && _swapEnabled && _overMinimum && sender != uniswapV2Pair) {
      _swapForETH(_swapAmount);
    }

    uint256 tax = 0;
    if (_isSell && !(isTaxExcluded[sender] || isTaxExcluded[recipient])) {
      // at the expiration date we will reset taxes which will
      // set them forever in the contract to no longer be changed
      if (
        block.timestamp > launchTime + SET_AND_LOCK_TAXES &&
        taxMarketingPerc > 300
      ) {
        taxMarketingPerc = 300; // 3%
        taxRewardsPerc = 200; // 2%
        taxEarlyPerc = 1000; // 10%
      }

      uint256 _taxEarlyPerc = getSellEarlyTax(sender, amount, taxEarlyPerc);
      uint256 _totalTax = taxMarketingPerc + taxRewardsPerc + _taxEarlyPerc;
      tax = (amount * _totalTax) / 10000;
      if (tax > 0) {
        uint256 _taxAmountETH = (tax * (taxMarketingPerc + taxRewardsPerc)) /
          _totalTax;
        super._transfer(sender, address(this), _taxAmountETH);
        if (_taxEarlyPerc > 0) {
          _burnWithEvent(sender, tax - _taxAmountETH);
        }
      }
      sellTracker[sender] += amount;
    }

    super._transfer(sender, recipient, amount - tax);

    // if the sell tracker equals or exceeds the amount of tokens bought,
    // reset all variables here which resets the time-decaying sell tax logic.
    if (sellTracker[sender] >= buyTracker[sender]) {
      _resetBuySellMetadata(sender);
    }
    // handles transferring to a fresh wallet or wallet that hasn't bought YDF before
    if (lastBuyTimestamp[recipient] == 0) {
      _resetBuySellMetadata(recipient);
    }
  }

  function _swapForETH(uint256 _amountToSwap) private swapLock {
    uint256 _balBefore = address(this).balance;

    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    _approve(address(this), address(uniswapV2Router), _amountToSwap);
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      _amountToSwap,
      0,
      path,
      address(this),
      block.timestamp
    );

    uint256 _balToProcess = address(this).balance - _balBefore;
    if (_balToProcess > 0) {
      uint256 _totalTaxETH = taxMarketingPerc + taxRewardsPerc;

      // send marketing ETH
      uint256 _marketingETH = (_balToProcess * taxMarketingPerc) / _totalTaxETH;
      address _treasury = treasury == address(0) ? owner() : treasury;
      if (_marketingETH > 0) {
        payable(_treasury).call{ value: _marketingETH }('');
      }

      // deposit rewards into rewards pool
      uint256 _rewardsETH = _balToProcess - _marketingETH;
      if (_rewardsETH > 0) {
        if (_rewards.totalSharesDeposited() > 0) {
          _rewards.depositRewards{ value: _rewardsETH }();
        } else {
          payable(_treasury).call{ value: _rewardsETH }('');
        }
      }
    }
  }

  function getSellEarlyTax(
    address _seller,
    uint256 _sellAmount,
    uint256 _tax
  ) public view returns (uint256) {
    if (lastBuyTimestamp[_seller] == 0) {
      return _tax;
    }

    if (sellTracker[_seller] + _sellAmount > buyTracker[_seller]) {
      return _tax;
    }

    if (block.timestamp > getSellEarlyExpiration(_seller)) {
      return 0;
    }
    uint256 _secondsAfterBuy = block.timestamp - lastBuyTimestamp[_seller];
    return
      (_tax * (EARLY_SELL_EXPIRATION - _secondsAfterBuy)) /
      EARLY_SELL_EXPIRATION;
  }

  function getSellEarlyExpiration(address _seller)
    public
    view
    returns (uint256)
  {
    return
      lastBuyTimestamp[_seller] == 0
        ? 0
        : lastBuyTimestamp[_seller] + EARLY_SELL_EXPIRATION;
  }

  function getStakedYDF() external view returns (address) {
    return address(_stakedYDF);
  }

  function getStakedYDFLP() external view returns (address) {
    return address(_stakedYDFLP);
  }

  function getVester() external view returns (address) {
    return address(_vester);
  }

  function getRewards() external view returns (address) {
    return address(_rewards);
  }

  function addToBuyTracker(address _user, uint256 _amount) external onlyVest {
    buyTracker[_user] += _amount;
    // if this user hasn't bought before, but is vesting from unstaking an
    // acquired stake NFT, go ahead and set their buy timetstamp here from now
    if (lastBuyTimestamp[_user] == 0) {
      lastBuyTimestamp[_user] = block.timestamp;
    }
  }

  function resetBuySellMetadata() external {
    _resetBuySellMetadata(msg.sender);
    emit ResetBuySellMetadata(msg.sender);
  }

  function _resetBuySellMetadata(address _user) internal {
    buyTracker[_user] = balanceOf(_user);
    lastBuyTimestamp[_user] = block.timestamp;
    sellTracker[_user] = 0;
  }

  function stakeMintToVester(uint256 _amount) external override onlyStake {
    _mint(address(_vester), _amount);
    emit StakeMintToVester(_amount);
  }

  function burn(uint256 _amount) external {
    _burnWithEvent(msg.sender, _amount);
  }

  function _burnWithEvent(address _user, uint256 _amount) internal {
    _burn(_user, _amount);
    emit Burn(_user, _amount);
  }

  function setIsTaxExcluded(address _wallet, bool _isExcluded)
    external
    onlyOwner
  {
    isTaxExcluded[_wallet] = _isExcluded;
    emit SetTaxExclusion(_wallet, _isExcluded);
  }

  function setMarketMakingPair(address _addy, bool _isPair) external onlyOwner {
    require(_addy != uniswapV2Pair, 'cannot change state of built-in pair');
    mmPairs[_addy] = _isPair;
    emit SetMarketMakingPair(_addy, _isPair);
  }

  function setSwapEnabled(bool _enabled) external onlyOwner {
    _swapEnabled = _enabled;
  }

  function setTreasury(address _treasury) external onlyOwner {
    treasury = _treasury;
    emit SetTreasury(_treasury);
  }

  function startTrading() external onlyOwner {
    require(launchBlock == 0, 'already launched');
    launchBlock = block.number;
    launchTime = block.timestamp;
  }

  function withdrawETH() external onlyOwner {
    payable(owner()).call{ value: address(this).balance }('');
  }

  receive() external payable {}
}