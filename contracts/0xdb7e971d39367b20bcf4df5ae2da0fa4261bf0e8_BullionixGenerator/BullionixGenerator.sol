/**
 *Submitted for verification at Etherscan.io on 2020-03-26
*/

pragma solidity ^0.5.0;

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
pragma solidity ^0.5.0;

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

pragma solidity ^0.5.0;

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
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;


/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the SafeMath
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

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
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * [EIP](https://eips.ethereum.org/EIPS/eip-165).
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others (`ERC165Checker`).
 *
 * For an implementation, see `ERC165`.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
pragma solidity ^0.5.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface DGXinterface {
  /// @dev read transfer configurations
/// @return {
///   "_base": "denominator for calculating transfer fees",
///   "_rate": "numerator for calculating transfer fees",
///   "_collector": "the ethereum address of the transfer fees collector",
///   "_no_transfer_fee": "true if transfer fees is turned off globally",
///   "_minimum_transfer_amount": "minimum amount of DGX that can be transferred"
/// }
function showTransferConfigs()
 external
  returns (uint256 _base, uint256 _rate, address _collector, bool _no_transfer_fee, uint256 _minimum_transfer_amount);
  /// @dev read the demurrage configurations
/// @return {
///   "_base": "denominator for calculating demurrage fees",
///   "_rate": "numerator for calculating demurrage fees",
///   "_collector": "ethereum address of the demurrage fees collector"
///   "_no_demurrage_fee": "true if demurrage fees is turned off globally"
/// }
function showDemurrageConfigs()
  external
  returns (uint256 _base, uint256 _rate, address _collector, bool _no_demurrage_fee);
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
     @dev Returns the user data for an account
     * Specifically calling this to get the last time of transfer to calculate demurrage fees
     * 
     *
     * Returns bool _exists,
     * Returns uint256 _raw_balance,
     * Returns uint256 _payment_date,
     * Returns bool _no_demurrage_fee,
     * Returns bool _no_recast_fee,
     * Returns bool _no_transfer_fee
     *
     * Emits a `Transfer` event.
     **/
function read_user(address _account)
        external
    returns (
        bool _exists,
        uint256 _raw_balance,
        uint256 _payment_date,
        bool _no_demurrage_fee,
        bool _no_recast_fee,
        bool _no_transfer_fee
    );

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
pragma solidity ^0.5.0;


/**
 * @dev Implementation of the `IERC165` interface.
 *
 * Contracts may inherit from this and call `_registerInterface` to declare
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
     * @dev See `IERC165.supportsInterface`.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See `IERC165.supportsInterface`.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}
pragma solidity ^0.5.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

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
     * NFT by either `approve` or `setApproveForAll`.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either `approve` or `setApproveForAll`.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}
pragma solidity ^0.5.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a `safeTransfer`. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}
pragma solidity ^0.5.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}

pragma solidity ^0.5.0;

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from token ID to owner
    mapping (uint256 => address) private _tokenOwner;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to number of owned token
    mapping (address => Counters.Counter) private _ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor () public {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }

    /**
     * @dev Gets the owner of the specified token ID.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }

    /**
     * @dev Approves another address to transfer the given token ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per token at a given time.
     * Can only be called by the token owner or an approved operator.
     * @param to address to be approved for the given token ID
     * @param tokenId uint256 ID of the token to be approved
     */
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf.
     * @param to operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner.
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address.
     * Usage of this method is discouraged, use `safeTransferFrom` whenever possible.
     * Requires the msg.sender to be the owner, approved, or operator.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether the specified token exists.
     * @param tokenId uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    /**
     * @dev Returns whether the given spender can transfer a given token ID.
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     * is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use _burn(uint256) instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to transferFrom, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal function to invoke `onERC721Received` on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * This function is deprecated.
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Private function to clear current approval of a given token ID.
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

pragma solidity ^0.5.0;


/**
 * @title ERC-721 Non-Fungible Token with optional enumeration extension logic
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Enumerable is ERC165, ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[]) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Constructor function.
     */
    constructor () public {
        // register the supported interface to conform to ERC721Enumerable via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev Gets the token ID at a given index of the tokens list of the requested owner.
     * @param owner address owning the tokens list to be accessed
     * @param index uint256 representing the index to be accessed of the requested tokens list
     * @return uint256 token ID at the given index of the tokens list owned by the requested address
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev Gets the total amount of tokens stored by the contract.
     * @return uint256 representing the total amount of tokens
     */
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev Gets the token ID at a given index of all the tokens in this contract
     * Reverts if the index is greater or equal to the total number of tokens.
     * @param index uint256 representing the index to be accessed of the tokens list
     * @return uint256 token ID at the given index of the tokens list
     */
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to transferFrom, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        super._transferFrom(from, to, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to address the beneficiary that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);

        _addTokenToAllTokensEnumeration(tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use _burn(uint256) instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        _removeTokenFromOwnerEnumeration(owner, tokenId);
        // Since tokenId will be deleted, we can clear its slot in _ownedTokensIndex to trigger a gas refund
        _ownedTokensIndex[tokenId] = 0;

        _removeTokenFromAllTokensEnumeration(tokenId);
    }

    /**
     * @dev Gets the list of token IDs of the requested owner.
     * @param owner address owning the tokens
     * @return uint256[] List of token IDs owned by the requested address
     */
    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
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
     * while the token is not assigned a new owner, the _ownedTokensIndex mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        _ownedTokens[from].length--;

        // Note that _ownedTokensIndex[tokenId] hasn't been cleared: it still points to the old slot (now occupied by
        // lastTokenId, or just over the end of the array if the token was the last one).
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        _allTokens.length--;
        _allTokensIndex[tokenId] = 0;
    }
}

pragma solidity ^0.5.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
pragma solidity ^0.5.0;


contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /**
     * @dev Constructor function
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    /**
     * @dev Gets the token name.
     * @return string representing the token name
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Gets the token symbol.
     * @return string representing the token symbol
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns an URI for a given token ID.
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to set its URI
     * @param uri string URI to assign
     */
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = uri;
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use _burn(uint256) instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned by the msg.sender
     */
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

pragma solidity ^0.5.0;


/**
 * @title Full ERC721 Token
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
    constructor (string memory name, string memory symbol) public ERC721Metadata(name, symbol) {
        // solhint-disable-previous-line no-empty-blocks
    }
}
pragma solidity ^0.5.0;



/**
 * @title ERC721MetadataMintable
 * @dev ERC721 minting logic with metadata.
 */
contract ERC721MetadataMintable is ERC721, ERC721Metadata {
    /**
     * @dev Function to mint tokens.
     * @param to The address that will receive the minted tokens.
     * @param tokenId The token id to mint.
     * @param tokenURI The token URI of the minted token.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintWithTokenURI(address to, uint256 tokenId, string memory tokenURI) internal  returns (bool) {
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        return true;
    }
}

pragma solidity ^0.5.0;


/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
contract ERC721Burnable is ERC721 {
    /**
     * @dev Burns a specific ERC721 token.
     * @param tokenId uint256 id of the ERC721 token to be burned.
     */
    function burn(uint256 tokenId) internal {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}
pragma solidity >=0.4.22 <0.6.0;



//Deployed using 0.5.0.commit1d4f56
//optimization enabled
//kovan deployed at - 0xf7E80D70963cc97566BA25E5A22F24837d59CE4e
contract BullionixGenerator is
    ERC721Enumerable,
    ERC721MetadataMintable,
    ERC721Burnable,
    Ownable
{
    modifier isActive {
        require(isOnline == true);
        _;
    }
    using SafeMath for uint256;
    /*
* @dev Beginning state and init values
**/
    DGXinterface dgx;
    DGXinterface dgxStorage;
    DGXinterface dgxToken;
    bool public isOnline = false;
    /*
Kovan KDGX token contract - 0xAEd4fc9663420eC8a6c892065BBA49c935581Dce
Kovan Storage contract - 0x3c5E7435190ecd13C88F3600Ca317A1A5FdD2Ae6
Kovan TokenInformation - 0x2651586330d05411e6bcecF9c4ff48341E6d02D5


Mainnet (storage) = 0xc672ec9cf3be7ad06be4c5650812aec23bbfb7e1
Mainnet (token)    = 0x4f3afec4e5a3f2a6a1a411def7d7dfe50ee057bf
Mainnet (token information) = 0xbb246ee3fa95b88b3b55a796346313738c6e0150
Mainnet storage contract - 0xC672EC9CF3Be7Ad06Be4C5650812aEc23BBfB7E1
*/
    address payable public DGXTokenContract = 0x4f3AfEC4E5a3F2A6a1A411DEF7D7dFe50eE057bF;
    address payable public DGXContract = 0xBB246ee3FA95b88B3B55A796346313738c6E0150; //To be filled in
    address payable public DGXTokenStorage = 0xC672EC9CF3Be7Ad06Be4C5650812aEc23BBfB7E1; //To be filled in
    string constant name = "Bullionix";
    string constant title = "Bullionix"; //To be filled in
    string constant symbol = "BLX"; //To be filled in
    string constant version = "Bullionix v0.2";
    mapping(uint256 => uint256) public StakedValue;
    mapping(uint256 => seriesData) public seriesToTokenId;
    uint256 public totalSeries = 0;
    uint256 public totalFeesCollected = 0;
    struct seriesData {
        string url;
        uint256 numberInSeries;
        uint256 DGXcost;
        uint256 fee;
        bool alive;
    }
    /*
* @dev Events
* @dev Events to read when things happen
**/
    event NewSeriesMade(string indexed url, uint256 indexed numberToMint);
    event Staked(address indexed _sender, uint256 _amount, uint256 tokenStaked);
    event Burned(address indexed _sender, uint256 _amount, uint256 _tokenId);
    event Withdrawal(address indexed _receiver, uint256 indexed _amount);
    event TransferFee(uint256 indexed transferFee);
    event DemurrageFee(uint256 indexed demurrageFee);
    event CheckFees(
        uint256 indexed feeValue,
        uint256 indexed stakedValue,
        uint256 indexed _totalWithdrawal
    );

    /*
* @dev Constructor() and storge init
* @dev Sets state
**/
    constructor() public ERC721Metadata(name, symbol) {
        if (
            address(DGXContract) != address(0x0) &&
            address(DGXTokenStorage) != address(0x0)
        ) {
            isOnline = true;
            dgx = DGXinterface(DGXContract);
            dgxStorage = DGXinterface(DGXTokenStorage);
            dgxToken = DGXinterface(DGXTokenContract);
        }
    }

    /* 
* @dev changes online status to disable contract, must be current owner
*
**/
    function toggleOnline() external onlyOwner {
        isOnline = !isOnline;
    }
    /**
     * @dev Create a new series of NFTs.
     * @param _url location of metadata on backend server. Will be tacked onto the end of set url using returnURL().
     * @param _numberToMint  The token number for this series. 10 would make 10 tokens avaliable 
     * @param _DGXcost The amount of DGX to send
     * @param _fee Bullionix fee for generation
     * @return A boolean that indicates if the operation was successful.
     */
    function createNewSeries(
        string memory _url,
        uint256 _numberToMint,
        uint256 _DGXcost,
        uint256 _fee
    ) public onlyOwner isActive returns (bool _success) {
        //takes input from admin to create a new nft series. Will have to define how many tokens to make, how much DGX they cost, and the url from s3.
        require(msg.sender == owner(), "Only Owner"); //optional as onlyOwner Modifier is used
        uint256 total = totalSeries;
        uint256 tempNumber = _numberToMint.add(totalSeries);
        for (uint256 i = total; i < tempNumber; i++) {
            seriesToTokenId[i].url = _url;
            seriesToTokenId[i].numberInSeries = _numberToMint;
            seriesToTokenId[i].DGXcost = _DGXcost;
            seriesToTokenId[i].fee = _fee;
            totalSeries = totalSeries.add(1);
        }

        emit NewSeriesMade(_url, _numberToMint);
        return true;
    }

    /* 
* @dev Stake to series and mint tokens 
*
**/
    function stake(uint256 _tokenToBuy) public payable isActive returns (bool) {
        //takes input from admin to create a new nft series. Will have to define how many tokens to make, how much DGX they cost, and the url from s3.
        require(
            seriesToTokenId[_tokenToBuy].fee >= 0 &&
                StakedValue[_tokenToBuy] == 0,
            "Can't stake to this token!"
        );
        uint256 amountRequired = (
            (
                seriesToTokenId[_tokenToBuy].DGXcost.add(
                    seriesToTokenId[_tokenToBuy].fee
                )
            )
        );
        uint256 transferFee = fetchTransferFee(amountRequired);
        uint256 adminFees = seriesToTokenId[_tokenToBuy].fee.sub(transferFee);
        totalFeesCollected = totalFeesCollected.add(adminFees);
        uint256 demurageFee = fetchDemurrageFee(msg.sender);
        //add demurage fee to transfer fee
        uint256 totalFees = transferFee.add(demurageFee);
        amountRequired = amountRequired.sub(totalFees);
        //require transfer to contract succeeds
        require(
            _checkAllowance(msg.sender, amountRequired),
            "Not enough allowance"
        );
        require(
            _transferFromDGX(msg.sender, amountRequired),
            "Transfer DGX failed"
        );
        //get url
        string memory fullURL = returnURL(_tokenToBuy);

        emit CheckFees(
            totalFees,
            amountRequired,
            (
                (
                    seriesToTokenId[_tokenToBuy].DGXcost.add(
                        seriesToTokenId[_tokenToBuy].fee
                    )
                )
            )
        );
        require(amountRequired > totalFees, "Math invalid");
        require(
            mintWithTokenURI(msg.sender, _tokenToBuy, fullURL),
            "Minting NFT failed"
        );
        //staked value is set to DGXCost sent by user minus the total fees
        StakedValue[_tokenToBuy] = amountRequired;
        emit Staked(msg.sender, StakedValue[_tokenToBuy], _tokenToBuy);
        seriesToTokenId[_tokenToBuy].alive = true;
        return true;
    }

    /**
     * @dev Burns a specific ERC721 token and refunds user the DGX on the NFT
     * @param _tokenId uint256 id of the ERC721 token to be burned.
     */

    //TODO: Finalize this function and transfer the DGX back to msg.sender for burning their nft
    function burnStake(uint256 _tokenId) public payable returns (bool) {
        //solhint-disable-next-line max-line-length
        //check token is staked

        require(
            StakedValue[_tokenId] > 0 && seriesToTokenId[_tokenId].alive,
            "NFT not burnable yet"
        );
        //check that you are owner of token
        require(
            _isApprovedOrOwner(msg.sender, _tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        //check balance of smart contract
        //get fees to calculate
        uint256 transferFee = fetchTransferFee(StakedValue[_tokenId]);
        uint256 demurrageFee = fetchDemurrageFee(address(this));
        //total fees
        uint256 feeValue = transferFee.add(demurrageFee);
        require(
            feeValue < StakedValue[_tokenId],
            "Fee is more than StakedValue"
        );
        uint256 UserWithdrawal = StakedValue[_tokenId].sub(feeValue);
        UserWithdrawal = UserWithdrawal.sub((seriesToTokenId[_tokenId].fee));
        require(_checkBalance() >= UserWithdrawal, "Balance check failed");
        seriesToTokenId[_tokenId].alive = false;
        //transfer 721 to 0x000
        _burn(_tokenId);
        //transfer dgx from contract to msg.sender
        require(dgxToken.transfer(msg.sender, UserWithdrawal));
        emit Burned(msg.sender, UserWithdrawal, _tokenId);
        return true;
    }

    function checkFeesForBurn(uint256 _tokenId)
        public
        payable
        returns (uint256)
    {
        uint256 transferFee = fetchTransferFee(
            (
                seriesToTokenId[_tokenId].DGXcost.add(
                    seriesToTokenId[_tokenId].fee
                )
            )
        );
        uint256 demurrageFee = fetchDemurrageFee(address(this));
        //total fees
        uint256 feeValue = transferFee.add(demurrageFee);

        uint256 UserWithdrawal = (
            (
                seriesToTokenId[_tokenId].DGXcost.add(
                    seriesToTokenId[_tokenId].fee
                )
            )
                .sub(feeValue)
        );
        UserWithdrawal = UserWithdrawal.sub((seriesToTokenId[_tokenId].fee));
        emit CheckFees(
            feeValue,
            (
                seriesToTokenId[_tokenId].DGXcost.add(
                    seriesToTokenId[_tokenId].fee
                )
            ),
            UserWithdrawal
        );
    }
    /**
     * @dev Withdrawals DGX from the balance collected via fees only Owner.
     */
    function withdrawal() public onlyOwner returns (bool) {
        require(isOnline == false);
        uint256 temp = _checkBalance(); //calls checkBalance which will revert if no balance, if balance pass it into transfer as amount to withdrawal MAX
        require(
            temp >= totalFeesCollected,
            "Not enough balance to withdrawal the fees collected"
        );
        require(dgxToken.transfer(msg.sender, totalFeesCollected));
        emit Withdrawal(msg.sender, totalFeesCollected);
        totalFeesCollected = 0;
        return true;
    }
    function _checkBalance() internal view returns (uint256) {
        uint256 tempBalance = dgxToken.balanceOf(address(this)); //checking balance on DGX contract
        require(tempBalance > 0, "Revert: Balance is 0!"); //do I even have a balance? Lets see. If no balance revert.
        return tempBalance; //here is your balance! Fresh off the stove.
    }
    function _checkAllowance(address sender, uint256 amountNeeded)
        internal
        view
        returns (bool)
    {
        uint256 tempBalance = dgxToken.allowance(sender, address(this)); //checking balance on DGX contract
        require(tempBalance >= amountNeeded, "Revert: Balance is 0!"); //do I even have a balance? Lets see. If no balance revert.
        return true; //here is your balance! Fresh off the stove.
    }
    /*
  * @dev Gets the total amount of tokens owned by the sender
  * @return uint[] with the id of each token owned
  */
    function viewYourTokens()
        external
        view
        returns (uint256[] memory _yourTokens)
    {
        return super._tokensOfOwner(msg.sender);
    }
    function setDGXStorage(address payable newAddress)
        external
        onlyOwner
        returns (bool)
    {
        DGXTokenStorage = newAddress;
        dgxStorage = DGXinterface(DGXTokenStorage);
        return true;
    }
    function setDGXContract(address payable newAddress)
        external
        onlyOwner
        returns (bool)
    {
        DGXContract = newAddress;
        dgx = DGXinterface(DGXContract);
        return true;
    }
    function setDGXTokenContract(address payable newAddress)
        external
        onlyOwner
        returns (bool)
    {
        DGXContract = newAddress;
        dgxToken = DGXinterface(DGXContract);
        return true;
    }
    // Internals
    /*
  * TransferForm called after user has approved DGX to be spent by this contract.
  * If transferform fails, return false 
  * @dev returns the entire tokenURI 
  * @return uint256 with the id of the token
  */

    /*
  * @dev returns the entire tokenURI 
  * @return uint256 with the id of the token
  */
    function returnURL(uint256 _tokenId)
        internal
        view
        returns (string memory _URL)
    {
        require(
            checkURL(_tokenId),
            "ERC721: approved query for nonexistent token"
        ); //Does this token exist? Lets see.
        string memory uri = seriesToTokenId[_tokenId].url;
        return string(abi.encodePacked("https://app.bullionix.io/metadata/", uri)); //Here is your URL!
    }

    /*
  * @dev Returns the URL - internal 
  * @return URL of token with full website attached
  */
    function checkURL(uint256 _tokenId) internal view returns (bool) {
        string memory temp = seriesToTokenId[_tokenId].url;
        bytes memory tempEmptyStringTest = bytes(temp);
        require(tempEmptyStringTest.length >= 1, temp);
        return true;
    }
    function _transferFromDGX(address _owner, uint256 _amount)
        internal
        returns (bool)
    {
        require(dgxToken.transferFrom(_owner, address(this), _amount));
        return true;
    }

    function fetchTransferFee(uint256 _amountToBeTransferred)
        internal
        returns (uint256 rate)
    {
        (uint256 _base, uint256 _rate, address _collector, bool _no_transfer_fee, uint256 _minimum_transfer_amount) = dgx
            .showTransferConfigs();
        if (_no_transfer_fee) {
            return 0;
        }
        emit TransferFee(_rate.mul(_amountToBeTransferred).div(_base));
        return _rate.mul(_amountToBeTransferred).div(_base);

    }

    function fetchLastTransfer(address _user)
        internal
        returns (uint256 _payment_date)
    {
        //gets the timestamp from the DGX contract to help calculate the fees
        (bool _exists, uint256 _raw_balance, uint256 _payment_date, bool _no_demurrage_fee, bool _no_recast_fee, bool _no_transfer_fee) = dgxStorage
            .read_user(_user);
        require(
            _payment_date >= 0 && _payment_date < block.timestamp,
            "Last payment timestamp is invalid"
        );

        return _payment_date;

    }

    function fetchDemurrageFee(address _sender)
        internal
        returns (uint256 rate)
    {
        //calculate the fee taken by DGX using (rate/base)*(timestamp_now - last_payment) / number_of_seconds_in_a_day = demurrage fee
        (uint256 _base, uint256 _rate, address _collector, bool _no_demurrage_fee) = dgx
            .showDemurrageConfigs();
        if (_no_demurrage_fee) return 0;
        //get last transfer date
        uint256 last_timestamp = fetchLastTransfer(_sender);
        uint256 daysSinceTransfer = block.timestamp.sub(last_timestamp);

        //calculate total fees
        //get total demurage fee by taking fee*days
        uint256 totalFees = (
            (_rate * 10**8).div(_base).mul(daysSinceTransfer).div(86400)
        );
        emit DemurrageFee(totalFees);
        return totalFees;

    }
    function() external payable {
        revert("Please call a function");
    }
}