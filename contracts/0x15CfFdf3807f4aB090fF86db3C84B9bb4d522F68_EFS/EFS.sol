/**
 *Submitted for verification at Etherscan.io on 2023-05-16
*/

//SPDX-License-Identifier: MIT

// EFS.CLUB
/*
Ethereum Football Stars Club (EFS)  


                                                                                                                           
8 8888888888   8 8888888888    d888888o.                 ,o888888o.    8 8888      8 8888      88 8 888888888o             
8 8888         8 8888        .`8888:' `88.              8888     `88.  8 8888      8 8888      88 8 8888    `88.           
8 8888         8 8888        8.`8888.   Y8           ,8 8888       `8. 8 8888      8 8888      88 8 8888     `88           
8 8888         8 8888        `8.`8888.               88 8888           8 8888      8 8888      88 8 8888     ,88           
8 888888888888 8 888888888888 `8.`8888.              88 8888           8 8888      8 8888      88 8 8888.   ,88'           
8 8888         8 8888          `8.`8888.             88 8888           8 8888      8 8888      88 8 8888888888             
8 8888         8 8888           `8.`8888.            88 8888           8 8888      8 8888      88 8 8888    `88.           
8 8888         8 8888       8b   `8.`8888.           `8 8888       .8' 8 8888      ` 8888     ,8P 8 8888      88           
8 8888         8 8888       `8b.  ;8.`8888              8888     ,88'  8 8888        8888   ,d8P  8 8888    ,88'           
8 888888888888 8 8888        `Y8888P ,88P'               `8888888P'    8 888888888888 `Y88888P'   8 888888888P             


                                             ████████████              
                                          ██▓▓████████████████          
                                      ████    ██████████▓▓    ████      
                                    ██            ██              ██    
                                  ████            ██              ████  
                                  ████            ██              ████  
                                  ████████    ██▓▓████▓▓██    ████████  
                                ██████    ██████████████████▓▓    ██████
                                ████        ████████████████        ████
                                ██          ██████████████▓▓          ██
                                ██          ▓▓██████████████          ██
                                  ██          ██████████▓▓          ██  
                                  ██          ████████████          ██  
                                  ██▓▓██    ██            ██    ▓▓████  
                                    ▓▓██████                ████████    
                                    ████████                ████████    
                                      ████████            ████████      
                                          ████            ████          
                                              ████████████        
*/

// File: IOperatorFilterRegistry.sol

pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    function isOperatorAllowed(
        address registrant,
        address operator
    ) external view returns (bool);

    function register(address registrant) external;

    function registerAndSubscribe(
        address registrant,
        address subscription
    ) external;

    function registerAndCopyEntries(
        address registrant,
        address registrantToCopy
    ) external;

    function updateOperator(
        address registrant,
        address operator,
        bool filtered
    ) external;

    function updateOperators(
        address registrant,
        address[] calldata operators,
        bool filtered
    ) external;

    function updateCodeHash(
        address registrant,
        bytes32 codehash,
        bool filtered
    ) external;

    function updateCodeHashes(
        address registrant,
        bytes32[] calldata codeHashes,
        bool filtered
    ) external;

    function subscribe(
        address registrant,
        address registrantToSubscribe
    ) external;

    function unsubscribe(address registrant, bool copyExistingEntries) external;

    function subscriptionOf(address addr) external returns (address registrant);

    function subscribers(
        address registrant
    ) external returns (address[] memory);

    function subscriberAt(
        address registrant,
        uint256 index
    ) external returns (address);

    function copyEntriesOf(
        address registrant,
        address registrantToCopy
    ) external;

    function isOperatorFiltered(
        address registrant,
        address operator
    ) external returns (bool);

    function isCodeHashOfFiltered(
        address registrant,
        address operatorWithCode
    ) external returns (bool);

    function isCodeHashFiltered(
        address registrant,
        bytes32 codeHash
    ) external returns (bool);

    function filteredOperators(
        address addr
    ) external returns (address[] memory);

    function filteredCodeHashes(
        address addr
    ) external returns (bytes32[] memory);

    function filteredOperatorAt(
        address registrant,
        uint256 index
    ) external returns (address);

    function filteredCodeHashAt(
        address registrant,
        uint256 index
    ) external returns (bytes32);

    function isRegistered(address addr) external returns (bool);

    function codeHashOf(address addr) external returns (bytes32);
}

