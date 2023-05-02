/**
 *Submitted for verification at Etherscan.io on 2023-04-28
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

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
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


interface IVeERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

/// @title VeERC20
/// @notice Modified version of ERC20 where transfers and allowances are disabled.
/// @dev Only minting and burning are allowed. The hook `_beforeTokenOperation` and
/// `_afterTokenOperation` methods are called before and after minting/burning respectively.
contract VeERC20 is Ownable, IVeERC20 {
    mapping(address => uint256) internal _balances;

    uint256 internal _totalSupply;

    string private _name;
    string private _symbol;

    /// @dev Emitted when `value` tokens are burned and minted
    event Burn(address indexed account, uint256 value);
    event Mint(address indexed beneficiary, uint256 value);
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);
    
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
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
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

        _beforeTokenOperation(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Mint(account, amount);
        emit Transfer(address(0), account, amount);
        _afterTokenOperation(account, _balances[account]);
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

        _beforeTokenOperation(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Burn(account, amount);
        emit Transfer(account, address(0), amount);
        _afterTokenOperation(account, _balances[account]);
    }

    /**
     * @dev Hook that is called before any minting and burning.
     * @param from the account transferring tokens
     * @param to the account receiving tokens
     * @param amount the amount being minted or burned
     */
    function _beforeTokenOperation(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any minting and burning.
     * @param account the account being affected
     * @param newBalance the new balance of `account` after minting/burning
     */
    function _afterTokenOperation(address account, uint256 newBalance) internal virtual {}
}

interface IToken {
    function mint(address _to, uint256 _amount) external;
    function burnFrom(address account_, uint256 amount_) external;
    function totalSupply() external returns (uint256);
}

/// @title veOCTO Token 
/// @notice Infinite supply, used to receive extra farming yields and voting power
contract veOCTOToken is VeERC20, ReentrancyGuard, Pausable{

    struct OrderInfo {
        uint lockDays;
        uint48 unlockTime;
        uint256 amount;
        uint256 veAmount;
    }

    struct UserInfo {
        // reserve usage for future upgrades
        OrderInfo[] orders;
    }

    /// @notice user info mapping
    mapping(address => UserInfo) internal users;
    mapping(address => bool) public minters;
    IToken immutable public octo;

    uint32 maxLength;
    uint public lockDays;
    uint256 public burningAmount;

    uint256 public constant maxSupply = 1000000000 ether;
    uint256 public constant per = 1 days;

    event Enter(address addr, uint256 unlockTime, uint256 veAmount);
    event Exit(address addr, uint256 unlockTime, uint256 veAmount, uint256 amount);
    event SetMaxLength(uint256 len);
    error VeOcto_OVERFLOW();

    
    constructor(address _octoToken) public VeERC20("veOCTO Token", "veOCTO") {
        octo = IToken(_octoToken);
        lockDays = 20;            // 20 days
    }

    /**
     * @dev pause pool, restricting certain operations
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev unpause pool, enabling certain operations
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    function setMaxLength(uint256 _maxLength) external onlyOwner {
        if (_maxLength > type(uint32).max) revert VeOcto_OVERFLOW();
        maxLength = uint32(_maxLength);
        emit SetMaxLength(_maxLength);
    }

    function setLockDays(uint _days) external onlyOwner {
        require(_days > 0,"invalid value!");
        lockDays = _days;                       // days 
    }

    function getUserInfo(address addr) external view returns (UserInfo memory) {
        return users[addr];
    }

    /// @dev Creates `_amount` token to `_to`. Must only be called by the minter 
    /// @param _to The address that will receive the mint
    /// @param _amount The amount to be minted
    function mint(address _to, uint256 _amount) external minter {
        uint256 total = octo.totalSupply();
        require(total <= maxSupply,"exceeds max supply!" );
        require(maxSupply - total - burningAmount - _totalSupply >= _amount,"exceeds max supply!" );
        _mint(_to, _amount);
    }

    /// @dev Destroys `_amount` tokens from `_from`. Callable only by the minter
    /// @param _from The address that will burn tokens
    /// @param _amount The amount to be burned
    function burnFrom(address _from, uint256 _amount) external minter {
        _burn(_from, _amount);
    }

    function lock(uint256 _amount) external minter {
        _lock(_amount);
    }

    function unlock(uint256 _amount) external minter{
        _unlock(_amount);
    }

    function _lock(uint256 _amount) internal  {
        burningAmount = burningAmount + _amount;
    }

    function _unlock(uint256 _amount) internal {
         burningAmount = burningAmount - _amount;
    }

    function readyTolock(uint256 _amount)
        external
        nonReentrant
        whenNotPaused
    {
        require(_amount > 0, 'amount to lock cannot be zero');
        octo.burnFrom(msg.sender,_amount);
        _mint(msg.sender, _amount);
    }
    /// @notice lock veOcto into contract and mint veOcto
    function readyToUnlock(uint256 _veAmount,uint _days)
        external
        nonReentrant
        whenNotPaused
    {
        require(_veAmount > 0, 'amount to Unlock cannot be zero');
        require(_balances[msg.sender] > _veAmount,"unlock amount exceeds balance!");
        require(_days > 0 && _days <= lockDays,"invalid days");
        if (_veAmount > uint256(type(uint104).max)) revert VeOcto_OVERFLOW();

        // assert call is not coming from a smart contract
        _assertNotContract(msg.sender);
        require(users[msg.sender].orders.length < uint256(maxLength), 'orders too much');
   
        uint256 unlockTime = block.timestamp + _days * per; // seconds in a day = 86400

        if (unlockTime > uint256(type(uint48).max)) revert VeOcto_OVERFLOW();
        if (_veAmount > uint256(type(uint104).max)) revert VeOcto_OVERFLOW();
        
        uint256 amount = _veAmount * _days / lockDays;
        users[msg.sender].orders.push(OrderInfo(_days,uint48(unlockTime),amount, uint104(_veAmount)));

        //
        _burn(msg.sender, _veAmount);
        _lock(_veAmount);
        emit Enter(msg.sender, unlockTime, _veAmount);
    }

    function claim(uint256 slot) external nonReentrant whenNotPaused {
        uint256 length = users[msg.sender].orders.length;
        require(slot < length, 'wut?');

        OrderInfo memory order = users[msg.sender].orders[slot];
        require(block.timestamp >= uint256(order.unlockTime), 'not yet meh');

        // remove slot
        if (slot != length - 1) {
            users[msg.sender].orders[slot] = users[msg.sender].orders[length - 1];
        }
        users[msg.sender].orders.pop();
        
        octo.mint(msg.sender,order.amount);
        emit Exit(msg.sender, order.unlockTime, order.veAmount, order.amount);
        
       _unlock(order.veAmount);        
    }

    /// @notice asserts addres in param is not a smart contract.
    /// @param _addr the address to check
    function _assertNotContract(address _addr) private view {
        require(_addr == tx.origin,'Smart contract depositors not allowed');
    }

    function addMinter(address _minter) public onlyOwner(){
        require(_minter != address(0), "invalid address!");
        require(isContract(_minter),"invalid address!");
        minters[_minter] = true;
    }

    function delMinter(address _minter) public onlyOwner(){
        require(_minter != address(0), "invalid address!");
        minters[_minter] = false;
    }

    modifier minter() {
        require(minters[msg.sender], "Ownable: caller is not the owner" );
        _;
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.
        return account.code.length > 0;
    }
}