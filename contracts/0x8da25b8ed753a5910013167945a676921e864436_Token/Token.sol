/**
 *Submitted for verification at Etherscan.io on 2020-09-28
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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

abstract contract StakeBLVToken {
  function transferHook(address sender, address recipient, uint256 amount, uint256 senderBalance, uint256 recipientBalance) external virtual returns (uint256, uint256, uint256);
  function updateMyStakes(address staker, uint256 balance, uint256 totalSupply) external virtual returns (uint256);
}


/**
 * @dev Implementation of the  BLV
 * BLV is a price-reactive cryptocurrency.
 * That is, the inflation rate of the token is wholly dependent on its market activity.
 * Minting does not happen when the price is less than the day prior.
 * When the price is greater than the day prior, the inflation for that day is
 * a function of its price, percent increase, volume, any positive price streaks,
 * and the amount of time any given holder has been holding.
 * In the first iteration, the dev team acts as the price oracle, but in the future, we plan to integrate a Chainlink price oracle.
 */
contract Token is Ownable, IERC20 {
  using SafeMath for uint256;
  using Address for address;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;

  string public constant _name = "Bellevue Network";
  string public constant _symbol = "BLV";
  uint8 public constant _decimals = 18;

  StakeBLVToken public _stakingContract;

  address public _intervalWatcher;

  address public _teamWallet;
  address public _treasuryWallet;
    
  uint public startTimestamp;
  
  bool public freeze;
  
  bool private _stakingEnabled;
  
  struct Vester {
      uint lastRelease;
      uint balanceRemaining;
      uint balanceInit;
  }
    
  mapping (address => Vester) public vesters;


  modifier onlyWatcher() {
    assert(_msgSender() == _intervalWatcher/*, "Caller must be watcher."*/);
    _;
  }

  modifier onlyStakingContract() {
    require(msg.sender == address(_stakingContract), "Ownable: caller is not the staking contract");
    _;
  }

  event ErrorMessage(string errorMessage);

  constructor () public {
    
    startTimestamp = block.timestamp;

    _stakingEnabled = false;
    _treasuryWallet = 0xF40B0918D6b78fd705F30D92C9626ad218F1aEcE;
    _teamWallet = 0x2BFA783D7f38aAAa997650aE0EfdBDF632288A7F;
    _intervalWatcher = msg.sender;
    
    freeze = false;
    transferOwnership(0x6f3Bdb71C8d42b5a5DEe58b1a66f8a299EC4d216);
    
    _mint(0xb1412DFFBb7db18F8686Ea4787c30cA40BC6D1a8, 1000000E18);
    _mint(0xd1d784920983CdB17EE125887c875548D149E856, 1000000E18);
    _mint(0x2366ff0577e53984Bc0E103c803658DA1Ef7d19A, 425000E18);
    _mint(0x380D463383201f1758a7c59aE569d79bA84D7263, 425000E18);
    _mint(0xf8880975805Fc659C756aBfE879002FDa1470768, 425000E18);
    _mint(0xE20cf34fD6B38689eb68968E90F25CC6B80B16FB, 425000E18);
    _mint(0xa2B9a5f796ef1f68B2aEF0c984F961beD1085500, 425000E18);
    _mint(0x15DD94C2F7A78Be9b7d8711C09083F4F6EFc1029, 425000E18);
    _mint(0xD388BD277F390Cb36A90DEf9771c47869b266BAE, 425000E18);
    _mint(0x93f5af632Ce523286e033f0510E9b3C9710F4489, 425000E18);
    _mint(0x85D72d2D43c7BF149abf2132bDA2992087a9527e, 425000E18);
    _mint(0x4f5304E7CC2efD8a12d92703fF4964A79276a638, 425000E18);
    _mint(0xD733801c2512ce294a34b3a8878365dd30c7d791, 425000E18);
    
    _mint(0x7af6701EF2456F25e22a6e4Bfd70bCdFA0aEeB97, 425000E18);
    _mint(0x41a9A2bb121FE08592678Fc2c6fd0498b914a3c7, 425000E18);
    _mint(0x4530B100BF6400268E22fE64d7548fFaafA8dC39, 425000E18);
    _mint(0xbb257625458a12374daf2AD0c91d5A215732F206, 425000E18);
    _mint(0x84998f375355AE7AE7f60e8ecF1D24ad59948e9a, 425000E18);
    _mint(0x25054f27C9972B341Aee6c0D373A652566075431, 425000E18);
    _mint(0x7Da3c02716676f81790726c91BF4D05f14E98677, 425000E18);
    _mint(0xbbDBD6Bb3C05a7c966c203502e0a5A373E01e103, 425000E18);
    _mint(0x2604afb5A64992e5aBBF25865C9d3387adE92bad, 425000E18);
    _mint(0x4f6EB296cCAC2668640934208538EE8e3d3C846c, 425000E18);
    _mint(0x2F7B7aFbcaC8A70a1E0fe712a644e4621EdBB832, 425000E18);
    _mint(0x0C780749E6d0bE3C64c130450B20C40b843fbEC4, 425000E18);
    
    
    _mint(0xa4e74aE45F53045e07e3189933Bb5B1286BaeD54, 425000E18);
    _mint(0x6766c0Ad04d5aA6B53D8E42738dafBA490B0A7a3, 425000E18);
    _mint(0xC419528eDA383691e1aA13C381D977343CB9E5D0, 425000E18);
    _mint(0x515e4940850c217B8f4f2E3D2bE0aC6A52F17624, 425000E18);
    _mint(0x946C2a67373e64D5B318f9A669fE5664256491d6, 425000E18);
    _mint(0x6CDB0A4902C81E9C63De8c486F31e8d5DDc0A9f7, 425000E18);
    _mint(0x907b4128FF43eD92b14b8145a01e8f9bC6890E3E, 425000E18);
    _mint(0x3481fBA85c1b227Cd401d4ef2e2390f505738B08, 425000E18);
    _mint(0x06C8940CFEc1e9596123a2b0fA965F9E3758422f, 425000E18);
    _mint(0x5AaAEF91F93bE4dE932b8e7324aBBF9f26DAa706, 425000E18);
    _mint(0xEF572FbBdB552A00bdc2a3E3Bc9306df9E9e169d, 425000E18);
    _mint(0xE8609d2608Fb5555cb84e5D03c5B837A116fA8AD, 425000E18);
    
    _mint(0x05BaD2724b1415a8B6B3000a30E37d9C637D7340, 425000E18);
    _mint(0x2b82FEaC8778CE69eBbaE549DcfB558C6024714a, 425000E18);
    _mint(0xDBe24A37f06CAb8C8A786dDF0439ea5cB28e5328, 425000E18);
    _mint(0x318f1cFD866BE8a0835412A02127271B3e0F6485, 425000E18);
    _mint(0x5516F15603707EE1e854E149F0f0E33F443cC9C4, 425000E18);
    _mint(0x7723000de847d13856Aa46993e6D1d499D13af1B, 425000E18);
    _mint(0x76a7aa09e047fc0Cd56d206b986A67772ED936FD, 425000E18);
    _mint(0x4d6f7D3EC5ab66D14a494b4650717e7D44E527bD, 425000E18);
    _mint(0xA3839Cb3b18d0d8372cc1ba8ACb3C693329FD92B, 425000E18);
    _mint(0x7729370DA4bfeE1Ee183eEdD35176fCB20F9E8eb, 425000E18);
    _mint(0xa4b949fb6B2979E383b753f7b086ee1a7adB552a, 425000E18);
    _mint(0xc7861b59e2193424AfC83a83bD65c8B5216c7EB0, 425000E18);
    _mint(0x94054865f83f9Df3fAE7D4B8E6B08b7ff420b0e2, 425000E18);
    
    _mint(0x6766c0Ad04d5aA6B53D8E42738dafBA490B0A7a3, 29125000E18);
    
    
    
    
    vesters[_treasuryWallet] = (Vester(now, 25000000E18, 25000000E18));  // Treasury
    vesters[_teamWallet] = (Vester(now, 25000000E18, 25000000E18));  // Team
    
    
    vesters[0x8Ff5Ceb90FAb0e98fDfB3b9eACdF162dFFAaFeb4] = (Vester(now, 1000000E18, 1000000E18));
    vesters[0x48FFB1b31D30b59b54FEe7744fFd2Be62ae40E80] = (Vester(now, 1000000E18, 1000000E18));
    vesters[0xa626FDF1F62176EFFB78E00d579E421e67ADa485] = (Vester(now, 1000000E18, 1000000E18));
    vesters[0x814035FD80140Af0a5b7502c9b1a10f6eC8aD38A] = (Vester(now, 1000000E18, 1000000E18));
    vesters[0x3300D317713938007cFeC35268aaC7d54dB3a85b] = (Vester(now, 1000000E18, 1000000E18));
    vesters[0x99D34cAf247fCfB23570D1B29468DB1659604c96] = (Vester(now, 1000000E18, 1000000E18));
    vesters[0xFEDED73b3b2b74441C8Bf42218e7Ff24030A9705] = (Vester(now, 1000000E18, 1000000E18));
    vesters[0x0793F2c24bDc8353951Dcb9b14D30801bb608421] = (Vester(now, 1000000E18, 1000000E18));
    vesters[0x4342e82B94b128fcCBe1bDDF454e51336cC5fde2] = (Vester(now, 1000000E18, 1000000E18));
    vesters[0xd62a38Bd99376013D485214CC968322C20A6cC40] = (Vester(now, 1000000E18, 1000000E18));
    vesters[0xC419528eDA383691e1aA13C381D977343CB9E5D0] = (Vester(now, 1000000E18, 1000000E18));
    vesters[0xdF1cb2e9B48C830154CE6030FFc5E2ce7fD6c328] = (Vester(now, 1000000E18, 1000000E18));
    vesters[0x88Eb97E5ECbf1c5b4ecA19aCF659d4724392eD86] = (Vester(now, 1000000E18, 1000000E18));
    vesters[0x13f0B3e3351ff54bA8daF733167436D46CBa8623] = (Vester(now, 1000000E18, 1000000E18));
    vesters[0x0793F2c24bDc8353951Dcb9b14D30801bb608421] = (Vester(now, 1000000E18, 1000000E18));
    vesters[0xd7741872efC695be77C9bc8B7E7AFCF928dd4912] = (Vester(now, 1000000E18, 1000000E18));
    vesters[0xbcd670eB38fE7937245324F8a9689c49c7A8e91e] = (Vester(now, 875000E18, 875000E18));
    vesters[0x875e5d68cED80a84F1D0bdE9a864CF387690aBC1] = (Vester(now, 425000E18, 425000E18));
    vesters[0xD61545c9f495Da3d556e0474A102DE3937eB8451] = (Vester(now, 425000E18, 425000E18));
    vesters[0x42415d75FD3Bfc6cD44F232109925e04Fc5610d8] = (Vester(now, 425000E18, 425000E18));
    vesters[0xaC6dE509E1B5c1C619afe64e0dfA567bd5b58503] = (Vester(now, 850000E18, 850000E18));
    vesters[0x88B1fAb25703a07cACd2C9Da4797df2379F43A32] = (Vester(now, 850000E18, 850000E18));
    vesters[0xDfBB98446715dCCFcE6Fc231952d2e16884fD0d5] = (Vester(now, 850000E18, 850000E18));
    vesters[0x7947dD50cF73fdd44dBc8f7A4BE28E490B4D5D1B] = (Vester(now, 850000E18, 850000E18));
    
    vesters[0x6F0AB036b74a8d8263823609858C3F7efB9Ab782] = (Vester(now, 500000E18, 500000E18));
    vesters[0xB6f526ef7820BCA52058Be5c75dC05c7C456d22B] = (Vester(now, 500000E18, 500000E18));
    vesters[0xa3ccA0E4B6C70c2fdFbf95bB35BEA1CA604F7207] = (Vester(now, 750000E18, 750000E18));
    vesters[0x7BE8C8FEF3C323bEBd0338D7DB2F9370f896fecD] = (Vester(now, 750000E18, 750000E18));
    vesters[0x9c10FfeF1AeC731b616cc22fEdECA5d81d61859e] = (Vester(now, 750000E18, 750000E18));
    vesters[0x9F22318d7ceE9e22be01bD3bf64fB9257FB7F4B8] = (Vester(now, 750000E18, 750000E18));
    vesters[0xf4EdFf75aD10030DF1412317ea38Ed84e12Ef41C] = (Vester(now, 750000E18, 750000E18));
    vesters[0xbaFf5f62BF40cbBFC0Be450F11126Fc4e094aAc3] = (Vester(now, 500000E18, 500000E18));
    vesters[0x1C96aFc64A706695A9558E76679f8Bc72e354854] = (Vester(now, 1000000E18, 1000000E18));
    vesters[0x0d0D3321bBeAFF438D68Ad58a77fdA6309920E86] = (Vester(now, 1000000E18, 1000000E18));
    vesters[0xB016539a2d7A0dFa98237C93AC4AF0f46Ba74BAD] = (Vester(now, 1000000E18, 1000000E18));
    vesters[0x66d4bdF37AA4c04c7C66a743396caE3FA2425f79] = (Vester(now, 1000000E18, 1000000E18));
    vesters[0x00893fAc04C1F1B6e30847Dcc1F24761271c81c7] = (Vester(now, 1000000E18, 1000000E18));
    vesters[0x20d256Ae504F7459532f3711035133624F83C15B] = (Vester(now, 1000000E18, 1000000E18));
    vesters[0x082faa352c52365c0B6e0D8F52523Acf8eA511f4] = (Vester(now, 1000000E18, 1000000E18));
    vesters[0x0Bbc35b239209C7819bC8e0008FF476DD637DFca] = (Vester(now, 1000000E18, 1000000E18));
    vesters[0xb2103ACE0eca26D55dfC827cD59d51DD87Bd0e03] = (Vester(now, 1000000E18, 1000000E18));
    vesters[0x80DFbf3cF73f6bbA8B5175976ae8338D4Ced26A7] = (Vester(now, 1000000E18, 1000000E18));
    vesters[0xE1aF2f6ba1B34656e72005d1cFc25a80a6248211] = (Vester(now, 1000000E18, 1000000E18));
    vesters[0x9E667b5277A38fE2d0f9297447fa7C62d3d6aE69] = (Vester(now, 1000000E18, 1000000E18));
    vesters[0x1BAf30992f4F37e0c5909276bA0e1a3F96Eaf9Cb] = (Vester(now, 1000000E18, 1000000E18));
    vesters[0xbDfBFd5B4123566D358f69882A5909492049be8A] = (Vester(now, 1000000E18, 1000000E18));
    vesters[0x19e61Dbc204BA4A5E3Ef57721c7ab139399df7c6] = (Vester(now, 1000000E18, 1000000E18));
    vesters[0x87f84EEc3adAC507372018DA187661726867f316] = (Vester(now, 1000000E18, 1000000E18));
    vesters[0x0Cbd15145285B9cd05e95c19cB1E2d1Fdc71Cf90] = (Vester(now, 1000000E18, 1000000E18));
    vesters[0x174818EB82C976083591d0eaa720B70498616561] = (Vester(now, 1000000E18, 1000000E18));
    vesters[0x643a7B5Cb05486626594b17280dcb051D2725155] = (Vester(now, 1000000E18, 1000000E18));
    vesters[0xf422c173264dCd512E3CEE0DB4AcB568707C0b8D] = (Vester(now, 850000E18, 850000E18));
    vesters[0xf916D5D0310BFCD0D9B8c43D0a29070670D825f9] = (Vester(now, 850000E18, 850000E18));
    vesters[0xE58Ea0ceD4417f0551Fb82ddF4F6477072DFb430] = (Vester(now, 850000E18, 850000E18));
  }
  
  
  
  function release() public {
      
    if(msg.sender == _treasuryWallet) {
        releaseTreasury();
        return;
    } else if (msg.sender == _teamWallet) {
        releaseTeam();
        return;
    }
    
    Vester storage vester = vesters[msg.sender];
    require(vester.balanceInit > 0 && vester.balanceRemaining > 0, "Timelock: no tokens to release");
    
    if(vester.lastRelease == startTimestamp) {
        uint tokens = mulDiv(vester.balanceInit, 25, 100);
        vester.lastRelease = block.timestamp;
        vester.balanceRemaining = vester.balanceRemaining.sub(tokens);
        _mint(msg.sender, tokens);
        return;
    }
    
    uint daysSinceLast = block.timestamp.sub(vester.lastRelease) / 86400;
    
    require(daysSinceLast >= 30);
    
    uint tokens = mulDiv(vester.balanceInit, 25, 100);
    if(tokens > vester.balanceRemaining) {
        tokens = vester.balanceRemaining;
    }
    vester.lastRelease = block.timestamp;
    vester.balanceRemaining = vester.balanceRemaining.sub(tokens);
    _mint(msg.sender, tokens);
}

    function releaseTreasury() internal {
        Vester storage vester = vesters[_treasuryWallet];
        if(vester.lastRelease == startTimestamp) {
            uint tokens = mulDiv(vester.balanceInit, 25, 100);
            vester.lastRelease = block.timestamp;
            vester.balanceRemaining = vester.balanceRemaining.sub(tokens);
            _mint(_treasuryWallet, tokens);
            return;
        }
        uint daysSinceLast = block.timestamp.sub(vester.lastRelease) / 86400;
        require(daysSinceLast >= 90);
        uint tokens = mulDiv(vester.balanceInit, 25, 100);
        if(tokens > vester.balanceRemaining) {
            tokens = vester.balanceRemaining;
        }
        vester.lastRelease = block.timestamp;
        vester.balanceRemaining = vester.balanceRemaining.sub(tokens);
        _mint(_treasuryWallet, tokens);
    }
    
    function releaseTeam() internal {
        Vester storage vester = vesters[_teamWallet];
        uint daysSinceLast = block.timestamp.sub(vester.lastRelease) / 86400;
        require(daysSinceLast >= 90);
        uint tokens = mulDiv(vester.balanceInit, 25, 100);
        if(tokens > vester.balanceRemaining) {
            tokens = vester.balanceRemaining;
        }
        vester.lastRelease = block.timestamp;
        vester.balanceRemaining = vester.balanceRemaining.sub(tokens);
        _mint(_teamWallet, tokens);
    }


  function updateMyStakes() public {
    require(_stakingEnabled, "Staking is disabled");
    try _stakingContract.updateMyStakes(msg.sender, _balances[msg.sender], _totalSupply) returns (uint256 numTokens) {
      _mint(msg.sender, numTokens);
    } catch Error (string memory error) {
      emit ErrorMessage(error);
    }
  }

  function updateTreasuryWallet(address treasuryWallet) external onlyOwner {
    _treasuryWallet = treasuryWallet;
  }

  function updateIntervalWatcher(address treasuryWatcher) external onlyOwner {
    _intervalWatcher = treasuryWatcher;
  }

  function updateTreasuryStakes() external onlyWatcher {
    require(_stakingEnabled, "Staking is disabled");
    try _stakingContract.updateMyStakes(_treasuryWallet, balanceOf(_treasuryWallet), _totalSupply) returns (uint256 numTokens) {
      _mint(_treasuryWallet, numTokens);
    } catch Error (string memory error) {
      emit ErrorMessage(error);
    }
  }

  function updateTeamStakes() external onlyWatcher {
    require(_stakingEnabled, "Staking is disabled");
    try _stakingContract.updateMyStakes(_teamWallet, balanceOf(_teamWallet), _totalSupply) returns (uint256 numTokens) {
      _mint(_teamWallet, numTokens);
    } catch Error (string memory error) {
      emit ErrorMessage(error);
    }
  }

  function updateStakingContract(StakeBLVToken stakingContract) external onlyOwner {
    _stakingContract = stakingContract;
    _stakingEnabled = true;
  }


  /**
   * @dev Returns the name of the token.
   */
  function name() public view returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public view returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5,05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
   * called.
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
  function decimals() public view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {IERC20-balanceOf}.
   */
  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account].add(vesters[account].balanceRemaining);
  }
  
  function balanceOfNoVesting(address account) public view returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {IERC20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
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
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for ``sender``'s tokens of at least
   * `amount`.
   */
  function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
    return true;
  }

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(address sender, address recipient, uint256 amount) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");
    require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
    if(sender != owner()) {
        require(freeze == false, "Contract is frozen");
    }
    
    

    if(_stakingEnabled) {
      (uint256 senderBalance, uint256 recipientBalance, uint256 burnAmount) = _stakingContract.transferHook(sender, recipient, amount, _balances[sender], _balances[recipient]);
      _balances[sender] = senderBalance;
      _balances[recipient] = recipientBalance;
      _totalSupply = _totalSupply.sub(burnAmount);
      if (burnAmount > 0) {
        emit Transfer(sender, recipient, amount.sub(burnAmount));
        emit Transfer(sender, address(0), burnAmount);
      } else {
        emit Transfer(sender, recipient, amount);
      }
    } else {
      _balances[sender] = _balances[sender].sub(amount);
      _balances[recipient] = _balances[recipient].add(amount);
      emit Transfer(sender, recipient, amount);
    }
  }


  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements
   *
   * - `to` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }


  function mint(address account, uint256 amount) public onlyStakingContract {
    require(account != address(0), "ERC20: mint to the zero address");

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) external onlyStakingContract {
    require(account != address(0), "ERC20: burn from the zero address");
    _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function burn(uint256 amount) external {
    _balances[_msgSender()] = _balances[_msgSender()].sub(amount, "ERC20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(_msgSender(), address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   *
   * This is internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(address owner, address spender, uint256 amount) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
  
  function updateFreeze(bool _freeze) external onlyOwner {
      freeze = _freeze;
  }
  
      function mulDiv (uint x, uint y, uint z) public pure returns (uint) {
          (uint l, uint h) = fullMul (x, y);
          assert (h < z);
          uint mm = mulmod (x, y, z);
          if (mm > l) h -= 1;
          l -= mm;
          uint pow2 = z & -z;
          z /= pow2;
          l /= pow2;
          l += h * ((-pow2) / pow2 + 1);
          uint r = 1;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          return l * r;
    }
    
    function fullMul (uint x, uint y) private pure returns (uint l, uint h) {
          uint mm = mulmod (x, y, uint (-1));
          l = x * y;
          h = mm - l;
          if (mm < l) h -= 1;
    }
}