// File: OperatorFilterer.sol

pragma solidity ^0.8.13;

abstract contract OperatorFilterer {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry constant operatorFilterRegistry =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(operatorFilterRegistry).code.length > 0) {
            if (subscribe) {
                operatorFilterRegistry.registerAndSubscribe(
                    address(this),
                    subscriptionOrRegistrantToCopy
                );
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    operatorFilterRegistry.registerAndCopyEntries(
                        address(this),
                        subscriptionOrRegistrantToCopy
                    );
                } else {
                    operatorFilterRegistry.register(address(this));
                }
            }
        }
    }

    modifier onlyAllowedOperator(address from) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(operatorFilterRegistry).code.length > 0) {
            // Allow spending tokens from addresses with balance
            // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
            // from an EOA.
            if (from == msg.sender) {
                _;
                return;
            }
            if (
                !(operatorFilterRegistry.isOperatorAllowed(
                    address(this),
                    msg.sender
                ) &&
                    operatorFilterRegistry.isOperatorAllowed(
                        address(this),
                        from
                    ))
            ) {
                revert OperatorNotAllowed(msg.sender);
            }
        }
        _;
    }
}

// File: DefaultOperatorFilterer.sol

pragma solidity ^0.8.13;

abstract contract DefaultOperatorFilterer is OperatorFilterer {
    address constant DEFAULT_SUBSCRIPTION =
        address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    constructor() OperatorFilterer(DEFAULT_SUBSCRIPTION, true) {}
}

// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
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
}

// File: @openzeppelin/contracts/utils/Address.sol

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
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

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
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

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
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

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
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
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);

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

// File: contracts/erc721a.sol

// Creator: Chiru Labs

pragma solidity ^0.8.4;

error ApprovalCallerNotOwnerNorApproved();

error ApprovalQueryForNonexistentToken();

error ApproveToCaller();

error ApprovalToCurrentOwner();

error BalanceQueryForZeroAddress();

error MintToZeroAddress();

error MintZeroQuantity();

error OwnerQueryForNonexistentToken();

error TransferCallerNotOwnerNorApproved();

error TransferFromIncorrectOwner();

error TransferToNonERC721ReceiverImplementer();

error TransferToZeroAddress();

error URIQueryForNonexistentToken();

/**

 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including

 * the Metadata extension. Built to optimize for lower gas during batch mints.

 *

 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).

 *

 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.

 *

 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).

 */

