/**
 *Submitted for verification at BscScan.com on 2023-02-18
*/

// File: PinksaleICO.sol



pragma solidity ^0.8.0;

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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
        return div(a, b, "SafeMath: division by zero.");
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

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


contract PinksaleICO is ReentrancyGuard {
    using SafeMath for uint256;

    struct ICOInfo {
        IERC20 sale_token; // Sale token
        IERC20 buy_token; // in case of buy with BUSD/USDT/USDC
        string buy_token_name; // used to store buy token name to get at front end.
        uint256 token_rate; // 1 base token = ? s_tokens, fixed price
        uint256 token_supply; // total supply user will sale by creating an ICO.
        uint256 ICO_start;
        uint256 ICO_end;
    }

    struct ICOStatus {
        uint256 raised_amount; // Total base currency raised (usually ETH)
        uint256 sold_amount; // Total ICO tokens sold
        uint256 num_buyers; // Number of unique participants
    }

    struct BuyerInfo {
        uint256 base; // Total base token (usually ETH) deposited by user, can be withdrawn on presale failure
        uint256 sale; // Num presale tokens a user owned, can be withdrawn on presale success
    }
    
    struct TokenInfo {
        string name;
        string symbol;
        uint256 decimal;
    }

    address public owner;

    ICOInfo public ICO_info;
    ICOStatus public status;
    TokenInfo public tokeninfo;

    uint256 public ICOSetting;


    mapping(address => BuyerInfo) private buyers;

    event ICOCreated(address, address);
    event UserDepsitedSuccess(address, uint256);
    event OwnerWithdrawRemainingTokensSuccess(uint256);
    event OwnerWithdrawCollectedBNBSuccess(uint256);
    event OwnerWithdrawCollectedTokenSuccess(uint256);

    modifier onlyOwner() {
        require(owner == msg.sender, "Not ICO owner.");
        _;
    }


    constructor(
        address owner_,
        IERC20 _sale_token,
        IERC20 _buy_token,
        string memory _buy_token_name,
        uint256 _token_rate,
        uint256 _token_supply,
        uint256 _ICO_start,
        uint256 _ICO_end
    ) {
        owner = msg.sender;
        init_private(
            _sale_token,
            _buy_token,
            _buy_token_name,
            _token_rate,
            _token_supply,
            _ICO_start,
            _ICO_end
        );
        owner = owner_;
        
        emit ICOCreated(owner, address(this));
    }

    function init_private (
        IERC20 _sale_token,
        IERC20 _buy_token,
        string memory _buy_token_name,
        uint256 _token_rate,
        uint256 _token_supply,
        uint256 _ICO_start,
        uint256 _ICO_end
        ) private onlyOwner {

        require(ICOSetting == 0, "Already setted");
        require(address(_sale_token) != address(0), "Zero Address");
        
        ICO_info.sale_token = _sale_token;
        if(address(_buy_token) != address(0)){
            ICO_info.buy_token = _buy_token;
        }
        ICO_info.buy_token_name = _buy_token_name;
        ICO_info.token_rate = _token_rate;
        ICO_info.token_supply = _token_supply;
        ICO_info.ICO_end = _ICO_end;
        ICO_info.ICO_start =  _ICO_start;

        //Set token token info
        tokeninfo.name = ICO_info.sale_token.name();
        tokeninfo.symbol = ICO_info.sale_token.symbol();
        tokeninfo.decimal = ICO_info.sale_token.decimals();

        ICOSetting = 1;
    }

    // Receive BNB and transfer ERC20 token according to the set exchange rate.
    function buyWithBNB() external payable nonReentrant {
        require(block.timestamp >= ICO_info.ICO_start && block.timestamp <= ICO_info.ICO_end, "ICO: Invalid buy time");

        address _buyer = msg.sender; // for later redundent use. Purpose: Gas consumption.
        uint256 _BNBAmount_in = msg.value; // for later redundent use. Purpose: gas consumption.
        uint256 _actualBNB_in; // actual amount of bnb to be received.
        uint256 _tokens_out; // total ERC20 tokens out.
        uint256 _remaining_out; // unused amount of bnb
        uint256 _remaining_supply = remainingSupply();

        require(_BNBAmount_in > 0, "ICO: Invalid amount of sent BNB");
        require(address(ICO_info.buy_token) == address(0), "ICO: Token cannot buy with bnb");
        _tokens_out = _BNBAmount_in * ICO_info.token_rate;

        if(_tokens_out > _remaining_supply) {
            _tokens_out = _remaining_supply; // actual tokens out.
            _remaining_out = _BNBAmount_in.sub(_tokens_out.div(ICO_info.token_rate)); // unused bnb amount.
            _actualBNB_in = _BNBAmount_in.sub(_remaining_out); // acutual bnb amount to be received.
            _BNBAmount_in = _actualBNB_in; // update the _BNBAmount_in value for later use.
        }

        BuyerInfo storage buyer = buyers[_buyer];
        if(buyer.base == 0){
            status.num_buyers++;
        }
        //update buyer data and contract data.
        buyer.base = buyer.base.add(_BNBAmount_in);
        buyer.sale = buyer.sale.add(_tokens_out);
        status.raised_amount = status.raised_amount.add(_BNBAmount_in);
        status.sold_amount = status.sold_amount.add(_tokens_out);

        ICO_info.sale_token.transfer(_buyer, _tokens_out); // transfer ERC20 tokens to the buyer.

        if(_remaining_out != 0){
            payable(_buyer).transfer(_remaining_out); // refund unused bnb to the buyer.
        }

        emit UserDepsitedSuccess(_buyer, _BNBAmount_in);
    }

    // Receive BUSD/USDT/USDC and transfer Sale token according to the set exchange rate.
    function buyWithoutBNB(IERC20 _token, uint256 _amount) external nonReentrant {
        require(block.timestamp >= ICO_info.ICO_start && block.timestamp <= ICO_info.ICO_end, "ICO: Invalid buy time");

        address _buyer = msg.sender; // for later redundent use. Purpose: Gas consumption.
        uint256 _amount_in = _amount;
        uint256 _actualAmount_in; // actual amount of sent BUSD/USDT/USDC token to be received.
        uint256 _tokens_out; // total ERC20 tokens out.
        uint256 _remaining_out; // unused amount of sent BUSD/USDT/USDC token
        uint256 _remaining_supply = remainingSupply(); 

        require(_token == ICO_info.buy_token, "ICO buy: Invalid _token address");
        require(_amount_in > 0, "ICO: Invalid amount of sent BUSD/USDT/USDC");
        require(_token.balanceOf(_buyer) >= _amount, "ICO buy: Insufficient balance");

        _tokens_out = _amount_in * ICO_info.token_rate; // total exchanged ERC20 tokens according to rate.

        if(_tokens_out > _remaining_supply) {
            _tokens_out = _remaining_supply; // actual tokens out.
            _remaining_out = _amount_in.sub(_tokens_out.div(ICO_info.token_rate)); // unused bnb amount.
            _actualAmount_in = _amount_in.sub(_remaining_out); // acutual bnb amount to be received.
            _amount_in = _actualAmount_in; // update _tokens
        }

        _token.transferFrom(_buyer, address(this), _amount_in); // take tokens in BUSD/USDT/USDC from user.
        
        BuyerInfo storage buyer = buyers[_buyer];
        if(buyer.base == 0){
            status.num_buyers++;
        }
        //update buyer data and contract data.
        buyer.base = buyer.base.add(_amount_in);
        buyer.sale = buyer.sale.add(_tokens_out);
        status.raised_amount = status.raised_amount.add(_amount_in);
        status.sold_amount = status.sold_amount.add(_tokens_out);

        ICO_info.sale_token.transfer(_buyer, _tokens_out); // transfer ERC20 tokens to the buyer.

        emit UserDepsitedSuccess(_buyer, _amount_in);
    }
    
    
    // On ICO Ended
    function ownerWithdrawRemainingTokens () external onlyOwner {
        require(block.timestamp > ICO_info.ICO_end, "ICO OwnerwithDraw: ICO is not ended yet"); // ICO Ended
        IERC20 _token = ICO_info.sale_token;
        require(_token.balanceOf(address(this)) > 0, "ICO ownerWithdraw: Already withdrawn");
        _token.transfer(owner, _token.balanceOf(address(this)));
        
        emit OwnerWithdrawRemainingTokensSuccess(_token.balanceOf(address(this)));
    }

    // on ICO ended.
    function ownerWithdrawCollectedBNBs () external onlyOwner {
        require(block.timestamp > ICO_info.ICO_end, "ICO OwnerwithDraw: ICO is not ended yet"); // ICO Ended
        require(address(ICO_info.buy_token) == address(0), "ICO: ICO didn't created with bnb");
        require(address(this).balance > 0, "ICO ownerWithdraw: Not collected any BNB yet");
        
        payable(owner).transfer(address(this).balance);
        
        emit OwnerWithdrawCollectedBNBSuccess(address(this).balance);
    }

    // on ICO ended.
    function ownerWithdrawCollectedToken () external onlyOwner {
        require(block.timestamp > ICO_info.ICO_end, "ICO OwnerWithdraw: ICO is not ended yet"); // ICO ended.
        require(address(ICO_info.buy_token) != address(0), "ICO OwnerWithdraw: ICO created with BNB");
        require(ICO_info.buy_token.balanceOf(address(this)) > 0, "ICO OwnerWithdraw: Not collected any token yet.");

        IERC20 _token = ICO_info.buy_token;
        _token.transfer(owner, _token.balanceOf(address(this)));

        emit OwnerWithdrawCollectedTokenSuccess(_token.balanceOf(address(this)));
    }

    // get ICO start and end time.
    function getICOTimes () public view returns (uint256, uint256) {
        return (ICO_info.ICO_start, ICO_info.ICO_end);
    }

    // get remaining supply of the sale token.
    function remainingSupply() public view returns (uint256) {
        return ICO_info.token_supply.sub(status.sold_amount);
    }

    // get amount of bnb/busd/usdt/usdc sent by user to smart contract
    function baseByUserCount (address _user) public view returns (uint256) {
        return buyers[_user].base;
    }
    
    // get amount of _saleTokens purchased by user
    function saleToUserCount(address _user) public view returns (uint256) {
        return buyers[_user].sale;
    }
}
// File: PinksaleICOFactory.sol


