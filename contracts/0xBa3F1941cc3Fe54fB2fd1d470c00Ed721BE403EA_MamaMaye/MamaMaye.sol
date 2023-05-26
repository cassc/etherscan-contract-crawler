/**
 *Submitted for verification at Etherscan.io on 2023-05-14
*/

// SPDX-License-Identifier: MIT

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
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

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// File: mamamaye.sol


pragma solidity ^0.8.19;


contract MamaMaye is ERC20 {
    address public admin;
    uint256 public currTime;
    uint256 public startingSupply = 803180033800000 * 10 ** 18;
    
    constructor() ERC20('MamaMaye Coin', 'MAMAMAYE') {
        _mint(msg.sender, 803180033800000 * 10 ** 18);
        admin = msg.sender;
    }
    
    function updateSupply(uint256 lastEnd, uint256 nestStart, uint256 currSupply) internal {
        currTime = block.timestamp;
        if (currTime > lastEnd && currTime < nestStart) {
            currSupply = currSupply *10 **18;
            if (startingSupply < currSupply) {
                _mint(admin, currSupply-startingSupply);
                startingSupply = currSupply;
            } else {
                revert ('SupplyForCurrentYearAlreadyAdjusted UseTimeMachineToChange');
            }
            
        } else {
            revert ('NotCurrentYear UseTimeMachineToGoThere');
        }
        
    }
    
    
    
    function USHER2024() external {
        updateSupply(17040671990000,17356896000000,810860525500000);
    }
    function USHER2025() external {
        updateSupply(17356895990000,17672256000000,818443745300000);
    }
    function USHER2026() external {
        updateSupply(17672255990000,17987616000000,825927665100000);
    }
    function USHER2027() external {
        updateSupply(17987615990000,18302976000000,833307831800000);
    }
    function USHER2028() external {
        updateSupply(18302975990000,18619200000000,840586330100000);
    }
    function USHER2029() external {
        updateSupply(18619199990000,18934560000000,847766072300000);
    }
    function USHER2030() external {
        updateSupply(18934559990000,19249920000000,854848737100000);
    }
    function USHER2031() external {
        updateSupply(19249919990000,19565280000000,861834945400000);
    }
    function USHER2032() external {
        updateSupply(19565279990000,19881504000000,868722787300000);
    }
    function USHER2033() external {
        updateSupply(19881503990000,20196864000000,875508351200000);
    }
    function USHER2034() external {
        updateSupply(20196863990000,20512224000000,882186270500000);
    }
    function USHER2035() external {
        updateSupply(20512223990000,20827584000000,888752422900000);
    }
    function USHER2036() external {
        updateSupply(20827583990000,21143808000000,895204888500000);
    }
    function USHER2037() external {
        updateSupply(21143807990000,21459168000000,901543761600000);
    }
    function USHER2038() external {
        updateSupply(21459167990000,21774528000000,907769364500000);
    }
    function USHER2039() external {
        updateSupply(21774527990000,22089888000000,913882856200000);
    }
    function USHER2040() external {
        updateSupply(22089887990000,22406112000000,919884738200000);
    }
    function USHER2041() external {
        updateSupply(22406111990000,22721472000000,925774548300000);
    }
    function USHER2042() external {
        updateSupply(22721471990000,23036832000000,931550815300000);
    }
    function USHER2043() external {
        updateSupply(23036831990000,23352192000000,937211824700000);
    }
    function USHER2044() external {
        updateSupply(23352191990000,23668416000000,942755538200000);
    }
    function USHER2045() external {
        updateSupply(23668415990000,23983776000000,948180327200000);
    }
    function USHER2046() external {
        updateSupply(23983775990000,24299136000000,953485467300000);
    }
    function USHER2047() external {
        updateSupply(24299135990000,24614496000000,958670774900000);
    }
    function USHER2048() external {
        updateSupply(24614495990000,24930720000000,963735732000000);
    }
    function USHER2049() external {
        updateSupply(24930719990000,25246080000000,968680014600000);
    }
    function USHER2050() external {
        updateSupply(25246079990000,25561440000000,973503390000000);
    }
    function USHER2051() external {
        updateSupply(25561439990000,25876800000000,978206175800000);
    }
    function USHER2052() external {
        updateSupply(25876799990000,26193024000000,982788544100000);
    }
    function USHER2053() external {
        updateSupply(26193023990000,26508384000000,987250156200000);
    }
    function USHER2054() external {
        updateSupply(26508383990000,26823744000000,991590525100000);
    }
    function USHER2055() external {
        updateSupply(26823743990000,27139104000000,995809874600000);
    }
    function USHER2056() external {
        updateSupply(27139103990000,27455328000000,999908516700000);
    }
    function USHER2057() external {
        updateSupply(27455327990000,27770688000000,1003888126200000);
    }
    function USHER2058() external {
        updateSupply(27770687990000,28086048000000,1007751808000000);
    }
    function USHER2059() external {
        updateSupply(28086047990000,28401408000000,1011503636000000);
    }
    function USHER2060() external {
        updateSupply(28401407990000,28717632000000,1015146968300000);
    }
    function USHER2061() external {
        updateSupply(28717631990000,29032992000000,1018683720900000);
    }
    function USHER2062() external {
        updateSupply(29032991990000,29348352000000,1022114904000000);
    }
    function USHER2063() external {
        updateSupply(29348351990000,29663712000000,1025441900400000);
    }
    function USHER2064() external {
        updateSupply(29663711990000,29979936000000,1028665835400000);
    }
    function USHER2065() external {
        updateSupply(29979935990000,30295296000000,1031787931500000);
    }
    function USHER2066() external {
        updateSupply(30295295990000,30610656000000,1034809807900000);
    }
    function USHER2067() external {
        updateSupply(30610655990000,30926016000000,1037733083000000);
    }
    function USHER2068() external {
        updateSupply(30926015990000,31242240000000,1040559053200000);
    }
    function USHER2069() external {
        updateSupply(31242239990000,31557600000000,1043288913600000);
    }
    function USHER2070() external {
        updateSupply(31557599990000,31872960000000,1045923950100000);
    }
    function USHER2071() external {
        updateSupply(31872959990000,32188320000000,1048465485800000);
    }
    function USHER2072() external {
        updateSupply(32188319990000,32504544000000,1050915040200000);
    }
    function USHER2073() external {
        updateSupply(32504543990000,32819904000000,1053274286100000);
    }
    function USHER2074() external {
        updateSupply(32819903990000,33135264000000,1055545000300000);
    }
    function USHER2075() external {
        updateSupply(33135263990000,33450624000000,1057728819500000);
    }
    function USHER2076() external {
        updateSupply(33450623990000,33766848000000,1059827417200000);
    }
    function USHER2077() external {
        updateSupply(33766847990000,34082208000000,1061842090900000);
    }
    function USHER2078() external {
        updateSupply(34082207990000,34397568000000,1063773681900000);
    }
    function USHER2079() external {
        updateSupply(34397567990000,34712928000000,1065622823300000);
    }
    function USHER2080() external {
        updateSupply(34712927990000,35029152000000,1067390445400000);
    }
    function USHER2081() external {
        updateSupply(35029151990000,35344512000000,1069077333500000);
    }
    function USHER2082() external {
        updateSupply(35344511990000,35659872000000,1070685242600000);
    }
    function USHER2083() external {
        updateSupply(35659871990000,35975232000000,1072217137500000);
    }
    function USHER2084() external {
        updateSupply(35975231990000,36291456000000,1073676544400000);
    }
    function USHER2085() external {
        updateSupply(36291455990000,36606816000000,1075066235300000);
    }
    function USHER2086() external {
        updateSupply(36606815990000,36922176000000,1076387402300000);
    }
    function USHER2087() external {
        updateSupply(36922175990000,37237536000000,1077640201900000);
    }
    function USHER2088() external {
        updateSupply(37237535990000,37553760000000,1078824894800000);
    }
    function USHER2089() external {
        updateSupply(37553759990000,37869120000000,1079941336600000);
    }
    function USHER2090() external {
        updateSupply(37869119990000,38184480000000,1080989230300000);
    }
    function USHER2091() external {
        updateSupply(38184479990000,38499840000000,1081968264300000);
    }
    function USHER2092() external {
        updateSupply(38499839990000,38816064000000,1082878095900000);
    }
    function USHER2093() external {
        updateSupply(38816063990000,39131424000000,1083718207700000);
    }
    function USHER2094() external {
        updateSupply(39131423990000,39446784000000,1084487879800000);
    }
    function USHER2095() external {
        updateSupply(39446783990000,39762144000000,1085186014500000);
    }
    function USHER2096() external {
        updateSupply(39762143990000,40078368000000,1085811158700000);
    }
    function USHER2097() external {
        updateSupply(40078367990000,40393728000000,1086361477600000);
    }
    function USHER2098() external {
        updateSupply(40393727990000,40709088000000,1086834763600000);
    }
    function USHER2099() external {
        updateSupply(40709087990000,41024448000000,1087228413400000);
    }
    function USHER2100() external {
        updateSupply(41024447990000,41339808000000,1087539371900000);
    }

}