contract ERC721A is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;

    using Strings for uint256;

    // Compiler will pack this into a single 256bit word.

    struct TokenOwnership {
        // The address of the owner.

        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.

        uint64 startTimestamp;
        // Whether the token has been burned.

        bool burned;
    }

    // Compiler will pack this into a single 256bit word.

    struct AddressData {
        // Realistically, 2**64-1 is more than enough.

        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.

        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.

        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address

        // (e.g. number of whitelist mint slots used).

        // If there are multiple variables, please pack them into a uint64.

        uint64 aux;
    }

    // The tokenId of the next token to be minted.

    uint256 internal _currentIndex;

    // The number of tokens burned.

    uint256 internal _burnCounter;

    // Token name

    string private _name;

    // Token symbol

    string private _symbol;

    // Mapping from token ID to ownership details

    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.

    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data

    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address

    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;

        _symbol = symbol_;

        _currentIndex = _startTokenId();
    }

    /**

     * To change the starting tokenId, please override this function.

     */

    function _startTokenId() internal view virtual returns (uint256) {
        return 1;
    }

    /**

     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.

     */

    function totalSupply() public view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented

        // more than _currentIndex - _startTokenId() times

        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**

     * Returns the total amount of tokens minted in the contract.

     */

    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,

        // and it is initialized to _startTokenId()

        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**

     * @dev See {IERC165-supportsInterface}.

     */

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**

     * @dev See {IERC721-balanceOf}.

     */

    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();

        return uint256(_addressData[owner].balance);
    }

    /**

     * Returns the number of tokens minted by `owner`.

     */

    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    /**

     * Returns the number of tokens burned by or on behalf of `owner`.

     */

    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    /**

     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).

     */

    function _getAux(address owner) internal view returns (uint64) {
        return _addressData[owner].aux;
    }

    /**

     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).

     * If there are multiple variables, please pack them into a uint64.

     */

    function _setAux(address owner, uint64 aux) internal {
        _addressData[owner].aux = aux;
    }

    /**

     * Gas spent here starts off proportional to the maximum mint batch size.

     * It gradually moves to O(1) as tokens get transferred around in the collection over time.

     */

    function _ownershipOf(
        uint256 tokenId
    ) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr && curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];

                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }

                    // Invariant:

                    // There will always be an ownership that has an address and is not burned

                    // before an ownership that does not have an address and is not burned.

                    // Hence, curr will not underflow.

                    while (true) {
                        curr--;

                        ownership = _ownerships[curr];

                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }

        revert OwnerQueryForNonexistentToken();
    }

    /**

     * @dev See {IERC721-ownerOf}.

     */

    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
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

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();

        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**

     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each

     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty

     * by default, can be overriden in child contracts.

     */

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**

     * @dev See {IERC721-approve}.

     */

    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);

        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**

     * @dev See {IERC721-getApproved}.

     */

    function getApproved(
        uint256 tokenId
    ) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**

     * @dev See {IERC721-setApprovalForAll}.

     */

    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;

        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**

     * @dev See {IERC721-isApprovedForAll}.

     */

    function isApprovedForAll(
        address owner,
        address operator
    ) public view virtual override returns (bool) {
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
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);

        if (
            to.isContract() &&
            !_checkContractOnERC721Received(from, to, tokenId, _data)
        ) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**

     * @dev Returns whether `tokenId` exists.

     *

     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.

     *

     * Tokens start existing when they are minted (`_mint`),

     */

    function _exists(uint256 tokenId) internal view returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex &&
            !_ownerships[tokenId].burned;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, "");
    }

    /**

     * @dev Safely mints `quantity` tokens and transfers them to `to`.

     *

     * Requirements:

     *

     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.

     * - `quantity` must be greater than 0.

     *

     * Emits a {Transfer} event.

     */

    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
    }

    /**

     * @dev Mints `quantity` tokens and transfers them to `to`.

     *

     * Requirements:

     *

     * - `to` cannot be the zero address.

     * - `quantity` must be greater than 0.

     *

     * Emits a {Transfer} event.

     */

    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = _currentIndex;

        if (to == address(0)) revert MintToZeroAddress();

        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.

        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1

        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1

        unchecked {
            _addressData[to].balance += uint64(quantity);

            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;

            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;

            uint256 end = updatedIndex + quantity;

            if (safe && to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);

                    if (
                        !_checkContractOnERC721Received(
                            address(0),
                            to,
                            updatedIndex++,
                            _data
                        )
                    ) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex != end);

                // Reentrancy protection

                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex != end);
            }

            _currentIndex = updatedIndex;
        }

        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**

     * @dev Transfers `tokenId` from `from` to `to`.

     *

     * Requirements:

     *

     * - `to` cannot be the zero address.

     * - `tokenId` token must be owned by `from`.

     *

     * Emits a {Transfer} event.

     */

    function _transfer(address from, address to, uint256 tokenId) private {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner

        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for

        // ownership above and the recipient's balance can't realistically overflow.

        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.

        unchecked {
            _addressData[from].balance -= 1;

            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];

            currSlot.addr = to;

            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.

            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.

            uint256 nextTokenId = tokenId + 1;

            TokenOwnership storage nextSlot = _ownerships[nextTokenId];

            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),

                // as a burned slot cannot contain the zero address.

                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;

                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);

        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**

     * @dev This is equivalent to _burn(tokenId, false)

     */

    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
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

    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.addr;

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSender() == from ||
                isApprovedForAll(from, _msgSender()) ||
                getApproved(tokenId) == _msgSender());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner

        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for

        // ownership above and the recipient's balance can't realistically overflow.

        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.

        unchecked {
            AddressData storage addressData = _addressData[from];

            addressData.balance -= 1;

            addressData.numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.

            TokenOwnership storage currSlot = _ownerships[tokenId];

            currSlot.addr = from;

            currSlot.startTimestamp = uint64(block.timestamp);

            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.

            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.

            uint256 nextTokenId = tokenId + 1;

            TokenOwnership storage nextSlot = _ownerships[nextTokenId];

            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),

                // as a burned slot cannot contain the zero address.

                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;

                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, address(0), tokenId);

        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.

        unchecked {
            _burnCounter++;
        }
    }

    /**

     * @dev Approve `to` to operate on `tokenId`

     *

     * Emits a {Approval} event.

     */

    function _approve(address to, uint256 tokenId, address owner) private {
        _tokenApprovals[tokenId] = to;

        emit Approval(owner, to, tokenId);
    }

    /**

     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.

     *

     * @param from address representing the previous owner of the given token ID

     * @param to target address that will receive the tokens

     * @param tokenId uint256 ID of the token to be transferred

     * @param _data bytes optional data to send along with the call

     * @return bool whether the call correctly returned the expected magic value

     */

    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try
            IERC721Receiver(to).onERC721Received(
                _msgSender(),
                from,
                tokenId,
                _data
            )
        returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**

     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.

     * And also called before burning one token.

     *

     * startTokenId - the first token id to be transferred

     * quantity - the amount to be transferred

     *

     * Calling conditions:

     *

     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be

     * transferred to `to`.

     * - When `from` is zero, `tokenId` will be minted for `to`.

     * - When `to` is zero, `tokenId` will be burned by `from`.

     * - `from` and `to` are never both zero.

     */

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**

     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes

     * minting.

     * And also called after one token has been burned.

     *

     * startTokenId - the first token id to be transferred

     * quantity - the amount to be transferred

     *

     * Calling conditions:

     *

     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been

     * transferred to `to`.

     * - When `from` is zero, `tokenId` has been minted for `to`.

     * - When `to` is zero, `tokenId` has been burned by `from`.

     * - `from` and `to` are never both zero.

     */

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}
// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File: contracts/contract.sol

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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


