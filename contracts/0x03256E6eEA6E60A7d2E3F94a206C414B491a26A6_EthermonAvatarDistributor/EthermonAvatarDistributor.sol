/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

// File: contracts/EthermonAvatarDistributor.sol

/**
 *Submitted for verification at polygonscan.com on 2022-01-28
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        override
        returns (bool)
    {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
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
        //unchecked {
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
        //}
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
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

interface EthermonAvatarIF {
    function mintNextToken(address _mintTo) external returns (bool);

    function mint(address _mintTo, uint256 _tokenId) external returns (bool);

    function getCurrentTokenId() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function cap() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);
}

contract EthermonAvatarDistributor is AccessControl {
    using SafeERC20 for IERC20;

    EthermonAvatarIF public eavaToken;
    IERC20 public emonToken;

    uint256 public tokenPrice = uint256(5 * 10**16); // 0.05 eth for test, 50 MATIC
    address public withdrawWallet;

    bytes32 public constant TOGGLE_MINTING_ROLE =
        keccak256("TOGGLE_MINTING_ROLE");

    address public upgradedToAddress = address(0);

    uint256 public mintingCap = 555;
    uint256 public mintingCount = 0;
    uint8 public MAX_MINT_LIMIT = 10;
    uint8 public MAX_MINT_LIMIT_WHITELIST = 10;

    mapping(address => bool) public whitelist1;
    mapping(address => bool) public whitelist2;

    bool public whitelist1Enabled = true;
    bool public whitelist2Enabled = false;
    uint256 public onWhiteList2max = 1;
    uint256 public onWhiteList2mints = 0;

    uint256 public tokenCounter = 0;

    constructor(EthermonAvatarIF _eavaToken, IERC20 _emonToken) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(TOGGLE_MINTING_ROLE, msg.sender);
        tokenCounter = 519;
        withdrawWallet = msg.sender;

        eavaToken = _eavaToken;
        emonToken = IERC20(_emonToken);
    }

    function SetTokenCounter(uint256 _tokenCounter) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Caller is not a admin"
        );
        tokenCounter = _tokenCounter;
    }

    function setContracts(EthermonAvatarIF _eavaToken, IERC20 _emonToken)
        external
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Caller is not a admin"
        );
        eavaToken = _eavaToken;
        emonToken = IERC20(_emonToken);
    }

    function upgrade(address _upgradedToAddress) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Caller is not a admin"
        );

        upgradedToAddress = _upgradedToAddress;
    }

    // mint
    bool public _mintingPaused = true;
    bool public onlyMintingByTokenHoldersAllowed = false;
    uint256 public minTokenBalanceRequired = 0; //Would 1000 EMON to mint

    function getBalanceEAVA(address _owner) public view returns (uint256) {
        return eavaToken.balanceOf(_owner);
    }

    function mint2(uint256 _num) public payable returns (bool) {
        require(
            address(0) == upgradedToAddress,
            "Contract has been upgraded to a new address"
        );
        require(
            msg.value >= (tokenPrice * _num),
            "Insufficient amount provided"
        );
        require(!_mintingPaused, "Minting paused");
        // require(whiteList[msg.sender] || !whitelistOnly, "ONLY WHITELIST"); //either on whitelist or whitelist is false

        require((mintingCount + _num) <= mintingCap, "Minting cap reached");
        mintingCount = mintingCount + _num;

        uint256 emonBalance = emonToken.balanceOf(msg.sender);
        uint256 eavaBalance = eavaToken.balanceOf(msg.sender);

        require(
            (whitelist1Enabled &&
                whitelist1[msg.sender] &&
                (eavaBalance + _num <= MAX_MINT_LIMIT_WHITELIST)) ||
                (
                    (whitelist2Enabled &&
                        whitelist2[msg.sender] &&
                        (emonBalance >= minTokenBalanceRequired))
                ) ||
                (!whitelist1Enabled && !whitelist2Enabled),
            "ONLY WHITELIST"
        );

        // if on whitelist 2 and cap not reached
        require(
            (!whitelist2Enabled) ||
                (((whitelist1Enabled && whitelist1[msg.sender])) ||
                    (whitelist2Enabled &&
                        (eavaBalance + _num <= MAX_MINT_LIMIT_WHITELIST) &&
                        (whitelist2[msg.sender] &&
                            (emonBalance >= minTokenBalanceRequired)) &&
                        (onWhiteList2max > onWhiteList2mints + _num))),
            "WHITELIST 2 cap reached"
        );

        if (
            !whitelist2Enabled ||
            (((whitelist1Enabled && whitelist1[msg.sender])) ||
                (whitelist2Enabled &&
                    (whitelist2[msg.sender] &&
                        (emonBalance >= minTokenBalanceRequired)) &&
                    (onWhiteList2max > onWhiteList2mints + _num)))
        ) {
            onWhiteList2mints = onWhiteList2mints + _num;
        }

        uint256 tokenId = tokenCounter - 1;
        // MAX_MINT_LIMIT (A person can mint 10 in one go only).
        require(
            _num <= MAX_MINT_LIMIT && tokenId + _num <= mintingCap,
            "Either Maximum cap of 5555 mints reached OR Miniting capacity exceeds 10"
        );

        for (uint256 i; i < _num; i++) {
            eavaToken.mint(msg.sender, tokenCounter); //, tokenId + i + 1
            tokenCounter += 1;
        }
        return true;
    }

    function mint(uint256 _num) public payable returns (bool) {
        require(
            address(0) == upgradedToAddress,
            "Contract has been upgraded to a new address"
        );
        require(
            msg.value >= (tokenPrice * _num),
            "Insufficient amount provided"
        );
        require(!_mintingPaused, "Minting paused");
        // require(whiteList[msg.sender] || !whitelistOnly, "ONLY WHITELIST"); //either on whitelist or whitelist is false

        require((mintingCount + _num) <= mintingCap, "Minting cap reached");
        mintingCount = mintingCount + _num;

        uint256 emonBalance = emonToken.balanceOf(msg.sender);
        uint256 eavaBalance = eavaToken.balanceOf(msg.sender);

        require(
            (whitelist1Enabled &&
                whitelist1[msg.sender] &&
                (eavaBalance + _num <= MAX_MINT_LIMIT_WHITELIST)) ||
                (
                    (whitelist2Enabled &&
                        whitelist2[msg.sender] &&
                        (emonBalance >= minTokenBalanceRequired))
                ) ||
                (!whitelist1Enabled && !whitelist2Enabled),
            "ONLY WHITELIST"
        );

        // if on whitelist 2 and cap not reached
        require(
            (!whitelist2Enabled) ||
                (((whitelist1Enabled && whitelist1[msg.sender])) ||
                    (whitelist2Enabled &&
                        (eavaBalance + _num <= MAX_MINT_LIMIT_WHITELIST) &&
                        (whitelist2[msg.sender] &&
                            (emonBalance >= minTokenBalanceRequired)) &&
                        (onWhiteList2max > onWhiteList2mints + _num))),
            "WHITELIST 2 cap reached"
        );

        if (
            !whitelist2Enabled ||
            (((whitelist1Enabled && whitelist1[msg.sender])) ||
                (whitelist2Enabled &&
                    (whitelist2[msg.sender] &&
                        (emonBalance >= minTokenBalanceRequired)) &&
                    (onWhiteList2max > onWhiteList2mints + _num)))
        ) {
            onWhiteList2mints = onWhiteList2mints + _num;
        }

        uint256 tokenId = eavaToken.getCurrentTokenId();
        // MAX_MINT_LIMIT (A person can mint 10 in one go only).
        require(
            _num <= MAX_MINT_LIMIT && tokenId + _num <= mintingCap,
            "Either Maximum cap of 5555 mints reached OR Miniting capacity exceeds 10"
        );

        for (uint256 i; i < _num; i++) {
            eavaToken.mintNextToken(msg.sender); //, tokenId + i + 1
        }
        return true;
    }

    // mintUsingEMON

    bool public _mintingUsingEMONPaused = true;
    uint256 public tokenPriceEMON = uint256(2000 * 10**18); // = 2000 EMON paid to mint

    function setLimitConfig(uint8 _limit, uint8 _limitWhitelist) external {
        require(
            _limit >= 0 &&
                _limitWhitelist >= 0 &&
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Wrong limit parameter or Caller is not an admin"
        );
        MAX_MINT_LIMIT = _limit;
        MAX_MINT_LIMIT_WHITELIST = _limitWhitelist;
    }

    function mintUsingEMON(uint256 _num) public returns (bool) {
        require(
            address(0) == upgradedToAddress,
            "Contract has been upgraded to a new address"
        );
        require(!_mintingUsingEMONPaused, "Minting using EMON paused");

        require((mintingCount + _num) <= mintingCap, "Minting cap reached");
        mintingCount = mintingCount + _num;

        uint256 emonBalance = emonToken.balanceOf(msg.sender);
        uint256 eavaBalance = eavaToken.balanceOf(msg.sender);

        require(
            (whitelist1Enabled &&
                whitelist1[msg.sender] &&
                (eavaBalance + _num <= MAX_MINT_LIMIT_WHITELIST)) ||
                (
                    (whitelist2Enabled &&
                        whitelist2[msg.sender] &&
                        (emonBalance >= minTokenBalanceRequired))
                ) ||
                (!whitelist1Enabled && !whitelist2Enabled),
            "ONLY WHITELIST"
        );

        // if on whitelist 2 and cap not reached
        require(
            (!whitelist2Enabled &&
                (eavaBalance + _num <= MAX_MINT_LIMIT_WHITELIST)) ||
                (((whitelist1Enabled && whitelist1[msg.sender])) ||
                    (whitelist2Enabled &&
                        (whitelist2[msg.sender] &&
                            (emonBalance >= minTokenBalanceRequired)) &&
                        (onWhiteList2max > onWhiteList2mints + _num))),
            "WHITELIST 2 cap reached"
        );

        if (
            !whitelist2Enabled ||
            (((whitelist1Enabled && whitelist1[msg.sender])) ||
                (whitelist2Enabled &&
                    (whitelist2[msg.sender] &&
                        (emonBalance >= minTokenBalanceRequired)) &&
                    (onWhiteList2max > onWhiteList2mints + _num)))
        ) {
            onWhiteList2mints = onWhiteList2mints + _num;
        }

        uint256 tokenId = eavaToken.getCurrentTokenId();
        // MAX_MINT_LIMIT (A person can mint 10 in one go only).
        require(
            _num <= MAX_MINT_LIMIT && tokenId + _num < mintingCap,
            "Either Maximum cap of 5555 mints reached OR Miniting capacity exceeds 10"
        );

        emonToken.safeTransferFrom(
            msg.sender,
            address(this),
            (tokenPriceEMON * _num)
        );

        for (uint256 i; i < _num; i++) {
            eavaToken.mintNextToken(msg.sender);
        }

        return true;
    }

    fallback() external payable {}

    receive() external payable {}

    // admin functions
    function withdrawAll() public {
        uint256 _each = address(this).balance;
        require(payable(withdrawWallet).send(_each));
    }

    function updateWithdrawWallet(address _newWallet) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");

        withdrawWallet = _newWallet;
    }

    function togglePause(bool _pause) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");
        require(_mintingPaused != _pause, "Already in desired pause state");

        _mintingPaused = _pause;
    }

    function togglePauseEMON(bool _pause) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");
        require(
            _mintingUsingEMONPaused != _pause,
            "Already in desired pause state"
        );

        _mintingUsingEMONPaused = _pause;
    }

    function toggleOnlyMintingByTokenHolders(bool _isRestricted) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                hasRole(TOGGLE_MINTING_ROLE, msg.sender),
            "Caller is not toggler or admin"
        );

        onlyMintingByTokenHoldersAllowed = _isRestricted;
    }

    function updateMinTokenBalanceRequired(uint256 _required) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");

        minTokenBalanceRequired = _required;
    }

    function updatePrice(uint256 _newPrice) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");

        tokenPrice = _newPrice;
    }

    function updatePriceEMON(uint256 _newPrice) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");

        tokenPriceEMON = _newPrice;
    }

    function adminWithdrawERC20(address token) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");

        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, amount);
    }

    function adminWithdrawERC721(address token, uint256 _tokenId) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");

        IERC721(token).transferFrom(address(this), msg.sender, _tokenId);
    }

    // whitelist 1
    uint256 onWhitelist1Count = 0;

    function addToWhiteList1(address[] calldata entries) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");

        for (uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "Cannot add zero address");
            require(!whitelist1[entry], "Cannot add duplicate address");

            whitelist1[entry] = true;
            onWhitelist1Count++;
        }
    }

    function removeFromWhiteList1(address[] calldata entries) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");

        for (uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "Cannot remove zero address");

            whitelist1[entry] = false;
            onWhitelist1Count--;
        }
    }

    function toggleWhiteList1(bool _whitelist1Enabled) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");

        whitelist1Enabled = _whitelist1Enabled;
    }

    function isOnWhiteList1(address addr) external view returns (bool) {
        return whitelist1[addr];
    }

    function totalOnWhitelist1() external view returns (uint256) {
        return onWhitelist1Count;
    }

    // whitelist 2
    uint256 onWhitelist2Count = 0;

    function addToWhiteList2() external {
        require(
            !whitelist2[msg.sender],
            "Cannot add duplicate address to whitelist 2"
        );

        // User need to hold EMON to add themselves to whiteList2
        uint256 emonBalance = emonToken.balanceOf(msg.sender);
        require(
            emonBalance >= minTokenBalanceRequired,
            "Insufficient EMON balance to add to whiteList 2"
        );

        whitelist2[msg.sender] = true;
        onWhitelist2Count++;
    }

    function removeFromWhiteList2(address[] calldata entries) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");

        for (uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "Cannot remove zero address");

            whitelist2[entry] = false;
            onWhitelist2Count--;
        }
    }

    function toggleWhiteList2(bool _whitelist2Enabled) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");

        whitelist2Enabled = _whitelist2Enabled;
    }

    function isOnWhiteList2(address addr) external view returns (bool) {
        return whitelist2[addr];
    }

    function totalOnWhitelist2() external view returns (uint256) {
        return onWhitelist2Count;
    }

    function setWhiteList2Cap(uint256 _onWhiteList2cap) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");

        onWhiteList2max = _onWhiteList2cap;
    }

    function setMintingCap(uint256 _mintingCap) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");

        mintingCap = _mintingCap;
    }
}