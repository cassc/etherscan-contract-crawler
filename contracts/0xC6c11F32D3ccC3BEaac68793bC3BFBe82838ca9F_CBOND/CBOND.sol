/**
 *Submitted for verification at Etherscan.io on 2020-12-03
*/

/*                           HTTPS://SYNCBOND.COM                         HTTPS://APP.SYNCBOND.COM
███████╗██╗░░░██╗███╗░░░██╗░██████╗░░░░██████╗░░██████╗░██╗░░░░██╗███████╗██████╗░███████╗██████╗░
██╔════╝╚██╗░██╔╝████╗░░██║██╔════╝░░░░██╔══██╗██╔═══██╗██║░░░░██║██╔════╝██╔══██╗██╔════╝██╔══██╗
███████╗░╚████╔╝░██╔██╗░██║██║░░░░░░░░░██████╔╝██║░░░██║██║░█╗░██║█████╗░░██████╔╝█████╗░░██║░░██║
╚════██║░░╚██╔╝░░██║╚██╗██║██║░░░░░░░░░██╔═══╝░██║░░░██║██║███╗██║██╔══╝░░██╔══██╗██╔══╝░░██║░░██║
███████║░░░██║░░░██║░╚████║╚██████╗░░░░██║░░░░░╚██████╔╝╚███╔███╔╝███████╗██║░░██║███████╗██████╔╝
╚══════╝░░░╚═╝░░░╚═╝░░╚═══╝░╚═════╝░░░░╚═╝░░░░░░╚═════╝░░╚══╝╚══╝░╚══════╝╚═╝░░╚═╝╚══════╝╚═════╝░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░██████╗██████╗░██╗░░░██╗██████╗░████████╗░██████╗░██████╗░░██████╗░███╗░░░██╗██████╗░███████╗░░░░
██╔════╝██╔══██╗╚██╗░██╔╝██╔══██╗╚══██╔══╝██╔═══██╗██╔══██╗██╔═══██╗████╗░░██║██╔══██╗██╔════╝░░░░
██║░░░░░██████╔╝░╚████╔╝░██████╔╝░░░██║░░░██║░░░██║██████╔╝██║░░░██║██╔██╗░██║██║░░██║███████╗░░░░
██║░░░░░██╔══██╗░░╚██╔╝░░██╔═══╝░░░░██║░░░██║░░░██║██╔══██╗██║░░░██║██║╚██╗██║██║░░██║╚════██║░░░░
╚██████╗██║░░██║░░░██║░░░██║░░░░░░░░██║░░░╚██████╔╝██████╔╝╚██████╔╝██║░╚████║██████╔╝███████║░░░░
░╚═════╝╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░░░░╚═╝░░░░╚═════╝░╚═════╝░░╚═════╝░╚═╝░░╚═══╝╚═════╝░╚══════╝░░░░
*/
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



interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes calldata data) external;
}




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
     *
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
     *
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
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}




/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}


library SquareRoot {
  function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}


/*
  https://ethereum.stackexchange.com/a/8447
*/
library AddressStrings {
  function toString(address x) internal pure returns (string memory) {
      bytes memory s = new bytes(40);
      for (uint i = 0; i < 20; i++) {
          byte b = byte(uint8(uint(x) / (2**(8*(19 - i)))));
          byte hi = byte(uint8(b) / 16);
          byte lo = byte(uint8(b) - 16 * uint8(hi));
          s[2*i] = char(hi);
          s[2*i+1] = char(lo);
      }
      return string(s);
  }

  function char(byte b) internal pure returns (byte c) {
      if (uint8(b) < 10) return byte(uint8(b) + 0x30);
      else return byte(uint8(b) + 0x57);
  }
}


interface Oracle{
  function liquidityValues(address token) external view returns(uint);//returns usd value of token (consider usd an 18 decimal stablecoin), or 0 if not listed
  function syncValue() external view returns(uint);//returns usd value of SYNC
}














/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transfered from `from` to `to`.
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function getApproved(uint256 tokenId) external view returns (address operator);

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
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}







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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}





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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);
}







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
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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





/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}





/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint256(value)));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key), errorMessage)));
    }
}



/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mecanisms to perform token transfer, such as signature-based.
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
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
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
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
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
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
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}






/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}











