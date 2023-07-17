/**
 *Submitted for verification at Etherscan.io on 2020-05-18
*/

/*
 * Crypto stamp 2 Pre-sale
 * On-chain reservation token (ERC 1155) to be redeemed later for
 * actual digital-physical collectible postage stamps
 *
 * Developed by Capacity Blockchain Solutions GmbH <capacity.at>
 * for Österreichische Post AG <post.at>
 */

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/introspection/IERC165.sol

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

pragma solidity ^0.6.2;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.0;

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
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// File: contracts/OZ_ERC1155/IERC1155.sol

pragma solidity ^0.6.0;


/**
    @title ERC-1155 Multi Token Standard basic interface
    @dev See https://eips.ethereum.org/EIPS/eip-1155
 */
abstract contract IERC1155 is IERC165 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) public view virtual returns (uint256);

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids) public view virtual returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external virtual;

    function isApprovedForAll(address account, address operator) external view virtual returns (bool);

    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata data) external virtual;

    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external virtual;
}

// File: contracts/OZ_ERC1155/IERC1155Receiver.sol

pragma solidity ^0.6.0;


/**
    @title ERC-1155 Multi Token Receiver Interface
    @dev See https://eips.ethereum.org/EIPS/eip-1155
*/
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.6.2;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts/introspection/ERC165.sol

pragma solidity ^0.6.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// File: contracts/OZ_ERC1155/ERC1155.sol

pragma solidity ^0.6.0;