pragma solidity ^0.8.4;

contract EFS is Ownable, ERC721A, DefaultOperatorFilterer {
    using Strings for uint256;

    string private baseTokenURI;

    uint256 public publicSaleCost = 0.15 ether;

    uint64 public publicTotalSupply = 0;

// Maximum supply for each type of card
uint256 public CommonMaxSupply = 700;
uint256 public EpicMaxSupply = 250;
uint256 public GoldMaxSupply = 50;
uint256 public UniqueMaxSupply = 1;

// Ratios for each type of card (divided by 1000)
uint256 public CommonCardRatio = 1 * 10 ** 18;
uint256 public EpicCardRatio = 3 * 10 ** 18;
uint256 public GoldCardRatio = 10 * 10 ** 18;
uint256 public UniqueCardRatio = 30 * 10 ** 18;

// Ratios for each star rating of players (divided by 1000)
uint256 public OneStarRatio = 1 * 10 ** 18;
uint256 public TwoStarRatio = 1.2 * 10 ** 18;
uint256 public ThreeStarRatio = 1.3 * 10 ** 18;
uint256 public FourStarRatio = 1.5 * 10 ** 18;
  

   

    bool public publicSaleActive = true;

    mapping(uint => string) public  cardsData ;



    struct CardsStar {
        uint256 id;
        uint256 star;
    }

    mapping(uint256 => uint256) public cardStarRatio;
  
    mapping(uint256 => mapping(uint256 => uint256)) public totalSupply;

  


    constructor() ERC721A("Ethereum Football Stars Club", "EFSC") {}

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0, "Invalid mint amount!");

        _;
    }

  // Function to add star ratings for cards
function addCardsStar(CardsStar[] memory _data) public onlyOwner {
    // Iterate over the array of card star data
    for (uint i = 0; i < _data.length; i++) {
        // Assign the star rating to the corresponding card ID in the mapping
        cardStarRatio[_data[i].id] = _data[i].star;
    }
}

   // Get the price in ETH for a card