contract Sync is IERC20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private balances;
  mapping (address => mapping (address => uint256)) private allowed;
  string public constant name  = "SYNC";
  string public constant symbol = "SYNC";
  uint8 public constant decimals = 18;
  uint256 _totalSupply = 16000000 * (10 ** 18); // 16 million supply

  mapping (address => bool) public mintContracts;

  modifier isMintContract() {
    require(mintContracts[msg.sender],"calling address is not allowed to mint");
    _;
  }

  constructor() public Ownable(){
    balances[msg.sender] = _totalSupply;
    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  function setMintAccess(address account, bool canMint) public onlyOwner {
    mintContracts[account]=canMint;
  }

  function _mint(address account, uint256 amount) public isMintContract {
    require(account != address(0), "ERC20: mint to the zero address");
    _totalSupply = _totalSupply.add(amount);
    balances[account] = balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address user) public view override returns (uint256) {
    return balances[user];
  }

  function allowance(address user, address spender) public view override returns (uint256) {
    return allowed[user][spender];
  }

  function transfer(address to, uint256 value) public override returns (bool) {
    require(value <= balances[msg.sender],"insufficient balance");
    require(to != address(0),"cannot send to zero address");

    balances[msg.sender] = balances[msg.sender].sub(value);
    balances[to] = balances[to].add(value);

    emit Transfer(msg.sender, to, value);
    return true;
  }

  function approve(address spender, uint256 value) public override returns (bool) {
    require(spender != address(0),"cannot approve the zero address");
    allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function approveAndCall(address spender, uint256 tokens, bytes calldata data) external returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

  function transferFrom(address from, address to, uint256 value) public override returns (bool) {
    require(value <= balances[from],"insufficient balance");
    require(value <= allowed[from][msg.sender],"insufficient allowance");
    require(to != address(0),"cannot send to the zero address");

    balances[from] = balances[from].sub(value);
    balances[to] = balances[to].add(value);

    allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, value);
    return true;
  }

  function burn(uint256 amount) external {
    require(amount != 0,"must burn more than zero");
    require(amount <= balances[msg.sender],"insufficient balance");
    _totalSupply = _totalSupply.sub(amount);
    balances[msg.sender] = balances[msg.sender].sub(amount);
    emit Transfer(msg.sender, address(0), amount);
  }

}




