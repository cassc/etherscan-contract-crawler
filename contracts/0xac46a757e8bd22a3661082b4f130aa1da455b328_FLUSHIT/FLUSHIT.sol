/**
 *Submitted for verification at Etherscan.io on 2023-08-01
*/

/**
 *Submitted for verification at snowtrace.io on 2022-04-04
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }
}

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
    _setOwner(_msgSender());
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
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _setOwner(newOwner);
  }

  function _setOwner(address newOwner) private {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) 
  {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
      require(b > 0, errorMessage);
      uint256 c = a / b;
      return c;
  }
}

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
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract FLUSHIT is Ownable {
  using SafeMath for uint256;

  address constant DOOKIE = 0xb8EF3a190b68175000B74B4160d325FD5024760e;
  address constant USDC = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
  uint256 public RFV = 7000;

  constructor() Ownable() {}

  // _RFV must be given with 2 decimals -> $1.50 = 150
  function setRfv(uint256 _RFV) external onlyOwner {
    RFV = _RFV;
  }

  function transfer(
    address _to,
    uint256 _amount,
    address _token
  ) external onlyOwner {
    require(
      _amount <= IERC20(_token).balanceOf(address(this)),
      "Not enough balance"
    );

    IERC20(_token).transfer(_to, _amount);
  }

  // Amount must be given in DOOKIE, which has 9 decimals
  function swap(uint256 _amount) external {
    require(_amount <= IERC20(DOOKIE).balanceOf(msg.sender), "You need more DOOKIE");
    require(_amount > 0, "amount is 0");

    require(
      IERC20(DOOKIE).allowance(msg.sender, address(this)) >= _amount,
      "You need to approve this contract to spend your DOOKIE"
    );

    IERC20(DOOKIE).transferFrom(msg.sender, address(this), _amount);

    uint256 _value = _amount.mul(RFV).div( 100000 );

    require(
      _value <= IERC20(USDC).balanceOf(address(this)),
      "Please wait "
    );
    IERC20(USDC).transfer(msg.sender, _value);
  }
}