function getPriceEth(
    uint256 _cardId,
    uint256 _cardType
) public view returns (uint256) {
    uint256 _types;
    uint256 _star;

    // Determine the ratio for the given card type
    if (_cardType == 1) {
        _types = CommonCardRatio;
    } else if (_cardType == 2) {
        _types = EpicCardRatio;
    } else if (_cardType == 3) {
        _types = GoldCardRatio;
    } else if (_cardType == 4) {
        _types = UniqueCardRatio;
    } else {
        revert("Invalid card type");
    }

    // Determine the ratio for the star rating of the card
    if (cardStarRatio[_cardId] == 1) {
        _star = OneStarRatio;
    } else if (cardStarRatio[_cardId] == 2) {
        _star = TwoStarRatio;
    } else if (cardStarRatio[_cardId] == 3) {
        _star = ThreeStarRatio;
    } else if (cardStarRatio[_cardId] == 4) {
        _star = FourStarRatio;
    } else {
        revert("Invalid star rating");
    }

    // Calculate the ETH price using the ratios and the public sale cost
    uint256 ethPrice = publicSaleCost * _types * _star;
    
    // Convert the price to ETH by dividing by 10^18 twice
    return ethPrice / (10 ** 18) / (10 ** 18);
}


// Get the total price in ETH for a basket of cards
function getPriceEthBasket(
    uint64[] memory playerIds,
    uint64[] memory playerTypes,
    uint64[] memory mintAmounts
) public view returns (uint256) {
    // Check that the lengths of the input arrays are the same
    require(
        playerIds.length == playerTypes.length &&
        playerTypes.length == mintAmounts.length,
        "Invalid input arrays"
    );

    // Variable to store the total price
    uint256 totalPrice;

    // Iterate over the player IDs
    for (uint i = 0; i < playerIds.length; i++) {
        // Check that the player ID and player type are valid
        require(
            playerIds[i] >= 1 && playerTypes[i] >= 1 && playerTypes[i] <= 4,
            "Invalid player ID or type"
        );

        // Check if the maximum supply for the corresponding NFT type is reached
        if (playerTypes[i] == 1) {
            require(
                totalSupply[playerIds[i]][playerTypes[i]] +
                mintAmounts[i] <=
                CommonMaxSupply,
                "Common NFT max supply reached"
            );
        } else if (playerTypes[i] == 2) {
            require(
                totalSupply[playerIds[i]][playerTypes[i]] +
                mintAmounts[i] <=
                EpicMaxSupply,
                "Epic NFT max supply reached"
            );
        } else if (playerTypes[i] == 3) {
            require(
                totalSupply[playerIds[i]][playerTypes[i]] +
                mintAmounts[i] <=
                GoldMaxSupply,
                "Gold NFT max supply reached"
            );
        } else if (playerTypes[i] == 4) {
            require(
                totalSupply[playerIds[i]][playerTypes[i]] +
                mintAmounts[i] <=
                UniqueMaxSupply,
                "Unique NFT max supply reached"
            );
        } else {
            revert("Invalid NFT type");
        }

        // Calculate the price for the current card and add it to the total price
        totalPrice += mintAmounts[i] * getPriceEth(playerIds[i], playerTypes[i]);
    }

    // Return the total price in ETH
    return totalPrice;
}

    //Get Supply
   // Get the supply of a player's NFTs and perform a max supply validation
function getSupply(
    uint256 _playerId,
    uint256 _playerType,
    uint256 _mintAmount
) public view returns (uint256) {
    // Check the player type and perform the corresponding max supply validation
    if (_playerType == 1) {
        require(
            totalSupply[_playerId][_playerType] +
            _mintAmount <=
            CommonMaxSupply,
            "Common NFT max supply reached"
        );
    } else if (_playerType == 2) {
        require(
            totalSupply[_playerId][_playerType] +
            _mintAmount <=
            EpicMaxSupply,
            "Epic NFT max supply reached"
        );
    } else if (_playerType == 3) {
        require(
            totalSupply[_playerId][_playerType] +
            _mintAmount <=
            GoldMaxSupply,
            "Gold NFT max supply reached"
        );
    } else if (_playerType == 4) {
        require(
            totalSupply[_playerId][_playerType] +
            _mintAmount <=
            UniqueMaxSupply,
            "Unique NFT max supply reached"
        );
    } else {
        revert("Invalid NFT type");
    }

    // Return the current supply of the player's NFTs for the specified type
    return totalSupply[_playerId][_playerType];
}
   
   // Get the remaining supply for a specific player and player type