/**
 * @title Standard ERC1155 token
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 */
contract ERC1155 is ERC165, IERC1155
{
    using SafeMath for uint256;
    using Address for address;

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    // Mapping token ID to that token being registered as existing
    mapping (uint256 => bool) private _tokenExists;

    /*
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    constructor() public {
        // register the supported interfaces to conform to ERC1155 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155);
    }

    /**
        @dev Get the specified address' balance for token with specified ID.

        Attempting to query the zero account for a balance will result in a revert.

        @param account The address of the token holder
        @param id ID of the token
        @return The account's balance of the token type requested
     */
    function balanceOf(address account, uint256 id) public view override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        require(_exists(id), "ERC1155: balance query for nonexistent token");
        return _balances[id][account];
    }

    /**
        @dev Get the balance of multiple account/token pairs.

        If any of the query accounts is the zero account, this query will revert.

        @param accounts The addresses of the token holders
        @param ids IDs of the tokens
        @return Balances for each account and token id pair
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and IDs must have same lengths");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            require(accounts[i] != address(0), "ERC1155: some address in batch balance query is zero");
            require(_exists(ids[i]), "ERC1155: some token in batch balance query does not exist");
            batchBalances[i] = _balances[ids[i]][accounts[i]];
        }

        return batchBalances;
    }

    /**
     * @dev Sets or unsets the approval of a given operator.
     *
     * An operator is allowed to transfer all tokens of the sender on their behalf.
     *
     * Because an account already has operator privileges for itself, this function will revert
     * if the account attempts to set the approval status for itself.
     *
     * @param operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address operator, bool approved) external override virtual {
        require(msg.sender != operator, "ERC1155: cannot set approval status for self");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
        @notice Queries the approval status of an operator for a given account.
        @param account   The account of the Tokens
        @param operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address account, address operator) public view override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
        @dev Transfers `value` amount of an `id` from the `from` address to the `to` address specified.
        Caller must be approved to manage the tokens being transferred out of the `from` account.
        If `to` is a smart contract, will call `onERC1155Received` on `to` and act appropriately.
        @param from Source address
        @param to Target address
        @param id ID of the token type
        @param value Transfer amount
        @param data Data forwarded to `onERC1155Received` if `to` is a contract receiver
    */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        override
        virtual
    {
        require(to != address(0), "ERC1155: target address must be non-zero");
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender) == true,
            "ERC1155: need operator approval for 3rd party transfers"
        );

        _balances[id][from] = _balances[id][from].sub(value, "ERC1155: insufficient balance for transfer");
        _balances[id][to] = _balances[id][to].add(value);

        emit TransferSingle(msg.sender, from, to, id, value);

        _doSafeTransferAcceptanceCheck(msg.sender, from, to, id, value, data);
    }

    /**
        @dev Transfers `values` amount(s) of `ids` from the `from` address to the
        `to` address specified. Caller must be approved to manage the tokens being
        transferred out of the `from` account. If `to` is a smart contract, will
        call `onERC1155BatchReceived` on `to` and act appropriately.
        @param from Source address
        @param to Target address
        @param ids IDs of each token type
        @param values Transfer amounts per token type
        @param data Data forwarded to `onERC1155Received` if `to` is a contract receiver
    */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        override
        virtual
    {
        require(ids.length == values.length, "ERC1155: IDs and values must have same lengths");
        require(to != address(0), "ERC1155: target address must be non-zero");
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender) == true,
            "ERC1155: need operator approval for 3rd party transfers"
        );

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 value = values[i];

            _balances[id][from] = _balances[id][from].sub(
                value,
                "ERC1155: insufficient balance of some token type for transfer"
            );
            _balances[id][to] = _balances[id][to].add(value);
        }

        emit TransferBatch(msg.sender, from, to, ids, values);

        _doSafeBatchTransferAcceptanceCheck(msg.sender, from, to, ids, values, data);
    }

    /**
     * @dev Register a token ID so other contract functionality knows this token
     * actually exists and this ID is valid. Minting will automatically call this.
     * @param id uint256 ID of the token to register
     */
    function _registerToken(uint256 id) internal virtual {
        _tokenExists[id] = true;
    }

    /**
     * @dev Returns whether the specified token exists. Use {_registerTokenID} to set this flag.
     * @param id uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 id) internal view returns (bool) {
        return _tokenExists[id];
    }

    /**
     * @dev Internal function to mint an amount of a token with the given ID
     * @param to The address that will own the minted token
     * @param id ID of the token to be minted
     * @param value Amount of the token to be minted
     * @param data Data forwarded to `onERC1155Received` if `to` is a contract receiver
     */
    function _mint(address to, uint256 id, uint256 value, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        if (!_exists(id)) {
            _registerToken(id);
        }
        _balances[id][to] = _balances[id][to].add(value);
        emit TransferSingle(msg.sender, address(0), to, id, value);

        _doSafeTransferAcceptanceCheck(msg.sender, address(0), to, id, value, data);
    }

    /**
     * @dev Internal function to batch mint amounts of tokens with the given IDs
     * @param to The address that will own the minted token
     * @param ids IDs of the tokens to be minted
     * @param values Amounts of the tokens to be minted
     * @param data Data forwarded to `onERC1155Received` if `to` is a contract receiver
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory values, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: batch mint to the zero address");
        require(ids.length == values.length, "ERC1155: minted IDs and values must have same lengths");

        for(uint i = 0; i < ids.length; i++) {
            if (!_exists(ids[i])) {
                _registerToken(ids[i]);
            }
            _balances[ids[i]][to] = values[i].add(_balances[ids[i]][to]);
        }

        emit TransferBatch(msg.sender, address(0), to, ids, values);

        _doSafeBatchTransferAcceptanceCheck(msg.sender, address(0), to, ids, values, data);
    }

    /**
     * @dev Internal function to burn an amount of a token with the given ID
     * @param account Account which owns the token to be burnt
     * @param id ID of the token to be burnt
     * @param value Amount of the token to be burnt
     */
    function _burn(address account, uint256 id, uint256 value) internal virtual {
        require(account != address(0), "ERC1155: attempting to burn tokens on zero account");

        _balances[id][account] = _balances[id][account].sub(
            value,
            "ERC1155: attempting to burn more than balance"
        );
        emit TransferSingle(msg.sender, account, address(0), id, value);
    }

    /**
     * @dev Internal function to batch burn an amounts of tokens with the given IDs
     * @param account Account which owns the token to be burnt
     * @param ids IDs of the tokens to be burnt
     * @param values Amounts of the tokens to be burnt
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory values) internal virtual {
        require(account != address(0), "ERC1155: attempting to burn batch of tokens on zero account");
        require(ids.length == values.length, "ERC1155: burnt IDs and values must have same lengths");

        for(uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][account] = _balances[ids[i]][account].sub(
                values[i],
                "ERC1155: attempting to burn more than balance for some token"
            );
        }

        emit TransferBatch(msg.sender, account, address(0), ids, values);
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    )
        internal
        virtual
    {
        if(to.isContract()) {
            require(
                IERC1155Receiver(to).onERC1155Received(operator, from, id, value, data) ==
                    IERC1155Receiver(to).onERC1155Received.selector,
                "ERC1155: got unknown value from onERC1155Received"
            );
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    )
        internal
        virtual
    {
        if(to.isContract()) {
            require(
                IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, values, data) ==
                    IERC1155Receiver(to).onERC1155BatchReceived.selector,
                "ERC1155: got unknown value from onERC1155BatchReceived"
            );
        }
    }
}

// File: contracts/OZ_ERC1155/IERC1155MetadataURI.sol

pragma solidity ^0.6.0;


/**
 * @title ERC-1155 Multi Token Standard basic interface, optional metadata URI extension
 * @dev See https://eips.ethereum.org/EIPS/eip-1155
 */
