// SPDX-License-Identifier: No License

pragma solidity ^0.7.3;

import "./utils/Initializable.sol";
import "./utils/Ownable.sol";
import "./utils/SafeMath.sol";
import "./interfaces/ICoverERC20.sol";

/**
 * @title CoverERC20 implements {ERC20} standards with expended features for COVER
 * @author [email protected]
 *
 * COVER's covToken Features:
 *  - Has mint and burn by owner (Cover contract) only feature.
 *  - No limit on the totalSupply.
 *  - Should only be created from Cover contract. See {Cover}
 */
contract CoverERC20 is ICoverERC20, Initializable, Ownable {
  using SafeMath for uint256;

  uint8 public constant decimals = 18;
  string public constant name = "covToken";

  // The symbol of  the contract
  string public override symbol;
  uint256 private _totalSupply;

  mapping(address => uint256) private balances;
  mapping(address => mapping (address => uint256)) private allowances;

  /// @notice Initialize, called once
  function initialize (string calldata _symbol) external initializer {
    symbol = _symbol;
    initializeOwner();
  }

  /// @notice Standard ERC20 function
  function balanceOf(address account) external view override returns (uint256) {
    return balances[account];
  }

  /// @notice Standard ERC20 function
  function totalSupply() external view override returns (uint256) {
    return _totalSupply;
  }

  /// @notice Standard ERC20 function
  function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  /// @notice Standard ERC20 function
  function allowance(address owner, address spender) external view virtual override returns (uint256) {
    return allowances[owner][spender];
  }

  /// @notice Standard ERC20 function
  function approve(address spender, uint256 amount) external virtual override returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  /// @notice Standard ERC20 function
  function transferFrom(address sender, address recipient, uint256 amount)
    external virtual override returns (bool)
  {
    _transfer(sender, recipient, amount);
    _approve(sender, msg.sender, allowances[sender][msg.sender].sub(amount, "CoverERC20: transfer amount exceeds allowance"));
    return true;
  }

  /// @notice New ERC20 function
  function increaseAllowance(address spender, uint256 addedValue) public virtual override returns (bool) {
    _approve(msg.sender, spender, allowances[msg.sender][spender].add(addedValue));
    return true;
  }

  /// @notice New ERC20 function
  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual override returns (bool) {
    _approve(msg.sender, spender, allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
    return true;
  }

  /// @notice COVER specific function
  function mint(address _account, uint256 _amount)
    external override onlyOwner returns (bool)
  {
    require(_account != address(0), "CoverERC20: mint to the zero address");

    _totalSupply = _totalSupply.add(_amount);
    balances[_account] = balances[_account].add(_amount);
    emit Transfer(address(0), _account, _amount);
    return true;
  }

  /// @notice COVER specific function
  function setSymbol(string calldata _symbol)
    external override onlyOwner returns (bool)
  {
    symbol = _symbol;
    return true;
  }

  /// @notice COVER specific function
  function burnByCover(address _account, uint256 _amount) external override onlyOwner returns (bool) {
    _burn(_account, _amount);
    return true;
  }

  /// @notice COVER specific function
  function burn(uint256 _amount) external override returns (bool) {
    _burn(msg.sender, _amount);
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "CoverERC20: transfer from the zero address");
    require(recipient != address(0), "CoverERC20: transfer to the zero address");

    balances[sender] = balances[sender].sub(amount, "CoverERC20: transfer amount exceeds balance");
    balances[recipient] = balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "CoverERC20: burn from the zero address");

    balances[account] = balances[account].sub(amount, "CoverERC20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "CoverERC20: approve from the zero address");
    require(spender != address(0), "CoverERC20: approve to the zero address");

    allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
}