function getRemaining(uint256 _playerId, uint256 _playerType) public view returns (uint256) {
    uint256 _maxSupply;

    // Determine the maximum supply based on the player type
    if (_playerType == 1) {
        _maxSupply = CommonMaxSupply;
    } else if (_playerType == 2) {
        _maxSupply = EpicMaxSupply;
    } else if (_playerType == 3) {
        _maxSupply = GoldMaxSupply;
    } else if (_playerType == 4) {
        _maxSupply = UniqueMaxSupply;
    } else {
        revert("Invalid card type");
    }

    // Calculate the remaining supply by subtracting the current supply from the maximum supply
    return _maxSupply - totalSupply[_playerId][_playerType];
}

// Get the remaining supply for all player types for a specific player
function getRemainingId(uint256 _playerId) public view returns (string memory) {
    // Calculate the remaining supply for each player type
    uint256 _Common = CommonMaxSupply - totalSupply[_playerId][1];
    uint256 _Epic = EpicMaxSupply - totalSupply[_playerId][2];
    uint256 _Gold = GoldMaxSupply - totalSupply[_playerId][3];
    uint256 _Unique = UniqueMaxSupply - totalSupply[_playerId][4];

    // Concatenate the remaining supply values into a string and return it
    return string.concat(Strings.toString(_Common), ",", Strings.toString(_Epic), ",", Strings.toString(_Gold), ",", Strings.toString(_Unique));
}
// Function to calculate the sum of an array
function sumArray(uint64[] memory arr) private pure returns (uint) {
    uint sum;
    for (uint i = 0; i < arr.length; i++) {
        sum += arr[i];
    }
    return sum;
}

// Function to buy a basket of cards
function BuyCardsBasket(
    uint64[] memory _playerIds,
    uint64[] memory _playerTypes,
    uint64[] memory _mintAmounts
) public payable mintCompliance(sumArray(_mintAmounts)) {
    require(publicSaleActive, "Public sale is not active");
    require(
        _playerIds.length == _playerTypes.length &&
            _playerTypes.length == _mintAmounts.length,
        "Invalid input arrays"
    );

    // Calculate the total price for the card basket
    uint256 totalPrice = getPriceEthBasket(
        _playerIds,
        _playerTypes,
        _mintAmounts
    );

    // Check if the sent value is equal to the total price
    require(msg.value == totalPrice, "Insufficient funds");

    // Assign metadatas to the cards
    assignMetadatas(_playerIds, _playerTypes, _mintAmounts);

    // Mint the cards to the buyer
    _safeMint(msg.sender, sumArray(_mintAmounts));
}
   // Function to buy cards directly and mint them to a specified address
function BuyDirectly(
    uint64[] memory _playerIds,
    uint64[] memory _playerTypes,
    uint64[] memory _mintAmounts,
    address _to
) public onlyOwner mintCompliance(sumArray(_mintAmounts)) {
    require(
        _playerIds.length == _playerTypes.length &&
            _playerTypes.length == _mintAmounts.length,
        "Invalid input arrays"
    );

    // Get the total price for the card basket
    getPriceEthBasket(_playerIds, _playerTypes, _mintAmounts);

    // Assign metadatas to the cards
    assignMetadatas(_playerIds, _playerTypes, _mintAmounts);

    // Mint the cards directly to the specified address
    _safeMint(_to, sumArray(_mintAmounts));
}