contract CBOND is ERC721, Ownable {
  using SafeMath for uint256;
  using Strings for uint256;
  using AddressStrings for address;

  event Created(address token,uint256 syncAmount,uint256 tokenAmount,uint256 syncPrice,uint256 tokenPrice,uint256 tokenId);
  event Matured(address token,uint256 syncReturned,uint256 tokenAmount,uint256 tokenId);
  event DivsPaid(address token,uint256 syncReturned,uint256 tokenId);

  //read only counter values
  uint256 public totalCBONDS=0;//Total number of Cbonds created.
  uint256 public totalQuarterlyCBONDS=0;//Total number of quarterly Cbonds created.
  uint256 public totalCBONDSCashedout=0;//Total number of Cbonds that have been matured.
  uint256 public totalSYNCLocked=0;//Total amount of Sync locked in Cbonds.
  mapping(address => uint256) public totalLiquidityLockedByPair;//Total amount of tokens locked in Cbonds of the given liquidity token.

  //values contained in individual CBONDs, by token id
  mapping(uint256 => address) public lAddrById;//The address of the liquidity token used to create the given Cbond.
  mapping(uint256 => uint256) public lTokenPriceById;//The relative price of the liquidity token at the time the given Cbond was created.
  mapping(uint256 => uint256) public lTokenAmountById;//The amount of liquidity tokens initially deposited into the given Cbond.
  mapping(uint256 => uint256) public syncPriceById;//The relative price of Sync at the time the given Cbond was created.
  mapping(uint256 => uint256) public syncAmountById;//The amount of Sync initially deposited into the given Cbond.
  mapping(uint256 => uint256) public syncInterestById;//The amount of Sync interest on the initially deposited Sync awarded by the given Cbond. For quarterly Cbonds, this variable will represent only the interest of a single quarter.
  mapping(uint256 => uint256) public syncRewardedOnMaturity;//The amount of Sync returned to the user on maturation of the given Cbond.
  mapping(uint256 => uint256) public timestampById;//The time the given Cbond was created.
  mapping(uint256 => bool) public gradualDivsById;//Whether the given Cbond awards dividends quarterly.
  mapping(uint256 => uint256) public lastDivsCashoutById;//For Quarterly Cbonds, this variable represents the last cashout timestamp.
  mapping(uint256 => uint256) public totalDivsCashoutById;//For Quarterly Cbonds, the total dividends cashed out to date. Frontend use only, not used for calculations within the contract.
  mapping(uint256 => uint256) public termLengthById;//Length of term in seconds for the given Cbond.

  //constant and pseudo-constant (never changed after constructor) values
  uint256 constant public PERCENTAGE_PRECISION=10000;//Divide percentages by this to get the real multiplier.
  uint256 constant public INCENTIVE_MAX_PERCENT=220;//2.2%, the maximum value the liquidity incentive rate can be.
  uint256 constant public MAX_SYNC_GLOBAL=100000 * (10 ** 18);//Maximum Sync in a Cbond. Cbonds with higher amounts of Sync cannot be created.
  uint256 constant public QUARTER_LENGTH=90 days;//The length of a quarter, the interval of time between quarterly dividends.
  uint256 public STARTING_TIME=block.timestamp;//The time the contract was deployed.
  uint256 constant public BASE_INTEREST_RATE_START=220;//2.2%, starting value for base interest rate.
  uint256 constant public MINIMUM_BASE_INTEREST_RATE=10;//0.1%, the minimum value base interest rate can be.
  uint256 constant public MAXIMUM_BASE_INTEREST_RATE=4500;//45%, the maximum value base interest rate can be.
  uint256[] public LUCKY_EXTRAS=[500,1000];//Bonus interest awarded to user on creating lucky and extra lucky Cbonds.
  uint256 public YEAR_LENGTH=360 days;//Time length of approximately 1 year
  uint256[] public TERM_DURATIONS=[90 days,180 days,360 days,720 days,1080 days];//Possible term durations for Cbonds, index values corresponding to the following variables:
  uint256[] public DURATION_MODIFIERS=[825,1650,3300,6600,10000];//The percentage values used as duration modifiers for the given term lengths.
  uint256[] public DURATION_CALC_LOOPS=[0,0,3,7,11];//Number of loops for the duration rate formula approximation function, for the given term duration.
  mapping(uint256 => uint256) public INDEX_BY_DURATION;//Mapping of term durations to index values, as relates to the above variables.
  uint256 public RISK_FACTOR = 5;//Constant used in duration rate calculation

  //Index variables for tracking
  uint256 public lastDaySyncSupplyUpdated=0;//The previously recorded day on which the supply of Sync was last recorded into syncSupplyByDay.
  uint256 public currentDaySyncSupplyUpdated=0;//The day on which the supply of Sync was last recorded into syncSupplyByDay.
  mapping(address => mapping(uint256 => uint256)) public cbondsHeldByUser;//Mapping of cbond ids held by user. The second mapping is a list, length given by cbondsHeldByUserCursor.
  mapping(address => uint256) public cbondsHeldByUserCursor;//The number of Cbonds held by the given user.
  mapping(address => uint256) public lastDayTokenSupplyUpdated;//The previously recorded day on which the supply of the given token was last recorded into liqTokenTotalsByDay.
  mapping(address => uint256) public currentDayTokenSupplyUpdated;//The day on which the supply of the given token was last recorded into liqTokenTotalsByDay.
  mapping(uint256 => uint256) public syncSupplyByDay;//The recorded total supply of the Sync token for the given day. This value is written once and thereafter cannot be changed for a given day.
  mapping(uint256 => uint256) public interestRateByDay;//The recorded base interest rate for the given day. This value is written once and thereafter cannot be changed for a given day, and is recorded simultaneously with syncSupplyByDay.
  mapping(address => mapping(uint256 => uint256)) public liqTokenTotalsByDay;//The recorded total for the given liquidity token on the given day. This value is written once and thereafter cannot be changed for a given token/day.
  uint256 public _currentTokenId = 0;//Variable for tracking next NFT identifier.

  //Read only tracking variables (not used within the smart contract)
  mapping(uint256 => uint256) public cbondsMaturingByDay;//Mapping of days to number of cbonds maturing that day.

  //admin adjustable values
  mapping(address => bool) public tokenAccepted;//Whether a given liquidity token has been approved for use by admins. Cbonds can only be created using tokens listed here.
  uint256 public syncMinimum = 25 * (10 ** 18);//Cbonds cannot be created unless at least this amount of Sync is being included in them.
  bool public luckyEnabled = true;//Whether it is possible to create Lucky Cbonds

  //external contracts
  Oracle public priceChecker;//Used to determine the ratio in price between Sync and a given liquidity token. The value returned should not significantly affect user incentives and does not need to be guaranteed not to be exploitable by the user. Contract can be replaced by admin.
  Sync syncToken;//The Sync token contract. Sync is contained in every Cbond and is minted to provide interest on Cbonds.

  constructor(Oracle o,Sync s) public Ownable() ERC721("CBOND","CBOND"){
    priceChecker=o;
    syncToken=s;
    syncSupplyByDay[0]=syncToken.totalSupply();
    interestRateByDay[0]=BASE_INTEREST_RATE_START;
    _setBaseURI("api.syncbond.com");
    for(uint256 i=0;i<TERM_DURATIONS.length;i++){
      INDEX_BY_DURATION[TERM_DURATIONS[i]]=i;
    }
  }

  /*
    Admin functions
  */

  /*
    Admin function to set the base URI for metadata access.
  */
  function setBaseURI(string calldata baseURI_) external onlyOwner{
    _setBaseURI(baseURI_);
  }

  /*
    Admin function to set liquidity tokens which may be used to create Cbonds.
  */
  function setLiquidityTokenAccepted(address token,bool accepted) external onlyOwner{
    tokenAccepted[token]=accepted;
  }

  /*
    Admin function to set liquidity tokens which may be used to create Cbonds.
  */
  function setLiquidityTokenAcceptedMulti(address[] calldata tokens,bool accepted) external onlyOwner{
    for(uint256 i=0;i<tokens.length;i++){
      tokenAccepted[tokens[i]]=accepted;
    }
  }

  /*
    Admin function to reduce the minimum amount of Sync that can be used to create a Cbond.
  */
  function setSyncMinimum(uint256 newMinimum) public onlyOwner{
    require(newMinimum<syncMinimum,"increasing minimum sync required is not permitted");
    syncMinimum=newMinimum;
  }

  /*
    Admin function to change the price oracle.
  */
  function setPriceOracle(Oracle o) external onlyOwner{
    priceChecker=o;
  }

  /*
    Admin function to toggle on/off the lucky bonus.
  */
  function toggleLuckyBonus(bool enabled) external onlyOwner{
    luckyEnabled=enabled;
  }

  /*
    Admin function for updating the daily Sync total supply and token supply for various tokens, for use in case of low activity.
  */
  function recordSyncAndTokens(address[] calldata tokens) external onlyOwner{
    recordSyncSupply();
    for(uint256 i=0;i<tokens.length;i++){
      recordTokenSupply(tokens[i]);
    }
  }

  /*
    Retrieves available dividends for the given token. Dividends accrue every 3 months.
  */
  function cashOutDivs(uint256 tokenId) external{
    require(msg.sender==ownerOf(tokenId),"only token owner can call this");
    require(gradualDivsById[tokenId],"must be in quarterly dividends mode");

    //record current Sync supply and liquidity token supply for the day if needed
    recordSyncSupply();
    recordTokenSupply(lAddrById[tokenId]);

    //reward user with appropriate amount. If none is due it will provide an amount of 0 tokens.
    uint256 divs=dividendsOf(tokenId);
    syncToken._mint(msg.sender,divs);

    //register the timestamp of this transaction so future div payouts can be accurately calculated
    lastDivsCashoutById[tokenId]=block.timestamp;

    //update read variables
    totalDivsCashoutById[tokenId]=totalDivsCashoutById[tokenId].add(divs);

    emit DivsPaid(lAddrById[tokenId],divs,tokenId);
  }

  /*
    Returns liquidity tokens, mints Sync to pay back initial amount plus rewards.
  */
  function matureCBOND(uint256 tokenId) public{
    require(msg.sender==ownerOf(tokenId),"only token owner can call this");
    require(block.timestamp>termLengthById[tokenId].add(timestampById[tokenId]),"cbond term not yet completed");

    //record current Sync supply and liquidity token supply for the day if needed
    recordSyncSupply();
    recordTokenSupply(lAddrById[tokenId]);

    //amount of sync provided to user is initially deposited amount plus interest
    uint256 syncRetrieved=syncRewardedOnMaturity[tokenId];

    //provide user with their Sync tokens and their initially deposited liquidity tokens
    uint256 beforeMint=syncToken.balanceOf(msg.sender);
    syncToken._mint(msg.sender,syncRetrieved);
    require(IERC20(lAddrById[tokenId]).transfer(msg.sender,lTokenAmountById[tokenId]),"transfer must succeed");

    //update read only counter
    totalCBONDSCashedout=totalCBONDSCashedout.add(1);
    emit Matured(lAddrById[tokenId],syncRetrieved,lTokenAmountById[tokenId],tokenId);

    //burn the nft
    _burn(tokenId);
  }

  /*
    Public function for creating a new Cbond.
  */
  function createCBOND(address liquidityToken,uint256 amount,uint256 syncMaximum,uint256 secondsInTerm,bool gradualDivs) external returns(uint256){
    return _createCBOND(liquidityToken,amount,syncMaximum,secondsInTerm,gradualDivs,msg.sender);
  }

  /*
    Function for creating a new Cbond. User specifies a liquidity token and an amount, this is transferred from their account to this contract, along with a corresponding amount of Sync (transaction reverts if this is greater than the user provided maximum at the time of execution). A permitted term length is also provided, and whether the Cbond should provide gradual divs (Quarterly variety Cbond).
  */
  function _createCBOND(address liquidityToken,uint256 amount,uint256 syncMaximum,uint256 secondsInTerm,bool gradualDivs,address sender) private returns(uint256){
    require(tokenAccepted[liquidityToken],"liquidity token must be on the list of approved tokens");

    //record current Sync supply and liquidity token supply for the day if needed
    recordSyncSupply();
    recordTokenSupply(liquidityToken);

    //determine amount of Sync required, given the amount of liquidity tokens specified, and transfer that amount from the user
    uint256 liquidityValue=priceChecker.liquidityValues(liquidityToken);
    uint256 syncValue=priceChecker.syncValue();
    //Since syncRequired is the exact amount of Sync that will be transferred from the user, integer division truncations propagating to other values derived from this one is the correct behavior.
    uint256 syncRequired=liquidityValue.mul(amount).div(syncValue);
    require(syncRequired>=syncMinimum,"input tokens too few, sync transferred must be above the minimum");
    require(syncRequired<=syncMaximum,"price changed too much since transaction submitted");
    require(syncRequired<=MAX_SYNC_GLOBAL,"CBOND amount too large");
    syncToken.transferFrom(sender,address(this),syncRequired);
    require(IERC20(liquidityToken).transferFrom(sender,address(this),amount),"transfer must succeed");

    //burn sync tokens provided
    syncToken.burn(syncRequired);

    //get the token id of the new NFT
    uint256 tokenId=_getNextTokenId();

    //set all nft variables
    lAddrById[tokenId]=liquidityToken;
    syncPriceById[tokenId]=syncValue;
    syncAmountById[tokenId]=syncRequired;
    lTokenPriceById[tokenId]=liquidityValue;
    lTokenAmountById[tokenId]=amount;
    timestampById[tokenId]=block.timestamp;
    lastDivsCashoutById[tokenId]=block.timestamp;
    gradualDivsById[tokenId]=gradualDivs;
    termLengthById[tokenId]=secondsInTerm;

    //set the interest rate and final maturity withdraw amount
    setInterestRate(tokenId,syncRequired,liquidityToken,secondsInTerm,gradualDivs);

    //update global counters
    cbondsMaturingByDay[getDay(block.timestamp.add(secondsInTerm))]=cbondsMaturingByDay[getDay(block.timestamp.add(secondsInTerm))].add(1);
    cbondsHeldByUser[sender][cbondsHeldByUserCursor[sender]]=tokenId;
    cbondsHeldByUserCursor[sender]=cbondsHeldByUserCursor[sender].add(1);
    totalCBONDS=totalCBONDS.add(1);
    totalSYNCLocked=totalSYNCLocked.add(syncRequired);
    totalLiquidityLockedByPair[liquidityToken]=totalLiquidityLockedByPair[liquidityToken].add(amount);

    //create NFT
    _safeMint(sender,tokenId);
    _incrementTokenId();

    //submit event
     emit Created(liquidityToken,syncRequired,amount,syncValue,liquidityValue,tokenId);
     return tokenId;
  }

  /*
    Creates a metadata string from a token id. Should not be used onchain.
  */
  function putTogetherMetadataString(uint256 tokenId) public view returns(string memory){
    //TODO: add the rest of the variables, separate with appropriate url variable separators for ease of use
    string memory isDivs=gradualDivsById[tokenId]?"true":"false";
    return string(abi.encodePacked("/?tokenId=",tokenId.toString(),"&lAddr=",lAddrById[tokenId].toString(),"&syncPrice=", syncPriceById[tokenId].toString(),"&syncAmount=",syncAmountById[tokenId].toString(),"&mPayout=",syncRewardedOnMaturity[tokenId].toString(),"&lPrice=",lTokenPriceById[tokenId].toString(),"&lAmount=",lTokenAmountById[tokenId].toString(),"&startTime=",timestampById[tokenId].toString(),"&isDivs=",isDivs,"&termLength=",termLengthById[tokenId].toString(),"&divsNow=",dividendsOf(tokenId).toString()));
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

      //this line altered from
      //string memory _tokenURI = _tokenURIs[tokenId];
      //use of gas to manipulate strings can be avoided by putting them together at time of retrieval rather than in the token creation transaction.
      string memory _tokenURI = putTogetherMetadataString(tokenId);

      // If there is no base URI, return the token URI.
      if (bytes(baseURI()).length == 0) {
          return _tokenURI;
      }
      // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
      if (bytes(_tokenURI).length > 0) {
          return string(abi.encodePacked(baseURI(), _tokenURI));
      }
      // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
      return string(abi.encodePacked(baseURI(), tokenId.toString()));
  }

  /*
    Increments a counter used to produce the identifier for the next token to be created.
  */
  function _incrementTokenId() private  {
    _currentTokenId=_currentTokenId.add(1);
  }

  /*
    view functions
  */

  /*
    Returns the next unused token identifier.
  */
  function _getNextTokenId() private view returns (uint256) {
    return _currentTokenId.add(1);
  }

  /*
    Convenience function to get the current block time directly from the contract.
  */
  function getTime() public view returns(uint256){
    return block.timestamp;
  }

  /*
    Returns the current dividends owed to the given token, payable to its current owner.
  */
  function dividendsOf(uint256 tokenId) public view returns(uint256){
    //determine the number of periods worth of divs the token owner is owed, by subtracting the current period by the period when divs were last withdrawn.
    require(lastDivsCashoutById[tokenId]>=timestampById[tokenId],"dof1");
    uint256 lastCashoutInPeriod=lastDivsCashoutById[tokenId].sub(timestampById[tokenId]).div(QUARTER_LENGTH);//0 - first quarter, 1 - second, etc. This variable also represents the number of quarters previously cashed out
    require(block.timestamp>=timestampById[tokenId],"dof2");
    uint256 currentCashoutInPeriod=block.timestamp.sub(timestampById[tokenId]).div(QUARTER_LENGTH);
    require(currentCashoutInPeriod>=lastCashoutInPeriod,"dof3");
    uint256 periodsToCashout=currentCashoutInPeriod.sub(lastCashoutInPeriod);

    //only accrue divs before the maturation date. The final div payment will be paid as part of the matureCBOND transaction, so set the maximum number of periods to cash out be one less than the ultimate total.
    if(currentCashoutInPeriod>=termLengthById[tokenId].div(90 days)){
      //possible for lastCashout period to be greater due to being able to cash out after CBOND has ended (which records lastCashout as being after that date, despite only paying out for earlier periods). In this case, set periodsToCashout to 0 and ultimately return 0, there are no divs left.
      if(lastCashoutInPeriod>termLengthById[tokenId].div(90 days).sub(1)){
        periodsToCashout=0;
      }
      else{
        periodsToCashout=termLengthById[tokenId].div(90 days).sub(1).sub(lastCashoutInPeriod);
      }

    }
    //multiply the number of periods to pay out with the amount of divs owed for one period. Note: if this is a Quarterly Cbond, syncInterestById will have been recorded as the interest per quarter, rather than the total interest for the Cbond, as with a normal Cbond.
    uint quarterlyDividend=syncInterestById[tokenId];
    return periodsToCashout.mul(syncAmountById[tokenId]).mul(quarterlyDividend).div(PERCENTAGE_PRECISION);
  }

  /*
    Returns the amount of Sync needed to create a Cbond with the given amount of the given liquidity token. Consults the price oracle for the appropriate ratio.
  */
  function getSyncRequiredForCreation(IERC20 liquidityToken,uint256 amount) external view returns(uint256){
    return  priceChecker.liquidityValues(address(liquidityToken)).mul(amount).div(priceChecker.syncValue());
  }

  /*
    Set the sync rewarded on maturity and interest rate for the given CBOND
  */
  function setInterestRate(uint256 tokenId,uint256 syncRequired,address liquidityToken,uint256 secondsInTerm,bool gradualDivs) private{
    (uint256 lastSupply,uint256 currentSupply,uint256 lastTSupply,uint256 currentTSupply,uint256 lastInterestRate)=getSuppliesNow(liquidityToken);
    (uint256 interestRate,uint256 totalReturn)=getCbondTotalReturn(tokenId,syncRequired,liquidityToken,secondsInTerm,gradualDivs);
    syncRewardedOnMaturity[tokenId]=totalReturn;
    syncInterestById[tokenId]=interestRate;
    if(gradualDivs){
      require(secondsInTerm>=TERM_DURATIONS[2],"dividend bearing CBONDs must be at least 1 year duration");
      totalQuarterlyCBONDS=totalQuarterlyCBONDS.add(1);
    }
  }

  /*
    Following two functions work immediately after all the Cbond variables except the interest rate have been set, will be inaccurate other times. To be used as part of Cbond creation.
  */

  /*
    Gets the amount of Sync for the given Cbond to return on maturity.
  */
  function getCbondTotalReturn(uint256 tokenId,uint256 syncAmount,address liqAddr,uint256 duration,bool isDivs) public view returns(uint256 interestRate,uint256 totalReturn){
    // This is an integer math translation of P*(1+I) where P is principle I is interest rate. The new, equivalent formula is P*(c+I*c)/c where c is a constant of amount PERCENTAGE_PRECISION.

    interestRate=getCbondInterestRateNow(liqAddr, duration,getLuckyExtra(tokenId),isDivs);
    totalReturn = syncAmount.mul(PERCENTAGE_PRECISION.add(interestRate)).div(PERCENTAGE_PRECISION);
  }

  /*
    Gets the interest rate for a Cbond given its relevant properties.
  */
  function getCbondInterestRateNow(
    address liqAddr,
    uint256 duration,
    uint256 luckyExtra,
    bool quarterly) public view returns(uint256){

    return getCbondInterestRate(
      duration,
      liqTokenTotalsByDay[liqAddr][lastDayTokenSupplyUpdated[liqAddr]],
      liqTokenTotalsByDay[liqAddr][getDay(block.timestamp)],
      syncSupplyByDay[lastDaySyncSupplyUpdated],
      syncSupplyByDay[getDay(block.timestamp)],
      interestRateByDay[lastDaySyncSupplyUpdated],
      luckyExtra,
      quarterly);
  }

  /*
    This returns the Cbond interest rate. Divide by PERCENTAGE_PRECISION to get the real rate.
  */
  function getCbondInterestRate(
    uint256 duration,
    uint256 liqTotalLast,
    uint256 liqTotalCurrent,
    uint256 syncTotalLast,
    uint256 syncTotalCurrent,
    uint256 lastBaseInterestRate,
    uint256 luckyExtra,
    bool quarterly) public view returns(uint256){

    uint256 liquidityPairIncentiveRate=getLiquidityPairIncentiveRate(liqTotalCurrent,liqTotalLast);
    uint256 baseInterestRate=getBaseInterestRate(lastBaseInterestRate,syncTotalCurrent,syncTotalLast);
    if(!quarterly){
      return getDurationRate(duration,baseInterestRate.add(liquidityPairIncentiveRate).add(luckyExtra));
    }
    else{
      uint numYears=duration.div(YEAR_LENGTH);
      require(numYears>0,"invalid duration");//Quarterly Cbonds must have a duration 1 year or longer.
      uint numQuarters=duration.div(QUARTER_LENGTH);
      uint termModifier=RISK_FACTOR.mul(numYears.mul(4).sub(1));
      //Interest rate is the sum of base interest rate, liquidity incentive rate, and risk/term based modifier. Because this is the Quarterly Cbond rate, we also divide by the number of quarters in the Cbond, to set the recorded rate to the amount withdrawable per quarter.
      return baseInterestRate.add(liquidityPairIncentiveRate).add(luckyExtra).add(termModifier);
    }
  }

  /*
    This returns the Lucky Extra bonus of the given Cbond. This is based on whether the id of the Cbond ends in two or three 7's, and whether admins have disabled this feature.
  */
  function getLuckyExtra(uint256 tokenId) public view returns(uint256){
    if(luckyEnabled){
      if(tokenId.mod(100)==77){
        return LUCKY_EXTRAS[0];
      }
      if(tokenId.mod(1000)==777){
        return LUCKY_EXTRAS[1];
      }
    }
    return 0;
  }

  /*
    New implementation of duration modifier. Approximation of intended formula.
  */
  function getDurationRate(uint duration, uint baseInterestRate) public view returns(uint){
        require(duration==TERM_DURATIONS[0] || duration==TERM_DURATIONS[1] || duration==TERM_DURATIONS[2] || duration==TERM_DURATIONS[3] || duration==TERM_DURATIONS[4],"Invalid CBOND term length provided");

        if(duration==TERM_DURATIONS[0]){
          return baseInterestRate;
        }
        if(duration==TERM_DURATIONS[1]){
            uint preExponential = PERCENTAGE_PRECISION.add(baseInterestRate).add(RISK_FACTOR);
            uint exponential = preExponential.mul(preExponential).div(PERCENTAGE_PRECISION);
            return exponential.sub(PERCENTAGE_PRECISION);
        }
        if(duration==TERM_DURATIONS[2]){//1 year
            uint preExponential = PERCENTAGE_PRECISION.add(baseInterestRate).add(RISK_FACTOR.mul(3));
            uint exponential = preExponential.mul(preExponential).div(PERCENTAGE_PRECISION);
            for (uint8 i=0;i<2;i++) {
                exponential = exponential.mul(preExponential).div(PERCENTAGE_PRECISION);
            }
            return exponential.sub(PERCENTAGE_PRECISION);
        }
        if(duration==TERM_DURATIONS[3]){//2 years
            uint preExponential = PERCENTAGE_PRECISION.add(baseInterestRate).add(RISK_FACTOR.mul(7));
            uint exponential = preExponential.mul(preExponential).div(PERCENTAGE_PRECISION);
            for (uint8 i=0;i<6;i++) {
                exponential = exponential.mul(preExponential).div(PERCENTAGE_PRECISION);
            }
            return exponential.sub(PERCENTAGE_PRECISION);
        }
        if(duration==TERM_DURATIONS[4]){//3 years
            uint preExponential = PERCENTAGE_PRECISION.add(baseInterestRate).add(RISK_FACTOR.mul(11));
            uint exponential = preExponential.mul(preExponential).div(PERCENTAGE_PRECISION);
            for (uint8 i=0;i<10;i++) {
                exponential = exponential.mul(preExponential).div(PERCENTAGE_PRECISION);
            }
            return exponential.sub(PERCENTAGE_PRECISION);
        }
    }

  /*
    Returns the liquidity pair incentive rate. To use, multiply by a value then divide result by PERCENTAGE_PRECISION
  */
  function getLiquidityPairIncentiveRate(uint256 totalToday,uint256 totalYesterday) public view returns(uint256){
    //instead of reverting due to division by zero, if tokens in this contract go to zero give the max bonus
    if(totalToday==0){
      return INCENTIVE_MAX_PERCENT;
    }
    return Math.min(INCENTIVE_MAX_PERCENT,INCENTIVE_MAX_PERCENT.mul(totalYesterday).div(totalToday));
  }

  /*
    Returns the base interest rate, derived from the previous day interest rate, the current Sync total supply, and the previous day Sync total supply.
  */
  function getBaseInterestRate(uint256 lastdayInterestRate,uint256 syncSupplyToday,uint256 syncSupplyLast) public pure returns(uint256){
    return Math.min(MAXIMUM_BASE_INTEREST_RATE,Math.max(MINIMUM_BASE_INTEREST_RATE,lastdayInterestRate.mul(syncSupplyToday).div(syncSupplyLast)));
  }

  /*
    Returns the interest rate a Cbond with the given parameters would end up with if it were created.
  */
  function getCbondInterestRateIfUpdated(address liqAddr,uint256 duration,uint256 luckyExtra,bool quarterly) public view returns(uint256){
    (uint256 lastSupply,uint256 currentSupply,uint256 lastTSupply,uint256 currentTSupply,uint256 lastInterestRate)=getSuppliesIfUpdated(liqAddr);
    return getCbondInterestRate(duration,lastTSupply,currentTSupply,lastSupply,currentSupply,lastInterestRate,luckyExtra,quarterly);
  }

  /*
    Convenience function for frontend use which returns current and previous recorded Sync total supply, and tokens held for the provided token.
  */
  function getSuppliesNow(address tokenAddr) public view returns(uint256 lastSupply,uint256 currentSupply,uint256 lastTSupply,uint256 currentTSupply,uint256 lastInterestRate){
    currentSupply=syncSupplyByDay[currentDaySyncSupplyUpdated];
    lastSupply=syncSupplyByDay[lastDaySyncSupplyUpdated];
    lastInterestRate=interestRateByDay[lastDaySyncSupplyUpdated];
    currentTSupply=liqTokenTotalsByDay[tokenAddr][currentDayTokenSupplyUpdated[tokenAddr]];
    lastTSupply=liqTokenTotalsByDay[tokenAddr][lastDayTokenSupplyUpdated[tokenAddr]];
  }

  /*
    Gets what the Sync and liquidity token current and last supplies would become, if updated now. Intended for frontend use.
  */
  function getSuppliesIfUpdated(address tokenAddr) public view returns(uint256 lastSupply,uint256 currentSupply,uint256 lastTSupply,uint256 currentTSupply,uint256 lastInterestRate){
    uint256 day=getDay(block.timestamp);
    if(liqTokenTotalsByDay[tokenAddr][getDay(block.timestamp)]==0){
      currentTSupply=IERC20(tokenAddr).balanceOf(address(this));
      lastTSupply=liqTokenTotalsByDay[tokenAddr][currentDayTokenSupplyUpdated[tokenAddr]];
    }
    else{
      currentTSupply=liqTokenTotalsByDay[tokenAddr][currentDayTokenSupplyUpdated[tokenAddr]];
      lastTSupply=liqTokenTotalsByDay[tokenAddr][lastDayTokenSupplyUpdated[tokenAddr]];
    }
    if(syncSupplyByDay[day]==0){
      currentSupply=syncToken.totalSupply();
      lastSupply=syncSupplyByDay[currentDaySyncSupplyUpdated];
      //TODO: interest rate
      lastInterestRate=interestRateByDay[currentDaySyncSupplyUpdated];
    }
    else{
      currentSupply=syncSupplyByDay[currentDaySyncSupplyUpdated];
      lastSupply=syncSupplyByDay[lastDaySyncSupplyUpdated];
      lastInterestRate=interestRateByDay[lastDaySyncSupplyUpdated];
    }
  }

  /*
    Function for recording the Sync total supply and base interest rate by day. Records only at the first time it is called in a given day (see getDay).
  */
  function recordSyncSupply() public{
    if(syncSupplyByDay[getDay(block.timestamp)]==0){
      uint256 day=getDay(block.timestamp);
      syncSupplyByDay[day]=syncToken.totalSupply();
      lastDaySyncSupplyUpdated=currentDaySyncSupplyUpdated;
      currentDaySyncSupplyUpdated=day;

      //interest rate
      interestRateByDay[day]=getBaseInterestRate(interestRateByDay[lastDaySyncSupplyUpdated],syncSupplyByDay[day],syncSupplyByDay[lastDaySyncSupplyUpdated]);
    }
  }

  /*
    Records the current amount of the given token held by this contract for the current day. Like recordSyncSupply, only records the first time it is called in a day.
  */
  function recordTokenSupply(address tokenAddr) private{
    if(liqTokenTotalsByDay[tokenAddr][getDay(block.timestamp)]==0){
      uint256 day=getDay(block.timestamp);
      liqTokenTotalsByDay[tokenAddr][day]=IERC20(tokenAddr).balanceOf(address(this));
      lastDayTokenSupplyUpdated[tokenAddr]=currentDayTokenSupplyUpdated[tokenAddr];
      currentDayTokenSupplyUpdated[tokenAddr]=day;
    }
  }

  /*
    Gets the current day since the contract began. Starts at 1.
  */
  function getDay(uint256 timestamp) public view returns(uint256){
    return timestamp.sub(STARTING_TIME).div(24 hours).add(1);
  }

  /*
    Gets the current day since the contract began, at the current block time.
  */
  function getDayNow() public view returns(uint256){
    return getDay(block.timestamp);
  }
}