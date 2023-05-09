pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol" ;

interface IERC20Metadata is IERC20 {

 function name() external view returns (string memory);


 function symbol() external view returns (string memory);


}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol




pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol" ;


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
 mapping(address => uint256) private _balances;

 mapping(address => mapping(address => uint256)) private _allowances;

 uint256 private _totalSupply;

 string private _name;
 string private _symbol;


 constructor(string memory name_, string memory symbol_) {
 _name = name_;
 _symbol = symbol_;
 }

 
 function name() public view virtual override returns (string memory) {
 return _name;
 }

 
 function symbol() public view virtual override returns (string memory) {
 return _symbol;
 }

 
 

 function totalSupply() public view virtual override returns (uint256) {
 return _totalSupply;
 }


 function balanceOf(address account) public view virtual override returns (uint256) {
 return _balances[account];
 }

 
 function transfer(address to, uint256 amount) public virtual override returns (bool) {
 address owner = _msgSender();
 _transfer(owner, to, amount);
 return true;
 }


 function allowance(address owner, address spender) public view virtual override returns (uint256) {
 return _allowances[owner][spender];
 }

 
 function approve(address spender, uint256 amount) public virtual override returns (bool) {
 address owner = _msgSender();
 _approve(owner, spender, amount);
 return true;
 }


 function transferFrom(
 address from,
 address to,
 uint256 amount
 ) public virtual override returns (bool) {
 address spender = _msgSender();
 _spendAllowance(from, spender, amount);
 _transfer(from, to, amount);
 return true;
 }
 
 


 function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
 address owner = _msgSender();
 _approve(owner, spender, allowance(owner, spender) + addedValue);
 return true;
 }


 function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
 address owner = _msgSender();
 uint256 currentAllowance = allowance(owner, spender);
 require(currentAllowance >= subtractedValue, "Decreased allowance below zero");
 unchecked {
 _approve(owner, spender, currentAllowance - subtractedValue);
 }

 return true;
 }

 
 

 function _transfer(
 address from,
 address to,
 uint256 amount
 ) internal virtual {
 require(from != address(0), "Transfer from the zero");
 require(to != address(0), "Transfer to the zero");

 _beforeTokenTransfer(from, to, amount);

 uint256 fromBalance = _balances[from];
 require(fromBalance >= amount, "Transfer amt exceeds bal");
 unchecked {
 _balances[from] = fromBalance - amount;
 // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
 // decrementing then incrementing.
 _balances[to] += amount;
 }

 emit Transfer(from, to, amount);

 _afterTokenTransfer(from, to, amount);
 }


 function _mint(address account, uint256 amount) internal virtual {
 require(account != address(0), "Mint to the zero");

 _beforeTokenTransfer(address(0), account, amount);

 _totalSupply += amount;
 unchecked {
 // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
 _balances[account] += amount;
 }
 emit Transfer(address(0), account, amount);

 _afterTokenTransfer(address(0), account, amount);
 }


 function _burn(address account, uint256 amount) internal virtual {
 require(account != address(0), "Burn from the zero");

 _beforeTokenTransfer(account, address(0), amount);

 uint256 accountBalance = _balances[account];
 require(accountBalance >= amount, "Burn amt exceeds bal");
 unchecked {
 _balances[account] = accountBalance - amount;
 // Overflow not possible: amount <= accountBalance <= totalSupply.
 _totalSupply -= amount;
 }

 emit Transfer(account, address(0), amount);

 _afterTokenTransfer(account, address(0), amount);
 }

 
 function _approve(
 address owner,
 address spender,
 uint256 amount
 ) internal virtual {
 require(owner != address(0), "Approve from the zero");
 require(spender != address(0), "Approve to the zero");

 _allowances[owner][spender] = amount;
 emit Approval(owner, spender, amount);
 }

 
 function _spendAllowance(
 address owner,
 address spender,
 uint256 amount
 ) internal virtual {
 uint256 currentAllowance = allowance(owner, spender);
 if (currentAllowance != type(uint256).max) {
 require(currentAllowance >= amount, "Insufficient allowance");
 unchecked {
 _approve(owner, spender, currentAllowance - amount);
 }
 }
 }

 
 function _beforeTokenTransfer(
 address from,
 address to,
 uint256 amount
 ) internal virtual {}


 function _afterTokenTransfer(
 address from,
 address to,
 uint256 amount
 ) internal virtual {}
}

// File: @openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol




pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";


abstract contract ERC20Burnable is Context, ERC20 {
 
 function burn(uint256 amount) public virtual {
 _burn(_msgSender(), amount);
 }


 function burnFrom(address account, uint256 amount) public virtual {
 _spendAllowance(account, _msgSender(), amount);
 _burn(account, amount);
 }
}

// File: contracts/DollarToken.sol


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Dollar is ERC20, ERC20Burnable, Ownable {
 uint256 private constant INITIAL_SUPPLY = 12345678900 * 10**18;
 bool private limited;

    uint256 private maxHoldingAmount;

    uint256 private minHoldingAmount;

    address private uniswapV2Pair;

    mapping(address => bool) private blacklists;

 constructor() ERC20("Dollar coin", "DOLLAR") {
 _mint(msg.sender, INITIAL_SUPPLY);
 }

 function blacklist(address _address, bool _isBlacklisting) external onlyOwner {

        blacklists[_address] = _isBlacklisting;

    }

   function setRule(bool _limited, address _uniswapV2Pair, uint256 _maxHoldingAmount, uint256 _minHoldingAmount) external onlyOwner {

        limited = _limited;

        uniswapV2Pair = _uniswapV2Pair;

        maxHoldingAmount = _maxHoldingAmount;

        minHoldingAmount = _minHoldingAmount;

    }  


 function _beforeTokenTransfer(

        address from,

        address to,

        uint256 amount

    ) override internal virtual {

        require(!blacklists[to] && !blacklists[from], "Blacklisted");

        if (uniswapV2Pair == address(0)) {

            require(from == owner() || to == owner(), "trading is not started");

            return;

        }

        if (limited && from == uniswapV2Pair) {

            require(super.balanceOf(to) + amount <= maxHoldingAmount && super.balanceOf(to) + amount >= minHoldingAmount, "Forbid");

        }

    }
 function distributeTokens(address distributionWallet) external onlyOwner {
 uint256 supply = balanceOf(msg.sender);
 require(supply == INITIAL_SUPPLY, "Tokens already distributed");

 _transfer(msg.sender, distributionWallet, supply);
 }
}