/**
 *Submitted for verification at Etherscan.io on 2019-10-25
*/

pragma solidity 0.5.0;
// File: src/erc777/IERC777.sol


/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * [ERC1820 registry standard](https://eips.ethereum.org/EIPS/eip-1820) to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See `IERC1820Registry` and
 * `ERC1820Implementer`.
 */
interface IERC777 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See `IERC777Sender` and `IERC777Recipient`.
     *
     * Emits a `Sent` event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the `tokensReceived`
     * interface.
     */
    function send(address recipient, uint256 amount, bytes calldata data) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See `IERC777Sender`.
     *
     * Emits a `Burned` event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See `operatorSend` and `operatorBurn`.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See `isOperatorFor`.
     *
     * Emits an `AuthorizedOperator` event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Make an account an operator of the caller.
     *
     * See `isOperatorFor` and `defaultOperators`.
     *
     * Emits a `RevokedOperator` event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if `authorizeOperator` was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * `revokeOperator`, in which case `isOperatorFor` will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See `IERC777Sender` and `IERC777Recipient`.
     *
     * Emits a `Sent` event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the `tokensReceived`
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destoys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See `IERC777Sender`.
     *
     * Emits a `Burned` event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

// File: src/erc777/IERC777Recipient.sol


/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of `IERC777` tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * [ERC1820 global registry](https://eips.ethereum.org/EIPS/eip-1820).
 *
 * See `IERC1820Registry` and `ERC1820Implementer`.
 */
interface IERC777Recipient {
    /**
     * @dev Called by an `IERC777` token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * `IERC777.balanceOf`, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// File: src/erc777/IERC777Sender.sol


/**
 * @dev Interface of the ERC777TokensSender standard as defined in the EIP.
 *
 * `IERC777` Token holders can be notified of operations performed on their
 * tokens by having a contract implement this interface (contract holders can be
 *  their own implementer) and registering it on the
 * [ERC1820 global registry](https://eips.ethereum.org/EIPS/eip-1820).
 *
 * See `IERC1820Registry` and `ERC1820Implementer`.
 */
interface IERC777Sender {
    /**
     * @dev Called by an `IERC777` token contract whenever a registered holder's
     * (`from`) tokens are about to be moved or destroyed. The type of operation
     * is conveyed by `to` being the zero address or not.
     *
     * This call occurs _before_ the token contract's state is updated, so
     * `IERC777.balanceOf`, etc., can be used to query the pre-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol


/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol


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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/utils/Address.sol


/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// File: openzeppelin-solidity/contracts/introspection/IERC1820Registry.sol


/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * [EIP](https://eips.ethereum.org/EIPS/eip-1820). Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * `IERC165` interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a `ManagerChanged` event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See `setManager`.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as `account`'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See `interfaceHash` to learn how these are created.
     *
     * Emits an `InterfaceImplementerSet` event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an `IERC165` interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement `IERC1820Implementer` and return true when
     * queried for support, unless `implementer` is the caller. See
     * `IERC1820Implementer.canImplementInterfaceForAddress`.
     */
    function setInterfaceImplementer(address account, bytes32 interfaceHash, address implementer) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an `IERC165` interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * [section of the EIP](https://eips.ethereum.org/EIPS/eip-1820#interface-name).
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     *  @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     *  @param account Address of the contract for which to update the cache.
     *  @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     *  @notice Checks whether a contract implements an ERC165 interface or not.
     *  If the result is not cached a direct lookup on the contract address is performed.
     *  If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     *  'updateERC165Cache' with the contract address.
     *  @param account Address of the contract to check.
     *  @param interfaceId ERC165 interface to check.
     *  @return True if `account.address()` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     *  @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     *  @param account Address of the contract to check.
     *  @param interfaceId ERC165 interface to check.
     *  @return True if `account.address()` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);

    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);
}

// File: src/erc777/EarnERC777.sol









contract EarnERC777 is IERC777, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    struct Balance {
        uint256 value;
        uint256 exchangeRate;
    }

    uint256 constant RATE_SCALE = 10**18;
    uint256 constant DECIMAL_SCALE = 10**18;

    IERC1820Registry internal _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    mapping(address => Balance) internal _balances;

    uint256 internal _totalSupply;
    uint256 internal _exchangeRate;

    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;

    // We inline the result of the following hashes because Solidity doesn't resolve them at compile time.
    // See https://github.com/ethereum/solidity/issues/4024.

    // keccak256("ERC777TokensSender")
    bytes32 constant internal TOKENS_SENDER_INTERFACE_HASH =
        0x29ddb589b1fb5fc7cf394961c1adf5f8c6454761adf795e67fe149f658abe895;

    // keccak256("ERC777TokensRecipient")
    bytes32 constant internal TOKENS_RECIPIENT_INTERFACE_HASH =
        0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;

    //Empty, This is only used to respond the defaultOperators query.
    address[] internal _defaultOperatorsArray;

    // For each account, a mapping of its operators and revoked default operators.
    mapping(address => mapping(address => bool)) internal _operators;

    // ERC20-allowances
    mapping (address => mapping (address => uint256)) internal _allowances;

    constructor(
        string memory symbol,
        string memory name,
        uint8 decimals
    ) public {
        require(decimals <= 18, "decimals must be less or equal than 18");

        _name = name;
        _symbol = symbol;
        _decimals = decimals;

        _exchangeRate = 10**18;

        // register interfaces
        _erc1820.setInterfaceImplementer(address(this), keccak256("ERC777Token"), address(this));
        _erc1820.setInterfaceImplementer(address(this), keccak256("ERC20Token"), address(this));
    }

    /**
     * @dev See `IERC777.name`.
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev See `IERC777.symbol`.
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See `ERC20Detailed.decimals`.
     *
     * Always returns 18, as per the
     * [ERC777 EIP](https://eips.ethereum.org/EIPS/eip-777#backward-compatibility).
     */
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See `IERC777.granularity`.
     *
     * This implementation always returns `1`.
     */
    function granularity() external view returns (uint256) {
        return 1;
    }

    /**
     * @dev See `IERC777.totalSupply`.
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply.div(DECIMAL_SCALE);
    }

    /**
     * @dev Returns the amount of tokens owned by an account (`tokenHolder`).
     */
    function balanceOf(address who) external view returns (uint256) {
        return _balanceOf(who);
    }

    function _balanceOf(address who) internal view returns (uint256) {
        return _getBalance(who).value.div(DECIMAL_SCALE);
    }

    function accuracyBalanceOf(address who) external view returns (uint256) {
        return _getBalance(who).value ;
    }

    /**
     * @dev See `IERC777.send`.
     *
     * Also emits a `Transfer` event for ERC20 compatibility.
     */
    function send(address recipient, uint256 amount, bytes calldata data) external {
        _send(msg.sender, msg.sender, recipient, amount, data, "", true);
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Unlike `send`, `recipient` is _not_ required to implement the `tokensReceived`
     * interface if it is a contract.
     *
     * Also emits a `Sent` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool) {
        return _transfer(recipient, amount);
    }

    function _transfer(address recipient, uint256 amount) internal returns (bool) {
        require(recipient != address(0), "ERC777: transfer to the zero address");

        address from = msg.sender;

        _callTokensToSend(from, from, recipient, amount, "", "");

        _move(from, from, recipient, amount, "", "");

        _callTokensReceived(from, from, recipient, amount, "", "", false);

        return true;
    }

    /**
     * @dev See `IERC777.burn`.
     *
     * Also emits a `Transfer` event for ERC20 compatibility.
     */
    function burn(uint256 amount, bytes calldata data) external {
        _burn(msg.sender, msg.sender, amount, data, "");
    }

    /**
     * @dev See `IERC777.isOperatorFor`.
     */
    function isOperatorFor(
        address operator,
        address tokenHolder
    ) public view returns (bool) {
        return operator == tokenHolder ||
            _operators[tokenHolder][operator];
    }

    /**
     * @dev See `IERC777.authorizeOperator`.
     */
    function authorizeOperator(address operator) external {
        require(msg.sender != operator, "ERC777: authorizing self as operator");

       _operators[msg.sender][operator] = true;

        emit AuthorizedOperator(operator, msg.sender);
    }

    /**
     * @dev See `IERC777.revokeOperator`.
     */
    function revokeOperator(address operator) external {
        require(operator != msg.sender, "ERC777: revoking self as operator");

        delete _operators[msg.sender][operator];

        emit RevokedOperator(operator, msg.sender);
    }

    /**
     * @dev See `IERC777.defaultOperators`.
     */
    function defaultOperators() external view returns (address[] memory) {
        return _defaultOperatorsArray;
    }

    /**
     * @dev See `IERC777.operatorSend`.
     *
     * Emits `Sent` and `Transfer` events.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external {
        require(isOperatorFor(msg.sender, sender), "ERC777: caller is not an operator for holder");
        _send(msg.sender, sender, recipient, amount, data, operatorData, true);
    }

    /**
     * @dev See `IERC777.operatorBurn`.
     *
     * Emits `Sent` and `Transfer` events.
     */
    function operatorBurn(address account, uint256 amount, bytes calldata data, bytes calldata operatorData) external {
        require(isOperatorFor(msg.sender, account), "ERC777: caller is not an operator for holder");
        _burn(msg.sender, account, amount, data, operatorData);
    }

    /**
     * @dev See `IERC20.allowance`.
     *
     * Note that operator and allowance concepts are orthogonal: operators may
     * not have allowance, and accounts with allowance may not be operators
     * themselves.
     */
    function allowance(address holder, address spender) external view returns (uint256) {
        return _allowances[holder][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Note that accounts cannot have allowance issued by their operators.
     */
    function approve(address spender, uint256 value) external returns (bool) {
        address holder = msg.sender;
        _approve(holder, spender, value);
        return true;
    }

   /**
    * @dev See `IERC20.transferFrom`.
    *
    * Note that operator and allowance concepts are orthogonal: operators cannot
    * call `transferFrom` (unless they have allowance), and accounts with
    * allowance cannot call `operatorSend` (unless they are operators).
    *
    * Emits `Sent` and `Transfer` events.
    */
    function transferFrom(address holder, address recipient, uint256 amount) external returns (bool) {
        return _transferFrom(holder, recipient, amount);
    }

    function _transferFrom(address holder, address recipient, uint256 amount) internal returns (bool) {
        require(recipient != address(0), "ERC777: transfer to the zero address");
        require(holder != address(0), "ERC777: transfer from the zero address");

        address spender = msg.sender;

        _callTokensToSend(spender, holder, recipient, amount, "", "");

        _move(spender, holder, recipient, amount, "", "");

        _approve(holder, spender, _allowances[holder][spender].sub(amount));

        _callTokensReceived(spender, holder, recipient, amount, "", "", false);

        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * If a send hook is registered for `raccount`, the corresponding function
     * will be called with `operator`, `data` and `operatorData`.
     *
     * See `IERC777Sender` and `IERC777Recipient`.
     *
     * Emits `Sent` and `Transfer` events.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - if `account` is a contract, it must implement the `tokensReceived`
     * interface.
     */
    function _mint(
        address operator,
        address account,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    )
    internal
    {
        require(account != address(0), "ERC777: mint to the zero address");

        _callTokensReceived(operator, address(0), account, amount, userData, operatorData, false);

        uint256 scaleAmount = amount.mul(DECIMAL_SCALE);
        _totalSupply = _totalSupply.add(scaleAmount);
        _addBalance(account, scaleAmount);

        emit Minted(operator, account, amount, userData, operatorData);
        emit Transfer(address(0), account, amount);
    }

    function _getBalance(address account) internal view returns (Balance memory) {
        Balance memory balance = _balances[account];

        if (balance.value == uint256(0)) {
            balance.value = 0;
            balance.exchangeRate = _exchangeRate;
        } else if (balance.exchangeRate != _exchangeRate) {
            balance.value = balance.value.mul(_exchangeRate).div(balance.exchangeRate);
            balance.exchangeRate = _exchangeRate;
        }

        return balance;
    }

    function _addBalance(address account, uint256 amount) internal {
        Balance memory balance = _getBalance(account);

        balance.value = balance.value.add(amount);

        _balances[account] = balance;
    }

    function _subBalance(address account, uint256 amount) internal {
        Balance memory balance = _getBalance(account);

        balance.value = balance.value.sub(amount);

        _balances[account] = balance;
    }

    /**
     * @dev Send tokens
     * @param operator address operator requesting the transfer
     * @param from address token holder address
     * @param to address recipient address
     * @param amount uint256 amount of tokens to transfer
     * @param userData bytes extra information provided by the token holder (if any)
     * @param operatorData bytes extra information provided by the operator (if any)
     * @param requireReceptionAck if true, contract recipients are required to implement ERC777TokensRecipient
     */
    function _send(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    )
        internal
    {
        require(from != address(0), "ERC777: send from the zero address");
        require(to != address(0), "ERC777: send to the zero address");

        _callTokensToSend(operator, from, to, amount, userData, operatorData);

        _move(operator, from, to, amount, userData, operatorData);

        _callTokensReceived(operator, from, to, amount, userData, operatorData, requireReceptionAck);
    }

    /**
     * @dev Burn tokens
     * @param operator address operator requesting the operation
     * @param from address token holder address
     * @param amount uint256 amount of tokens to burn
     * @param data bytes extra information provided by the token holder
     * @param operatorData bytes extra information provided by the operator (if any)
     */
    function _burn(
        address operator,
        address from,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    )
        internal
    {
        require(from != address(0), "ERC777: burn from the zero address");

        _callTokensToSend(operator, from, address(0), amount, data, operatorData);

        uint256 scaleAmount = amount.mul(DECIMAL_SCALE);

        _totalSupply = _totalSupply.sub(scaleAmount);
        _subBalance(from, scaleAmount);

        emit Burned(operator, from, amount, data, operatorData);
        emit Transfer(from, address(0), amount);
    }

    function _move(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    )
        internal
    {
        uint256 scaleAmount = amount.mul(DECIMAL_SCALE);

        _subBalance(from,scaleAmount);
        _addBalance(to,scaleAmount);

        emit Sent(operator, from, to, amount, userData, operatorData);
        emit Transfer(from, to, amount);
    }

    function _approve(address holder, address spender, uint256 value) internal {
        // TODO: restore this require statement if this function becomes internal, or is called at a new callsite. It is
        // currently unnecessary.
        //require(holder != address(0), "ERC777: approve from the zero address");
        require(spender != address(0), "ERC777: approve to the zero address");

        _allowances[holder][spender] = value;
        emit Approval(holder, spender, value);
    }

    /**
     * @dev Call from.tokensToSend() if the interface is registered
     * @param operator address operator requesting the transfer
     * @param from address token holder address
     * @param to address recipient address
     * @param amount uint256 amount of tokens to transfer
     * @param userData bytes extra information provided by the token holder (if any)
     * @param operatorData bytes extra information provided by the operator (if any)
     */
    function _callTokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    )
        internal
    {
        address implementer = _erc1820.getInterfaceImplementer(from, TOKENS_SENDER_INTERFACE_HASH);
        if (implementer != address(0)) {
            IERC777Sender(implementer).tokensToSend(operator, from, to, amount, userData, operatorData);
        }
    }

    /**
     * @dev Call to.tokensReceived() if the interface is registered. Reverts if the recipient is a contract but
     * tokensReceived() was not registered for the recipient
     * @param operator address operator requesting the transfer
     * @param from address token holder address
     * @param to address recipient address
     * @param amount uint256 amount of tokens to transfer
     * @param userData bytes extra information provided by the token holder (if any)
     * @param operatorData bytes extra information provided by the operator (if any)
     * @param requireReceptionAck if true, contract recipients are required to implement ERC777TokensRecipient
     */
    function _callTokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    )
        internal
    {
        address implementer = _erc1820.getInterfaceImplementer(to, TOKENS_RECIPIENT_INTERFACE_HASH);
        if (implementer != address(0)) {
            IERC777Recipient(implementer).tokensReceived(operator, from, to, amount, userData, operatorData);
        } else if (requireReceptionAck) {
            require(!to.isContract(), "ERC777: token recipient contract has no implementer for ERC777TokensRecipient");
        }
    }

    function _distributeRevenue(address account) internal returns (bool) {
        uint256 value = _getBalance(account).value;

        require(value > 0, 'Token: the revenue balance must be large than zero');
        require(_totalSupply > value, 'Token: total supply must be large than revenue');

        delete _balances[account];

        _exchangeRate = _exchangeRate.mul(_totalSupply.mul(RATE_SCALE).div(_totalSupply.sub(value))).div(RATE_SCALE);

        emit Transfer(account, address(0), value.div(DECIMAL_SCALE));
        emit RevenueDistributed(account, _exchangeRate, value.div(DECIMAL_SCALE), value.mod(DECIMAL_SCALE));

        return true;
    }

    function exchangeRate() external view returns (uint256) {
        return _exchangeRate;
    }

    event RevenueDistributed(address indexed account, uint256 exchangeRate, uint256 value, uint256 remainder);
}

// File: openzeppelin-solidity/contracts/access/Roles.sol


/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: src/Ownable.sol


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;
    address private _newOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the new owner will be set
     */
     function newOwner() public view returns (address) {
        return _newOwner;
     }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address account) public onlyOwner {
        _transferOwnership(account);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address account) internal {
        require(account != address(0), "Ownable: new owner is the zero address");
        require(account != _newOwner, "Ownable: new owner is the same as previous owner");

        _newOwner = account;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (‘ newOwner ‘).
     * Can only be called by the current owner .
     */
    function acceptOwnership() public {
        require(msg.sender == _newOwner, "Ownable: msg.sender is not the same as newOwner");

        emit OwnershipTransferred(_owner, _newOwner);

        _owner = _newOwner;
        _newOwner = address(0);
    }
}

// File: src/MinterRole.sol




 contract MinterRole is Ownable {
     using Roles for Roles.Role;

     event MinterAdded(address indexed operator, address indexed account);
     event MinterRemoved(address indexed operator, address indexed account);

     Roles.Role private _minters;

     constructor () internal {
         _addMinter(msg.sender);
     }

     modifier onlyMinter() {
         require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
         _;
     }

     function isMinter(address account) public view returns (bool) {
         return _minters.has(account);
     }

     function addMinter(address account) public onlyOwner {
         _addMinter(account);
     }

     function removeMinter(address account) public onlyOwner {
         _removeMinter(account);
     }

     function _addMinter(address account) internal {
         _minters.add(account);
         emit MinterAdded(msg.sender, account);
     }

     function _removeMinter(address account) internal {
         _minters.remove(account);
         emit MinterRemoved(msg.sender, account);
     }
 }

// File: src/Pausable.sol



/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Ownable {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address indexed account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address indexed account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

// File: src/SwitchTransferable.sol



contract SwitchTransferable is Ownable {
    event TransferEnabled(address indexed operator);
    event TransferDisabled(address indexed operator);

    bool private _transferable;

    constructor () internal {
        _transferable = false;
    }

    modifier whenTransferable() {
        require(_transferable, "transferable must be true");
        _;
    }

    modifier whenNotTransferable() {
        require(!_transferable, "transferable must not be true");
        _;
    }

    function transferable() public view returns (bool) {
        return _transferable;
    }

    function enableTransfer() public onlyOwner whenNotTransferable {
        _transferable = true;
        emit TransferEnabled(msg.sender);
    }

    function disableTransfer() public onlyOwner whenTransferable {
        _transferable = false;
        emit TransferDisabled(msg.sender);
    }
}

// File: src/IMBTC.sol






contract IMBTC is EarnERC777, MinterRole, Pausable, SwitchTransferable {
    address internal _revenueAddress;

    constructor() EarnERC777("imBTC","The Tokenized Bitcoin",8) public {
    }

    function transfer(address recipient, uint256 amount) external whenNotPaused whenTransferable returns (bool) {
        return super._transfer(recipient, amount);
    }

    function send(address recipient, uint256 amount, bytes calldata data) external whenTransferable whenNotPaused {
        super._send(msg.sender, msg.sender, recipient, amount, data, "", true);
    }

    function burn(uint256 amount, bytes calldata data) external whenTransferable whenNotPaused {
        super._burn(msg.sender, msg.sender, amount, data, "");
    }

    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external whenTransferable whenNotPaused {
        require(isOperatorFor(msg.sender, sender), "ERC777: caller is not an operator for holder");
        super._send(msg.sender, sender, recipient, amount, data, operatorData, true);
    }

    function operatorBurn(address account, uint256 amount, bytes calldata data, bytes calldata operatorData)
        external whenTransferable whenNotPaused {
        require(isOperatorFor(msg.sender, account), "ERC777: caller is not an operator for holder");
        super._burn(msg.sender, account, amount, data, operatorData);
    }

    function mint(address recipient, uint256 amount,
            bytes calldata userData, bytes calldata operatorData) external onlyMinter whenNotPaused {
        super._mint(msg.sender, recipient, amount, userData, operatorData);
    }

    function transferFrom(address holder, address recipient, uint256 amount) external whenNotPaused returns (bool) {
        require(transferable(), "Token: transferable must be true");
        return super._transferFrom(holder, recipient, amount);
   }

   function setRevenueAddress(address account) external onlyOwner {
       require(_allowances[account][address(this)] > 0, "Token: the allowances of account must be large than zero");

       _revenueAddress = account;

       emit RevenueAddressSet(account);
   }

   function revenueAddress() external view returns (address) {
       return _revenueAddress;
   }

   function revenue() external view returns (uint256) {
       return _balanceOf(_revenueAddress);
   }

   event RevenueAddressSet(address indexed account);

   function distributeRevenue() external whenNotPaused {
       require(_revenueAddress != address(0), 'Token: revenue address must not be zero');

       _distributeRevenue(_revenueAddress);
   }
}