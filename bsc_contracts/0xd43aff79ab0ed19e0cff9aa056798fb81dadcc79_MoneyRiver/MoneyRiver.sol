/**
 *Submitted for verification at BscScan.com on 2023-02-28
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/*

███    ███  ██████  ███    ██ ███████ ██    ██     ██████  ██ ██    ██ ███████ ██████  
████  ████ ██    ██ ████   ██ ██       ██  ██      ██   ██ ██ ██    ██ ██      ██   ██ 
██ ████ ██ ██    ██ ██ ██  ██ █████     ████       ██████  ██ ██    ██ █████   ██████  
██  ██  ██ ██    ██ ██  ██ ██ ██         ██        ██   ██ ██  ██  ██  ██      ██   ██ 
██      ██  ██████  ██   ████ ███████    ██        ██   ██ ██   ████   ███████ ██   ██ 
                                                                                       
    https://www.moneyriver.finance/                                                     

*/

/**
 * @dev Collection of functions related to the address type
 */
library Address {
   
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

}


/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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

}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol



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
contract ERC20 is Context, IERC20, IERC20Metadata {
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

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
        address to,
        uint256 amount
    ) internal virtual {}

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
}


contract MoneyRiver is ERC20, Ownable, ReentrancyGuard{
    struct User {
        uint256 level;
        address upline;
        uint256 referrals;
        uint256 pool_bonus;
        uint256 match_bonus;
        uint256 total_match_bonus;
        uint40  last_time;
        uint256 deposit;
        uint256 payouts;
        uint256 reinvest_bonus;
    }

    uint256 constant TIMEOUT_1DAY = 1 days;
    uint256 constant MIN_DEPOSIT = 0.1 ether;

    address[5] private _admins;
    uint256[5] private admin_fees=[ 3,3,3,3,1 ]; //3%, 3%, 3%, 3%, 1%
    mapping(address => User) public users;
    mapping(address => uint256) public blocked;

     
    uint256[17] public levels=[                         // levels #
        0.05 ether, 0.05 ether, 0.05 ether, 0.05 ether, //1-4
        10 ether, 10 ether, 10 ether,                   //5-7
        25 ether, 25 ether, 25 ether,                   //8-10
        50 ether, 50 ether, 50 ether,                   //11-13
        100 ether, 100 ether, 100 ether, 100 ether      //14-17
    ]; 
    
    uint8[17] public ref_bonuses=[20,10,10,10,10,7,7,7,7,5,5,5,5,5,3,3];
    uint8[5] public pool_bonuses=[37,27,17,12,5];
    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(address => uint256[17]) public referrals_count;
    mapping(uint8 => address) public pool_top;
    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    event Upline(address indexed addr, address indexed upline);
    event Deposit(address indexed addr, uint256 amount);
    event LevelPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount, uint256 total_days);
    event IncreaseRefCount(address,address,uint256);
    event MoveTop(address winner, uint256 position);

    constructor()  ERC20("Money River","MRV") {
        _admins[0]=0xb94AF5887257A712A9F6fbf74A1BC4B3BF20F17E;
        _admins[1]=0x0E81103D8aB3e11cA4581308284eaB166E9a23Bc;
        _admins[2]=0x24e827D170332C2039C49011a709607529CC0fF8;
        _admins[3]=0xd52b7513687887d85Af2e6D2E7418F7159f23C00;
        _admins[4]=0x33688a8A07e981A564FcFEB3295940A7696B1F79;
    }

    function available(address sender, uint256 total_days) external view returns(uint256 to_payout){
        to_payout= users[sender].deposit * users[msg.sender].reinvest_bonus /1000 * total_days;
        if(users[sender].pool_bonus > 0) {
            to_payout += users[sender].pool_bonus;
        }
        if(users[sender].match_bonus > 0) {
            to_payout += users[sender].match_bonus;
        }
    }
    receive() payable external {
        _deposit( msg.value );
    }

    function getRefCount(address sender) external view returns(uint256[17] memory){
        return referrals_count[sender];
    }
    
    function deposit(address _upline) payable external nonReentrant{
        require(msg.value >= MIN_DEPOSIT, "Minimal amount is 0.1 BNB");
      
        if (users[msg.sender].reinvest_bonus ==0 ){
            users[msg.sender].reinvest_bonus=10;
        }
        if ( users[msg.sender].deposit > 0){
            uint256 total_days = ((block.timestamp - users[msg.sender].last_time) / TIMEOUT_1DAY);
            if (total_days > 0){
                uint256 amount= users[msg.sender].deposit * users[msg.sender].reinvest_bonus /1000 * total_days;
                _reinvest(amount);
            }
        }
        _setUpline(msg.sender, _upline);
        address up=msg.sender;
        for(uint8 i = 0; i < levels.length; i++) {
            if (up == address(0)) break;
            if (i > users[up].level){
                users[up].level=i;
            }
            up=users[up].upline;
        }
        _deposit( msg.value);
        adminPayouts(msg.value * 13 / 100 );
    }

    function reinvest() external nonReentrant{
        require(blocked[msg.sender] < block.timestamp, "Locked after reinvest or withdraw");
        blocked[msg.sender] = block.timestamp + TIMEOUT_1DAY;
        uint256 total_days = ((block.timestamp - users[msg.sender].last_time) / TIMEOUT_1DAY);
        uint256 amount= users[msg.sender].deposit *  users[msg.sender].reinvest_bonus /1000 * total_days;
        require(amount > 0, "Zero payout");
        _reinvest(amount);
        adminPayouts(amount * 13 / 100 );
        users[msg.sender].reinvest_bonus+=1;
        if(users[msg.sender].reinvest_bonus >40){
            users[msg.sender].reinvest_bonus=40;
        }
    }
    
    function withdraw() external nonReentrant{
        require(blocked[msg.sender] < block.timestamp, "Locked after reinvest or withdraw");
        blocked[msg.sender] = block.timestamp + TIMEOUT_1DAY;
        uint256 total_days = ((block.timestamp - users[msg.sender].last_time) / TIMEOUT_1DAY);
        uint256 to_payout= users[msg.sender].deposit * users[msg.sender].reinvest_bonus /1000 * total_days;
        uint256 admin_bonus=_refPayout(msg.sender, to_payout);
        to_payout += users[msg.sender].pool_bonus;
        users[msg.sender].pool_bonus = 0;
        to_payout += users[msg.sender].match_bonus;
        users[msg.sender].match_bonus = 0;
        require(to_payout > 0, "Zero payout");
        users[msg.sender].payouts += to_payout;
        users[msg.sender].reinvest_bonus=10;
        users[msg.sender].last_time = uint40(block.timestamp);
        total_withdraw += to_payout;
        Address.sendValue(payable(msg.sender), to_payout);
        emit Withdraw(msg.sender, to_payout, total_days);
        adminPayouts(admin_bonus);
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint40 _pool_last_draw, uint256 _pool_balance, uint256 _pool_lider) {
        return (total_users, total_deposited, total_withdraw, pool_last_draw, pool_balance, pool_users_refs_deposits_sum[pool_cycle][pool_top[0]]);
    }

    function poolTopInfo() view external returns(address[5] memory addrs, uint256[5] memory deps) {
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;
            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    }

    function _deposit(uint256 _amount) private {
        users[msg.sender].deposit += _amount;
        users[msg.sender].last_time = uint40(block.timestamp);
        total_deposited += _amount;
        _poolDeposits(msg.sender, _amount);
        if(pool_last_draw + TIMEOUT_1DAY < block.timestamp) {
            _drawPool();
        }
        emit Deposit(msg.sender, _amount);
    }

    function _reinvest(uint256 amount) private{
        amount += users[msg.sender].pool_bonus;
        users[msg.sender].pool_bonus = 0;
        amount += users[msg.sender].match_bonus;
        users[msg.sender].match_bonus = 0;
        _deposit( amount );
        _mint(msg.sender, amount * 100);
    }

    function _drawPool() private {
        pool_last_draw = uint40(block.timestamp);
        pool_cycle++;
        uint256 draw_amount = pool_balance / 10;
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;
            uint256 win = draw_amount * pool_bonuses[i] / 100;
            users[pool_top[i]].pool_bonus += win;
            pool_balance -= win;
            emit PoolPayout(pool_top[i], win);
            pool_top[i] = address(0);
        }
    }   

    function _poolDeposits(address _addr, uint256 _amount) private {
        pool_balance += _amount * 4 / 100;
        address upline = users[_addr].upline;
        if(upline == address(0)) return;
        pool_users_refs_deposits_sum[pool_cycle][upline] += _amount;
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            emit MoveTop(upline,i);
            if(pool_top[i] == upline) break;
            if(pool_top[i] == address(0)) {
                pool_top[i] = upline;
                break;
            }
            if(pool_users_refs_deposits_sum[pool_cycle][upline] > pool_users_refs_deposits_sum[pool_cycle][pool_top[i]]) {
                for(uint8 j = i + 1; j < pool_bonuses.length; j++) {
                    if(pool_top[j] == upline) {
                        for(uint8 k = j; k <= pool_bonuses.length; k++) {
                            pool_top[k] = pool_top[k + 1];
                        }
                        break;
                    }
                }
                for(uint8 j = uint8(pool_bonuses.length - 1); j > i; j--) {
                    pool_top[j] = pool_top[j - 1];
                }
                pool_top[i] = upline;
                break;
            }
        }
    }

    function _refPayout(address _addr, uint256 _amount) private returns(uint256 admin_bonus){
        if (_amount == 0) return 0;
        address up = users[_addr].upline;
        admin_bonus=0;
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) {
                admin_bonus+=_amount * ref_bonuses[i] / 100;
            }else{
                uint256 bonus = _amount * ref_bonuses[i] / 100;
                if ( users[up].deposit >=levels[i] ){
                    users[up].match_bonus += bonus;
                    users[up].total_match_bonus += bonus;
                    emit LevelPayout(up, _addr, bonus);
                }else{
                    admin_bonus+=bonus;
                }
                up = users[up].upline;
            }
        }
    }

    function _setUpline(address _addr, address _upline) private {
        if (users[_addr].upline != address(0)) return;
        if (_upline == address(0) || _addr == _upline || users[_upline].upline==address(0)) _upline=owner();
        users[_addr].upline = _upline;
        users[_upline].referrals++;
        emit Upline(_addr, _upline);
        total_users++;
        address[17] memory path;
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(_upline == address(0)) break;
            path[i]=_upline;
            _upline = users[_upline].upline;
            referrals_count[path[i]][i]++;
            emit IncreaseRefCount(msg.sender, path[i],referrals_count[path[i]][i]);
        }
    }
    
    function adminPayouts(uint256 amount) internal{
        for(uint256 i=0; i<admin_fees.length; i++){
            Address.sendValue(payable(_admins[i]), amount * admin_fees[i] / 13);
        }
    }
}