pragma solidity ^0.8.0;

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
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
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
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
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
     * @dev Returns the number of values in the set. O(1).
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}


contract PinksaleICOFactory {
  using Address for address payable;
  using SafeMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;

  address public feeTo;
  address public owner;
  uint256 public flatFee;
  uint256 private _salt = 10;

  PinksaleICO[] private _ICOs;
//   EnumerableSet.AddressSet private _ICOs;
  mapping (address => EnumerableSet.AddressSet) private _userICOs;

    // modifier: to check enough fee before creating an ICO.
  modifier enoughFee() {
    require(msg.value >= flatFee, "Flat fee");
    _;
  }

  modifier onlyOwner {
    require(msg.sender == owner, "You are not owner");
    _;
  }

    // will be emitted on each ICO creation.
  event CreatedICO(address indexed tokenAddress);

  constructor() {
    feeTo = msg.sender; // collected fee will be transferred to deployer
    flatFee = 100_000_000 gwei; // 0.1 BNB/ETH
    owner = msg.sender;
  }

    // changing fee receiver address.
    // only owner is authorized.
  function setFeeTo(address feeReceivingAddress) external onlyOwner {
    feeTo = feeReceivingAddress;
  }

    // changing fee amount.
    // only owner is authorized.
  function setFlatFee(uint256 fee) external onlyOwner {
    flatFee = fee;
  }

    // refund extra ETH/BNB fee sent by user at the time of ICO creation
  function refundExcessiveFee() internal {
    uint256 refund = msg.value.sub(flatFee);
    if (refund > 0) {
      payable(msg.sender).sendValue(refund);
    }
  }

    // create an instance of Pinksale ICO.
  function create(
    IERC20 _sale_token,
    IERC20 _buy_token, // will be address(0) in case of buy with BNB.
    string memory _buy_token_name,
    uint256 _token_rate,
    uint256 _token_supply,
    uint256 _ICO_start,
    uint256 _ICO_end
  ) external payable enoughFee returns (address) {
    require(_ICO_start > block.timestamp, "FactoryICO: Start time should be after now.");
    require(_ICO_end > _ICO_start, "FactoryICO: End date should be greater than start date");
    require(_sale_token.balanceOf(msg.sender) >= _token_supply, "FactoryICO: You don't have enough tokens");
    require(_sale_token.allowance(msg.sender, address(this)) >= _token_supply, "FactoryICO: Approve first");

    // take tokens from user for transfer to the ICO smart contract.
    refundExcessiveFee();

    // create2 opcode is used to create instances.
    PinksaleICO newICO = new PinksaleICO{
        salt: bytes32(++_salt)
    }(
      msg.sender,
      _sale_token,
      _buy_token,
      _buy_token_name,
      _token_rate,
      _token_supply,
      _ICO_start,
      _ICO_end
    );

    // transfer all the supply to ICO.
    _sale_token.transferFrom(msg.sender, address(newICO), _token_supply);
    _ICOs.push(newICO); // take record of all created ICOs.
    _userICOs[msg.sender].add(address(newICO)); // take record of all created ICOs for specific user.

    // if flatFee is enabled then transfer fee to fee receiver address.
    if(flatFee > 0) { 
        payable(feeTo).transfer(flatFee);
    }
    emit CreatedICO(address(newICO));
    return address(newICO);
  }

  // total ICOs created yet on platform
  function totalICOs() external view returns (PinksaleICO[] memory) {
      return _ICOs;
  }

  // total ICOs for a specific user.
  function totalICOsForUser(address _user) external view returns (address[] memory) {
      return _userICOs[_user].values();
  }


  // all number of ICOs on the platform
  function totalICOsCount() external view returns (uint256) {
      return _ICOs.length;
  }

  // all number of ICOs for specific user. 
  function totalICOsCountForUser(address _user) external view returns (uint256) {
      return _userICOs[_user].length();
  }
}