abstract contract IERC1155MetadataURI is IERC1155 {
    function uri(uint256 id) external view virtual returns (string memory);
}

// File: contracts/OZ_ERC1155/ERC1155MetadataURICatchAll.sol

pragma solidity ^0.6.0;




contract ERC1155MetadataURICatchAll is ERC165, ERC1155, IERC1155MetadataURI {
    // Catch-all URI with placeholders, e.g. https://example.com/{locale}/{id}.json
    string private _uri;

     /*
     *     bytes4(keccak256('uri(uint256)')) == 0x0e89341c
     */
    bytes4 private constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;

    /**
     * @dev Constructor function
     */
    constructor (string memory uri) public {
        _setURI(uri);

        // register the supported interfaces to conform to ERC1155 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
    }

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given token.
     * @dev URIs are defined in RFC 3986.
     * The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
     * param id uint256 ID of the token to query (ignored in this particular implementation,
     * as an {id} parameter in the string is expected)
     * @return URI string
    */
    function uri(uint256 id) external view override returns (string memory) {
        require(_exists(id), "ERC1155MetadataURI: URI query for nonexistent token");
        return _uri;
    }

    /**
     * @dev Internal function to set a new URI
     * @param newuri New URI to be set
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
        emit URI(_uri, 0);
    }
}

// File: contracts/ENSReverseRegistrarI.sol

/*
 * Interfaces for ENS Reverse Registrar
 * See https://github.com/ensdomains/ens/blob/master/contracts/ReverseRegistrar.sol for full impl
 * Also see https://github.com/wealdtech/wealdtech-solidity/blob/master/contracts/ens/ENSReverseRegister.sol
 *
 * Use this as follows (registryAddress is the address of the ENS registry to use):
 * -----
 * // This hex value is caclulated by namehash('addr.reverse')
 * bytes32 public constant ENS_ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;
 * function registerReverseENS(address registryAddress, string memory calldata) external {
 *     require(registryAddress != address(0), "need a valid registry");
 *     address reverseRegistrarAddress = ENSRegistryOwnerI(registryAddress).owner(ENS_ADDR_REVERSE_NODE)
 *     require(reverseRegistrarAddress != address(0), "need a valid reverse registrar");
 *     ENSReverseRegistrarI(reverseRegistrarAddress).setName(name);
 * }
 * -----
 * or
 * -----
 * function registerReverseENS(address reverseRegistrarAddress, string memory calldata) external {
 *    require(reverseRegistrarAddress != address(0), "need a valid reverse registrar");
 *     ENSReverseRegistrarI(reverseRegistrarAddress).setName(name);
 * }
 * -----
 * ENS deployments can be found at https://docs.ens.domains/ens-deployments
 * For Mainnet, 0x9062c0a6dbd6108336bcbe4593a3d1ce05512069 is the reverseRegistrarAddress,
 * for Ropsten, it is at 0x67d5418a000534a8F1f5FF4229cC2f439e63BBe2.
 */
pragma solidity ^0.6.0;

interface ENSRegistryOwnerI {
    function owner(bytes32 node) external view returns (address);
}

interface ENSReverseRegistrarI {
    function setName(string calldata name) external returns (bytes32 node);
}

// File: contracts/OracleRequest.sol

/*
Interface for requests to the rate oracle (for EUR/ETH)
Copy this to projects that need to access the oracle.
See rate-oracle project for implementation.
*/
pragma solidity ^0.6.0;


abstract contract OracleRequest {

    uint256 public EUR_WEI; //number of wei per EUR

    uint256 public lastUpdate; //timestamp of when the last update occurred

    function ETH_EUR() public view virtual returns (uint256); //number of EUR per ETH (rounded down!)

    function ETH_EURCENT() public view virtual returns (uint256); //number of EUR cent per ETH (rounded down!)

}

// File: contracts/CS2PresaleIBuyDP.sol

/*
Interfacte for CS2 on-chain presale for usage with DirectPay contracts.
*/
pragma solidity ^0.6.0;

abstract contract CS2PresaleIBuyDP {
    enum AssetType {
        Honeybadger,
        Llama,
        Panda,
        Doge
    }

    // Buy assets of a single type/animal. The number of assets is determined from the amount of ETH sent.
    // This variant will be used externally from the CS2PresaleDirectPay contracts, which need to buy for _their_ msg.sender.
    function buy(AssetType _type, address payable _recipient) public payable virtual;

}

// File: contracts/CS2PresaleDirectPay.sol

/*
Implements an on-chain presale for Crypto stamp Edition 2
*/
pragma solidity ^0.6.0;






contract CS2PresaleDirectPay {
    using SafeMath for uint256;

    address public tokenAssignmentControl;

    CS2PresaleIBuyDP public presale;
    CS2PresaleIBuyDP.AssetType public assetType;

    event TokenAssignmentControlTransferred(address indexed previousTokenAssignmentControl, address indexed newTokenAssignmentControl);

    constructor(CS2PresaleIBuyDP _presale,
        CS2PresaleIBuyDP.AssetType _assetType,
        address _tokenAssignmentControl)
    public
    {
        presale = _presale;
        require(address(presale) != address(0x0), "You need to provide an actual presale contract.");
        assetType = _assetType;
        tokenAssignmentControl = _tokenAssignmentControl;
        require(address(tokenAssignmentControl) != address(0x0), "You need to provide an actual tokenAssignmentControl address.");
    }

    modifier onlyTokenAssignmentControl() {
        require(msg.sender == tokenAssignmentControl, "tokenAssignmentControl key required for this function.");
        _;
    }

    /*** Enable adjusting variables after deployment ***/

    function transferTokenAssignmentControl(address _newTokenAssignmentControl)
    public
    onlyTokenAssignmentControl
    {
        require(_newTokenAssignmentControl != address(0), "tokenAssignmentControl cannot be the zero address.");
        emit TokenAssignmentControlTransferred(tokenAssignmentControl, _newTokenAssignmentControl);
        tokenAssignmentControl = _newTokenAssignmentControl;
    }

    /*** Actual presale functionality ***/

    // Buy assets of a single type/animal. The number of assets is determined from the amount of ETH sent.
    receive()
    external payable
    {
        presale.buy{value: msg.value}(assetType, msg.sender);
    }

    /*** Enable reverse ENS registration ***/

    // Call this with the address of the reverse registrar for the respecitve network and the ENS name to register.
    // The reverse registrar can be found as the owner of 'addr.reverse' in the ENS system.
    // For Mainnet, the address needed is 0x9062c0a6dbd6108336bcbe4593a3d1ce05512069
    function registerReverseENS(address _reverseRegistrarAddress, string calldata _name)
    external
    onlyTokenAssignmentControl
    {
        require(_reverseRegistrarAddress != address(0), "need a valid reverse registrar");
        ENSReverseRegistrarI(_reverseRegistrarAddress).setName(_name);
    }

    /*** Make sure currency or NFT doesn't get stranded in this contract ***/

    // If this contract gets a balance in some ERC20 contract after it's finished, then we can rescue it.
    function rescueToken(IERC20 _foreignToken, address _to)
    external
    onlyTokenAssignmentControl
    {
        _foreignToken.transfer(_to, _foreignToken.balanceOf(address(this)));
    }

    // If this contract gets a balance in some ERC721 contract after it's finished, then we can rescue it.
    function approveNFTrescue(IERC721 _foreignNFT, address _to)
    external
    onlyTokenAssignmentControl
    {
        _foreignNFT.setApprovalForAll(_to, true);
    }

}

// File: contracts/CS2Presale.sol

/*
Implements an on-chain presale for Crypto stamp Edition 2
*/
pragma solidity ^0.6.0;









contract CS2Presale is ERC1155MetadataURICatchAll, CS2PresaleIBuyDP {
    using SafeMath for uint256;

    OracleRequest internal oracle;

    address payable public beneficiary;
    address public tokenAssignmentControl;
    address public redeemer;

    uint256 public priceEurCent;

    uint256 public limitPerType;

    // Keep those sizes in sync with the length of the AssetType enum.
    uint256[4] public assetSupply;
    uint256[4] public assetSold;
    CS2PresaleDirectPay[4] public directPay;

    bool internal _isOpen = true;

    event DirectPayDeployed(address directPayContract);
    event PriceChanged(uint256 previousPriceEurCent, uint256 newPriceEurCent);
    event LimitChanged(uint256 previousLimitPerType, uint256 newLimitPerType);
    event OracleChanged(address indexed previousOracle, address indexed newOracle);
    event BeneficiaryTransferred(address indexed previousBeneficiary, address indexed newBeneficiary);
    event TokenAssignmentControlTransferred(address indexed previousTokenAssignmentControl, address indexed newTokenAssignmentControl);
    event RedeemerTransferred(address indexed previousRedeemer, address indexed newRedeemer);
    event ShopOpened();
    event ShopClosed();

    constructor(OracleRequest _oracle,
        uint256 _priceEurCent,
        uint256 _limitPerType,
        address payable _beneficiary,
        address _tokenAssignmentControl)
    ERC1155MetadataURICatchAll("https://test.crypto.post.at/CS2PS/meta/{id}")
    public
    {
        oracle = _oracle;
        require(address(oracle) != address(0x0), "You need to provide an actual Oracle contract.");
        beneficiary = _beneficiary;
        require(address(beneficiary) != address(0x0), "You need to provide an actual beneficiary address.");
        tokenAssignmentControl = _tokenAssignmentControl;
        require(address(tokenAssignmentControl) != address(0x0), "You need to provide an actual tokenAssignmentControl address.");
        redeemer = tokenAssignmentControl;
        priceEurCent = _priceEurCent;
        require(priceEurCent > 0, "You need to provide a non-zero price.");
        limitPerType = _limitPerType;
        // Register the token IDs we'll be using.
        uint256 typesNum = assetSupply.length;
        for (uint256 i = 0; i < typesNum; i++) {
            _registerToken(i);
        }
    }

    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "Only the current benefinicary can call this function.");
        _;
    }

    modifier onlyTokenAssignmentControl() {
        require(msg.sender == tokenAssignmentControl, "tokenAssignmentControl key required for this function.");
        _;
    }

    modifier onlyRedeemer() {
        require(msg.sender == redeemer, "Only the current redeemer can call this function.");
        _;
    }

    modifier requireOpen() {
        require(isOpen() == true, "This call only works when the presale is open.");
        _;
    }

    /*** Deploy DirectPay contracts ***/

    // This is its own function as it takes about 2M gas in addition to the 4M+ gas the main contract needs,
    // so it's probably better not to do this right in the constructor.
    // As it can only be done once and the caller cannot influence it, no restrictions are made on who can call it.
    function deployDP()
    public
    {
        uint256 typesNum = directPay.length;
        for (uint256 i = 0; i < typesNum; i++) {
            require(address(directPay[i]) == address(0x0), "direct-pay contracts have already been deployed.");
            directPay[i] = new CS2PresaleDirectPay(this, AssetType(i), tokenAssignmentControl);
            emit DirectPayDeployed(address(directPay[i]));
        }
    }

    /*** Enable adjusting variables after deployment ***/

    function setPrice(uint256 _newPriceEurCent)
    public
    onlyBeneficiary
    {
        require(_newPriceEurCent > 0, "You need to provide a non-zero price.");
        emit PriceChanged(priceEurCent, _newPriceEurCent);
        priceEurCent = _newPriceEurCent;
    }

    function setLimit(uint256 _newLimitPerType)
    public
    onlyBeneficiary
    {
        uint256 typesNum = assetSold.length;
        for (uint256 i = 0; i < typesNum; i++) {
            require(assetSold[i] <= _newLimitPerType, "At least one requested asset is already over the requested limit.");
        }
        emit LimitChanged(limitPerType, _newLimitPerType);
        limitPerType = _newLimitPerType;
    }

    function setOracle(OracleRequest _newOracle)
    public
    onlyBeneficiary
    {
        require(address(_newOracle) != address(0x0), "You need to provide an actual Oracle contract.");
        emit OracleChanged(address(oracle), address(_newOracle));
        oracle = _newOracle;
    }

    function setMetadataURI(string memory _newURI)
    public
    onlyBeneficiary
    {
        _setURI(_newURI);
    }

    function transferBeneficiary(address payable _newBeneficiary)
    public
    onlyBeneficiary
    {
        require(_newBeneficiary != address(0), "beneficiary cannot be the zero address.");
        emit BeneficiaryTransferred(beneficiary, _newBeneficiary);
        beneficiary = _newBeneficiary;
    }

    function transferTokenAssignmentControl(address _newTokenAssignmentControl)
    public
    onlyTokenAssignmentControl
    {
        require(_newTokenAssignmentControl != address(0), "tokenAssignmentControl cannot be the zero address.");
        emit TokenAssignmentControlTransferred(tokenAssignmentControl, _newTokenAssignmentControl);
        tokenAssignmentControl = _newTokenAssignmentControl;
    }

    function transferRedeemer(address _newRedeemer)
    public
    onlyRedeemer
    {
        require(_newRedeemer != address(0), "redeemer cannot be the zero address.");
        emit RedeemerTransferred(redeemer, _newRedeemer);
        redeemer = _newRedeemer;
    }

    function openShop()
    public
    onlyBeneficiary
    {
        _isOpen = true;
        emit ShopOpened();
    }

    function closeShop()
    public
    onlyBeneficiary
    {
        _isOpen = false;
        emit ShopClosed();
    }

    /*** Actual presale functionality ***/

    // Return true if presale is currently open for purchases.
    // This can have additional conditions to just the variable, e.g. actually having items to sell.
    function isOpen()
    public view
    returns (bool)
    {
        return _isOpen;
    }

    // Calculate current asset price in wei.
    // Note: Price in EUR cent is available from public var getter priceEurCent().
    function priceWei()
    public view
    returns (uint256)
    {
        return priceEurCent.mul(oracle.EUR_WEI()).div(100);
    }

    // This returns the total amount of all assets currently existing.
    function totalSupply()
    public view
    returns (uint256)
    {
        uint256 _totalSupply = 0;
        uint256 typesNum = assetSupply.length;
        for (uint256 i = 0; i < typesNum; i++) {
            _totalSupply = _totalSupply.add(assetSupply[i]);
        }
        return _totalSupply;
    }

    // This returns the total amount of all assets created/sold.
    function totalSold()
    public view
    returns (uint256)
    {
        uint256 _totalSold = 0;
        uint256 typesNum = assetSold.length;
        for (uint256 i = 0; i < typesNum; i++) {
            _totalSold = _totalSold.add(assetSold[i]);
        }
        return _totalSold;
    }

    // Returns the amount of assets of that type still available for sale.
    function availableForSale(AssetType _type)
    public view
    returns (uint256)
    {
        return limitPerType.sub(assetSold[uint256(_type)]);
    }

    // Returns true if the asset of the given type is sold out.
    function isSoldOut(AssetType _type)
    public view
    returns (bool)
    {
        return assetSold[uint256(_type)] >= limitPerType;
    }

    // Buy assets of a single type/animal. The number of assets is determined from the amount of ETH sent.
    function buy(AssetType _type)
    external payable
    requireOpen
    {
        buy(_type, msg.sender);
    }

    // Buy assets of a single type/animal. The number of assets is determined from the amount of ETH sent.
    // This variant will be used externally from the CS2PresaleDirectPay contracts, which need to buy for _their_ msg.sender.
    function buy(AssetType _type, address payable _recipient)
    public payable override
    requireOpen
    {
        uint256 curPriceWei = priceWei();
        require(msg.value >= curPriceWei, "You need to send enough currency to actually pay at least one item.");
        uint256 maxToSell = limitPerType.sub(assetSold[uint256(_type)]);
        require(maxToSell > 0, "The requested asset is sold out.");
        // Determine amount of assets to buy from payment value (algorithm rounds down).
        uint256 assetCount = msg.value.div(curPriceWei);
        // Don't allow buying more assets than available of this type.
        if (assetCount > maxToSell) {
            assetCount = maxToSell;
        }
        // Determine actual price of rounded-down count.
        uint256 payAmount = assetCount.mul(curPriceWei);
        // Transfer the actual payment amount to the beneficiary.
        beneficiary.transfer(payAmount);
        // Generate and assign the actual assets.
        _mint(_recipient, uint256(_type), assetCount, bytes(""));
        assetSupply[uint256(_type)] = assetSupply[uint256(_type)].add(assetCount);
        assetSold[uint256(_type)] = assetSold[uint256(_type)].add(assetCount);
        // Send back change money. Do this last.
        if (msg.value > payAmount) {
            _recipient.transfer(msg.value.sub(payAmount));
        }
    }

    // Buy assets of a multiple types/animals at once.
    function buyBatch(AssetType[] calldata _type, uint256[] calldata _count)
    external payable
    requireOpen
    {
        uint256 inputlines = _type.length;
        require(inputlines == _count.length, "Both input arrays need to be the same length.");
        uint256 curPriceWei = priceWei();
        require(msg.value >= curPriceWei, "You need to send enough currency to actually pay at least one item.");
        // Determine actual price of items to buy.
        uint256 payAmount = 0;
        uint256[] memory ids = new uint256[](inputlines);
        for (uint256 i = 0; i < inputlines; i++) {
            payAmount = payAmount.add(_count[i].mul(curPriceWei));
            ids[i] = uint256(_type[i]);
            assetSupply[ids[i]] = assetSupply[ids[i]].add(_count[i]);
            assetSold[ids[i]] = assetSold[ids[i]].add(_count[i]);
            // If any asset in the batch would go over the limit, fail the whole transaction.
            require(assetSold[ids[i]] <= limitPerType, "At least one requested asset is sold out.");
        }
        require(msg.value >= payAmount, "You need to send enough currency to actually pay all specified items.");
        // Transfer the actual payment amount to the beneficiary.
        beneficiary.transfer(payAmount);
        // Generate and assign the actual assets.
        _mintBatch(msg.sender, ids, _count, bytes(""));
        // Send back change money. Do this last.
        if (msg.value > payAmount) {
            msg.sender.transfer(msg.value.sub(payAmount));
        }
    }

    // Redeem assets of a multiple types/animals at once.
    // This burns them in this contract, but should be called by a contract that assigns/creates the final assets in turn.
    function redeemBatch(address owner, AssetType[] calldata _type, uint256[] calldata _count)
    external
    onlyRedeemer
    {
        uint256 inputlines = _type.length;
        require(inputlines == _count.length, "Both input arrays need to be the same length.");
        uint256[] memory ids = new uint256[](inputlines);
        for (uint256 i = 0; i < inputlines; i++) {
            ids[i] = uint256(_type[i]);
            assetSupply[ids[i]] = assetSupply[ids[i]].sub(_count[i]);
        }
        _burnBatch(owner, ids, _count);
    }

    // Returns whether the specified token exists.
    function exists(uint256 id) public view returns (bool) {
        return _exists(id);
    }

    /*** Enable reverse ENS registration ***/

    // Call this with the address of the reverse registrar for the respecitve network and the ENS name to register.
    // The reverse registrar can be found as the owner of 'addr.reverse' in the ENS system.
    // For Mainnet, the address needed is 0x9062c0a6dbd6108336bcbe4593a3d1ce05512069
    function registerReverseENS(address _reverseRegistrarAddress, string calldata _name)
    external
    onlyTokenAssignmentControl
    {
        require(_reverseRegistrarAddress != address(0), "need a valid reverse registrar");
        ENSReverseRegistrarI(_reverseRegistrarAddress).setName(_name);
    }

    /*** Make sure currency or NFT doesn't get stranded in this contract ***/

    // If this contract gets a balance in some ERC20 contract after it's finished, then we can rescue it.
    function rescueToken(IERC20 _foreignToken, address _to)
    external
    onlyTokenAssignmentControl
    {
        _foreignToken.transfer(_to, _foreignToken.balanceOf(address(this)));
    }

    // If this contract gets a balance in some ERC721 contract after it's finished, then we can rescue it.
    function approveNFTrescue(IERC721 _foreignNFT, address _to)
    external
    onlyTokenAssignmentControl
    {
        _foreignNFT.setApprovalForAll(_to, true);
    }

}