function assignMetadatas(
    uint64[] memory _playerIds,
    uint64[] memory _playerTypes,
    uint64[] memory _mintAmounts
) private {
    uint256 currentTokenID = _currentIndex;
    uint256 index;
    uint256 length =  _playerIds.length;

    while (index < length) {
        uint256 lastSupply = getSupply(_playerIds[index], _playerTypes[index],_mintAmounts[index]);
        uint64 mintAmount = _mintAmounts[index];
         string memory _typeOfPlayer =  Strings.toString(_playerTypes[index]);
         string memory _idOfPlayer =  makeNumbers(Strings.toString(_playerIds[index]));
       
        for (uint i = 0; i < mintAmount; i = unsafe_inc(i)) {
            lastSupply = lastSupply + 1;
           
            cardsData[currentTokenID]=string.concat(
                _idOfPlayer,
               _typeOfPlayer,
                Strings.toString(lastSupply));
            
            currentTokenID = currentTokenID + 1;
        }
         totalSupply[_playerIds[index]][_playerTypes[index]] += _mintAmounts[index];
         publicTotalSupply += _mintAmounts[index];
        index = unsafe_inc(index);
    }
}




 function unsafe_inc(uint x) private pure returns (uint) {
        unchecked { return x + 1; }
    }
  function makeNumbers(string memory _number) private  pure  returns (string memory) { 
      
    if(bytes(_number).length==1){ 
        return string.concat("000",_number); 
    }   else if(bytes(_number).length==2){ 
        return string.concat("00",_number); 
    }   else if(bytes(_number).length==3){ 
        return string.concat("0",_number); 
    }    else{ 
        return _number; 
    } 
}
    //@return token ids owned by an address in the collection
    function walletOfOwner(
        address _owner
    ) external view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount) {
            if (exists(currentTokenId) == true) {
                address currentTokenOwner = ownerOf(currentTokenId);

                if (currentTokenOwner == _owner) {
                    ownedTokenIds[ownedTokenIndex] = currentTokenId;
                    ownedTokenIndex++;
                }
            }
            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    //@return full url for passed in token id
    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();

        return
            bytes(currentBaseURI).length > 0
                           ? string(abi.encodePacked(currentBaseURI, cardsData[_tokenId], ".json"))

                : "";
    }

    //@return amount an address has minted during all sales
    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    //@return all NFT's minted including burned tokens
    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    function burn(uint256 _tokenId) public {
        require(exists(_tokenId), "Token does not exist");
        require(msg.sender == ownerOf(_tokenId), "Not the owner of the token");
        _burn(_tokenId, false);
    }

    //@return url for the nft metadata
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata _URI) external onlyOwner {
        baseTokenURI = _URI;
    }

    function setPublicSaleCost(uint256 _publicSaleCost) public onlyOwner {
        publicSaleCost = _publicSaleCost;
    }

    //Set Ratio
    function setCommonCardRatio(uint256 _commonCardRatio) public onlyOwner {
        CommonCardRatio = _commonCardRatio;
    }

    function setEpicCardRatio(uint256 _epicCardRatio) public onlyOwner {
        EpicCardRatio = _epicCardRatio;
    }

    function setGoldCardRatio(uint256 _goldCardRatio) public onlyOwner {
        GoldCardRatio = _goldCardRatio;
    }

    function setUniqueCardRatio(uint256 _uniqueCardRatio) public onlyOwner {
        UniqueCardRatio = _uniqueCardRatio;
    }

    //End SET Type Ratio

    //Set Star Ratio
    function setOneStarRatio(uint256 _ratio) public onlyOwner {
        OneStarRatio = _ratio;
    }

    function setTwoStarRatio(uint256 _ratio) public onlyOwner {
        TwoStarRatio = _ratio;
    }

    function setThreeStarRatio(uint256 _ratio) public onlyOwner {
        ThreeStarRatio = _ratio;
    }

    function setFourStarRatio(uint256 _ratio) public onlyOwner {
        FourStarRatio = _ratio;
    }


   
  function setCardsData(uint[] memory _tokenId , string[] memory _data) public onlyOwner {
      for (uint i=0;i<_tokenId.length;i++){
        cardsData[_tokenId[i]] = _data[i];
        }
    }

    function setPublicActive(bool _state) public onlyOwner {
        publicSaleActive = _state;
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

  

    /// Fallbacks
    receive() external payable {}

    fallback() external payable {}
}