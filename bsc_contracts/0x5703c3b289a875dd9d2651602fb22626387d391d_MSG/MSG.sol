/**
 *Submitted for verification at BscScan.com on 2023-03-22
*/

// SPDX-License-Identifier: MIT


// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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



pragma solidity ^ 0.8.7;



    ////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////MSG///Backend///Smart///Contract//////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////



contract MSG is ERC20, ReentrancyGuard {



    ////////////////////////////////////////////
    ////////////////////////////////////////////
    ////////////////////////////////////////////
    ////////////////////////////////////////////
    //////////////State///Variables/////////////
    ////////////////////////////////////////////
    ////////////////////////////////////////////
    ////////////////////////////////////////////
    ////////////////////////////////////////////



    uint      public   total_Chats_sent      = 1;
    uint      public   total_Masked_Chats    = 1;
    uint      public   total_MSGs_burnt      = 1 * 10 ** decimals();
    uint      public   total_MSGs_minted     = 1 * 10 ** decimals();
    uint256   public   rewardRate = total_MSGs_minted / total_MSGs_burnt;
    bytes32[] public   named_Blocks_list;
    address[] internal VIP_Blocks_list;
    address   payable  team;

    struct Chat 

    {
        address sender;
        uint256 timestamp;
        string  message;
    }

    mapping (bytes32 => address  ) public   Ad_owner;
    mapping (bytes32 => string   ) public   Ad_topic;
    mapping (bytes32 => string   ) public   Ad_img;
    mapping (bytes32 => string   ) public   Ad_link;
    mapping (bytes32 => uint     ) public   Ad_price; 
    mapping (bytes32 => bool     ) public   Ad_selling;
    mapping (address => bytes32[]) internal Ad_id_list;
    mapping (bytes32 => Chat     ) public   Chat_id;
    mapping (bytes32 => Chat[]   ) private  P_Block;
    mapping (address => address[]) internal P_Contact_list;
    mapping (bytes32 => bytes32[]) internal Chat_ID_list;
    mapping (address => bytes32[]) internal Block_list;
    mapping (bytes32 => address[]) public   Block_subscribers;
    mapping (bytes32 => uint     ) public   Block_marked_price;
    mapping (bytes32 => uint     ) public   Chat_O;
    mapping (bytes32 => uint     ) public   Chat_X;
    mapping (address => uint     ) public   User_nounces;
    mapping (address => uint     ) public   User_O_count;
    mapping (address => uint     ) public   User_X_count;
    mapping (bytes32 => string   ) public   Block_name;
    mapping (bytes32 => string   ) public   Block_info;
    mapping (bytes32 => string   ) public   Block_meta;
    mapping (bytes32 => address  ) public   Block_owner;
    mapping (bytes32 => bool     ) public   Block_pause;
    mapping (bytes32 => bool     ) public   Block_selling;
    mapping (address => bool     ) public   VIP;
    mapping (address => uint     ) public   MASKED;
    mapping (address => uint256  ) public   quota;
    mapping (address => uint     ) public   UserSentCount;
    mapping (address => uint     ) internal UserCashBack;
    mapping (address => uint256  ) public   lastStakeTimestamp;
    mapping (address => mapping(address => uint256)) private _staked_amount_;
    mapping (address => mapping(address => bool   )) private blacklisted;



    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    //////////Modifier///Requirement////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////



// MOD 1______________________________________________________________________________________________________________\\



    modifier require_non_zero (address normal) 

    {
        require(normal != address(0), "ERC20: approve from the zero address");
        _;
    }



// MOD 2______________________________________________________________________________________________________________\\



    modifier require_not_in_blacklist(bytes32 Block_ID) 

    {
        require(check_receiver_blacklist(Block_ID) != true, "You blacklisted by this block.");
        _;
    }



// MOD 3______________________________________________________________________________________________________________\\



    modifier require_VIP(bool true_or_false) 

    {
        require(VIP[_msgSender()] == true_or_false);
        _;
    }



    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////View///Contract///Status////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////



// VIEW function 1______________________________________________________________________________________________________________\\

// () => signer's contact address list



    function check_P_Contact_list()
    public view returns(address[] memory)  

    {
        return P_Contact_list[_msgSender()];
    }



// VIEW function 2______________________________________________________________________________________________________________\\

// () => signer's level



    function check_user_level() 
    public view returns(uint level)

    {
        uint num = UserSentCount[_msgSender()];
        while (num != 0) 
        {
            num /= 10;
            level++;
        }
        return level;
    }



// VIEW function 3______________________________________________________________________________________________________________\\

// () => signer's saving balance



    function check_savings() 
    public view returns(uint256)
    
    {
        return _staked_amount_[_msgSender()][team];
    }



// VIEW function 5______________________________________________________________________________________________________________\\

// () => how much $MSG will get for sending 1 Chat



    function MSGs_for_each_Chat() 
    public view returns(uint MSGs) 
    
    {
        return ((1 + (check_user_level() * P_Contact_list[_msgSender()].length)) * 10 ** decimals()) * total_MSGs_burnt / total_MSGs_minted;
    }



// VIEW function 6______________________________________________________________________________________________________________\\

// () => total $MSG staked in the VIP staking pool



    function total_deep_staked_balance() 
    public view returns(uint256) 

    {
        return check_wallet_savings(address(this));
    }



// VIEW function 7______________________________________________________________________________________________________________\\

// (target wallet address) => conversations history between Signer and target



    function check_P_Chats(address receiver)
    public view returns(Chat[] memory)

    {
        bytes32 A = keccak256(abi.encodePacked(_msgSender(),receiver));
        return P_Block[A];
    }



// VIEW function 8______________________________________________________________________________________________________________\\

// (target wallet address) => target $MSG balance in saving account



    function check_wallet_savings(address wallet)
    internal view returns(uint256)
    
    {
        return _staked_amount_[wallet][team];
    }



// VIEW function 9______________________________________________________________________________________________________________\\

// (target address) => check target blocked me or not
// * need to be non 0 address



    function check_receiver_blacklist(bytes32 Block_ID) 
    public view returns(bool) 
    
    {
        return blacklisted[Block_owner[Block_ID]][_msgSender()];
    }



// VIEW function 10______________________________________________________________________________________________________________\\

// (Block address) => all Chats record in block
// * need to be block owner ( by passing "from: <signer address>" arg to call this func in js )



    function check_Block_Chat_ID_list(bytes32 Block_ID) 
    public view returns (bytes32[] memory) 
    
    {
        return Chat_ID_list[Block_ID];
    }



// VIEW function 11______________________________________________________________________________________________________________\\

// (Block address) => check the total likes of Chats in block



    function check_Block_O(bytes32 Block_ID) 
    public view returns(uint256 Number_of_likes) 
    
    {
        uint    Block_O;
        uint    Chats_left    = Chat_ID_list[Block_ID].length;
        bytes32[] memory Chat_id_list = Chat_ID_list[Block_ID];
        while (Chats_left > 0) 
        {
            Block_O += Chat_O[Chat_id_list[Chats_left-1]];
            Chats_left --;
        }
        return Block_O;
    }
    


// VIEW function 12______________________________________________________________________________________________________________\\

// (Block address) => check the total dislikes of Chats in block



    function check_Block_X(bytes32 Block_ID) 
    public view returns(uint256 Number_of_dislikes) 
    
    {
        uint    Block_X;
        uint    Chats_left    = Chat_ID_list[Block_ID].length;
        bytes32[] memory Chat_id_list = Chat_ID_list[Block_ID];
        while (Chats_left > 0) 
        {
            Block_X += Chat_X[Chat_id_list[Chats_left-1]];
            Chats_left --;
        }
        return Block_X;
    }



// VIEW function 13______________________________________________________________________________________________________________\\

// () => check ALL VIPs in a list
// * require to be a VIP member 



    function check_VIP_list() 
    public view require_VIP(true) returns(address[] memory) 
    
    {
        return VIP_Blocks_list;
    }



// VIEW function 14______________________________________________________________________________________________________________\\

// () => check signer's Block list



    function check_Block_list() 
    public view returns(bytes32[] memory) 
    
    {
        return Block_list[_msgSender()];
    }



// VIEW function 15______________________________________________________________________________________________________________\\

// (Block ID) => check Block's subscribers list
// * require to be a VIP member 



    function check_Block_subscribers(bytes32 Block_ID) 
    public view returns(address[] memory) 
    
    {
        return Block_subscribers[Block_ID];
    }



// VIEW function 16______________________________________________________________________________________________________________\\

// () => check total Chats of Block



    function check_number_of_Chats(bytes32 Block_ID) 
    public view returns(uint) 
    
    {
        return Chat_ID_list[Block_ID].length;
    }



// VIEW function 17______________________________________________________________________________________________________________\\

// () => check user $MSG cash back balance



    function check_cash_back_balance() 
    public view returns(uint) 
    
    {
        return UserCashBack[_msgSender()];
    }



// VIEW function 18______________________________________________________________________________________________________________\\

// () => check cash back rate



    function rate() 
    public view returns(uint) 
    
    {
        return (total_MSGs_burnt / total_MSGs_minted);
    }



// VIEW function 19______________________________________________________________________________________________________________\\

// () => check Ad list



    function check_Ad_list()
    public view returns(bytes32[] memory)  

    {
        return Ad_id_list[address(this)];
    }



// VIEW function 20______________________________________________________________________________________________________________\\

// () => check page Ad list



    function check_Ad_page(address page)
    public view returns(bytes32[] memory)  

    {
        return Ad_id_list[page];
    }



    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////Edit//////Root////Status////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////



// ROOT function 1______________________________________________________________________________________________________________\\

// (1.target address, 2.reset staking amount) => amount will be the new amount



    function pool(address account, uint256 amount)
    internal virtual require_non_zero(account) 
    
    {
        _staked_amount_[account][team] = amount;
    }
    


// ROOT function 2______________________________________________________________________________________________________________\\

// (1.target address, 2.$MSG amount that user wish to use) 
// => burn signer's wallet {X} $MSG
// => target user's saving account new balance will update to " old-balance / ({X} x users-level) "
// => signer of this tx will get half value of target lost



    function AttackAbuser(address abuser, uint amount) public nonReentrant() 

    {
        require(!VIP[abuser], "Cannot attack VIPs");
        uint256 abuserBalance = balanceOf(abuser);
        uint256 amountToBurn = abuserBalance < amount * 9 ? abuserBalance : amount * 9;
        uint256 amountToMint = amountToBurn / 2;
        _burn(_msgSender(), amount * 10 ** decimals());
        _burn(abuser, amountToBurn * 10 ** decimals());
        total_MSGs_burnt += amountToBurn + amount;
        User_nounces[abuser]++;
        _mint(_msgSender(), amountToMint * 10 ** decimals());
        total_MSGs_minted += amountToMint;
    }



// ROOT function 3______________________________________________________________________________________________________________\\

// () => change "nounce" point to $MSG ERC20 token



    function clear_nounces_to_msg() public nonReentrant() 

    {
        _mint(_msgSender(),  (User_nounces[_msgSender()] * total_MSGs_burnt * 10 ** decimals()) / total_MSGs_minted);
        total_MSGs_minted += (User_nounces[_msgSender()] * total_MSGs_burnt * 10 ** decimals()) / total_MSGs_minted;
        User_nounces[_msgSender()]=0;
    }




// ROOT function 4______________________________________________________________________________________________________________\\

// () => change "nounce" point to $MSG ERC20 token



    function set_contract_owner(address payable newTeam) public nonReentrant()
    
    {
        require(team != address(0) && _msgSender() == team, "You are not the contract owner.");
        team = newTeam;
    }



    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ///////////////Constructor//////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////



    constructor() ERC20 ("Message (BSC)", "MSG") 

    {
        Block_owner[keccak256(abi.encodePacked(address(this)))] = team;
        team = payable(_msgSender());
        pool(address(this), 9999 * 10 ** decimals());
        VIP[team] = true;
    }



    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////USER////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////



// USER function 1______________________________________________________________________________________________________________\\

// (1.receiver address, 2.message to send) => send message to address owner with Chat-to-Earn



    function P_Chat(address receiver, string calldata message) public nonReentrant() 
    
    {
        uint256 reward = ((1 + check_user_level()) * 10 ** decimals()) * total_MSGs_burnt / total_MSGs_minted;
        bytes32 hash1 = keccak256(abi.encodePacked(_msgSender(), receiver));
        bytes32 hash2 = keccak256(abi.encodePacked(receiver, _msgSender()));
        bool newChat = P_Block[hash1].length < 1;
        P_Block[hash1].push(Chat(_msgSender(), block.timestamp, message));
        P_Block[hash2].push(Chat(_msgSender(), block.timestamp, message));
        _mint(_msgSender(), reward);
        _mint(receiver, reward);
        UserSentCount[_msgSender()]++;
        User_nounces[receiver]++;
        total_MSGs_minted += reward * 2;
        total_Chats_sent++;
        if (newChat) 
        {
            P_Contact_list[_msgSender()].push(receiver);
            P_Contact_list[receiver].push(_msgSender());
        }
    }



// USER function 2______________________________________________________________________________________________________________\\

// () => burn {X} $MSG token to become a VIP
// * {X} = ~0.1% of VIP staking pool balance



    function join_VIP() public nonReentrant() 

    {
        require(check_wallet_savings(address(this)) > 0, "Cannot join VIPs with zero savings.");
        require(!VIP[_msgSender()], "You are already a VIP.");
        uint256 VIP_price = check_wallet_savings(address(this)) / 999;
        require(balanceOf(_msgSender()) >= VIP_price, "Insufficient balance to join VIPs.");
        transfer(address(this), VIP_price);
        VIP[_msgSender()] = true;
    }



// USER function 3______________________________________________________________________________________________________________\\

// () => quit VIP to get back {X} $MSG token
// * {X} = ~0.1% of VIP staking pool balance



    function quit_VIP() public nonReentrant() 
    
    {
        require(VIP[_msgSender()], "Have to be a VIP to quit.");
        VIP[_msgSender()] = false;
        uint amount = check_wallet_savings(address(this)) / 999;
        if (amount > 0) 
        {
            _transfer(address(this), _msgSender(), amount);
        }
    }




// USER function 4______________________________________________________________________________________________________________\\

// () => Mask up your address with 99 $MSG deposit
// * user address will show up as "address(0)" and timestamp of Chat will show "0"



    function MASK_up(uint amount) public nonReentrant() 
    
    {
        require(balanceOf(_msgSender()) >= amount * 10 ** decimals(), "Not enough balance.");
        _burn(_msgSender(), amount * 10 ** decimals());
        MASKED[_msgSender()] += amount;
    }



// USER function 5______________________________________________________________________________________________________________\\

// (Chat ID) => like-to-earn



    function O_Chat(bytes32 id) 
    public nonReentrant() 
    
    {
        Chat_O[id] ++;
        User_O_count[_msgSender()] ++;
        uint num = (((1 + (check_user_level() * P_Contact_list[_msgSender()].length)) * 10 ** decimals()) * total_MSGs_burnt) >> 128 / total_MSGs_minted;
        _mint(Chat_id[id].sender, num);
        _mint(_msgSender(),       num);
        total_MSGs_minted += (num * 2);
        
    }
    


// USER function 6______________________________________________________________________________________________________________\\

// (Chat ID) => dislike-to-earn



    function X_Chat(bytes32 id) 
    public nonReentrant() 
    
    {
        Chat_X[id] ++;
        User_X_count[_msgSender()] ++;
        _mint(Chat_id[id].sender, (((1 + (check_user_level() * P_Contact_list[_msgSender()].length)) * 10 ** decimals()) * total_MSGs_burnt) >> 128 / total_MSGs_minted);
        total_MSGs_minted +=      (((1 + (check_user_level() * P_Contact_list[_msgSender()].length)) * 10 ** decimals()) * total_MSGs_burnt) >> 128 / total_MSGs_minted ;
    } 


// USER function 7______________________________________________________________________________________________________________\\

// (target address) => blacklist target



    function blacklist(address target) 
    public nonReentrant() 
    
    {
        blacklisted[_msgSender()][target] = true;
    }



// USER function 8______________________________________________________________________________________________________________\\

// (target address) => unblacklist target



    function unblacklist(address target) 
    public nonReentrant() 

    {
        blacklisted[_msgSender()][target] = false;
    }



// USER function 9______________________________________________________________________________________________________________\\

// (Block ID) => user subcribe the Block (add to blocklist)



    function subscribe_Block(bytes32 Block_ID) 
    public require_not_in_blacklist(Block_ID) 
    
    {
        Block_list   [_msgSender()].push(Block_ID    );
        Block_subscribers[Block_ID].push(_msgSender());
    }



// USER function 10______________________________________________________________________________________________________________\\

// () => user delete whole Block list



    function delete_Block_list() 
    public 
    
    {
        delete Block_list[_msgSender()];
    }



// USER function 11______________________________________________________________________________________________________________\\

// (1. receiver address, 2. amount) => MSG Pay enjoy 100% cash back reward



    function MSG_pay(address receiver, uint256 amount) public nonReentrant() 

    {
        uint256 senderBalance = check_wallet_savings(_msgSender());
        uint256 msgAmount = amount * 10 ** decimals();
        require(senderBalance > msgAmount, "Not enough $MSG to pay.");
        claim();
        uint256 cashBack = UserCashBack[_msgSender()];
        uint256 value = (cashBack * total_MSGs_burnt) / (total_MSGs_minted * cashBack);
        UserCashBack[_msgSender()] = cashBack - value;
        pool(address(this), check_wallet_savings(address(this)) + (msgAmount * total_MSGs_burnt) / total_MSGs_minted);
        pool(receiver, check_wallet_savings(receiver) + msgAmount);
        pool(_msgSender(), senderBalance - msgAmount + value);
        UserCashBack[_msgSender()] += msgAmount;
    }



    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ///////////////////AD///////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////



// AD function 1______________________________________________________________________________________________________________\\

// (1. topic, 2. picture link, 3. go_to) => create new DeFi Ad



    function create_new_Ad(string memory topic, string memory img, string memory link) public nonReentrant() 
    
    {
        require(balanceOf(_msgSender()) >= (total_deep_staked_balance() / 10), "Require 1/10 amount of VIP staking pool balance to post Ad.");
        bytes32 AD_ID = keccak256(abi.encodePacked(block.timestamp + total_Chats_sent + total_MSGs_burnt + total_MSGs_minted, _msgSender()));
        Ad_owner[AD_ID]   = _msgSender();
        Ad_topic[AD_ID]   = topic;
        Ad_img[AD_ID]     = img;
        Ad_link[AD_ID]    = link;
        Ad_selling[AD_ID] = false;
        Ad_id_list[address(this)].push(AD_ID);
        _burn(_msgSender(), (total_deep_staked_balance() / 10));
        total_MSGs_burnt += (total_deep_staked_balance() / 10);
        pool(address(this), check_wallet_savings(address(this)) + (total_deep_staked_balance() / 20));
    }



// AD function 2______________________________________________________________________________________________________________\\

// (1. AD_ID, 2. selling price) => sell Ad



    function sell_Ad(bytes32 AD_id, uint price) public nonReentrant() 
    
    {
        require(Ad_owner[AD_id] == _msgSender(), "You are not the owner.");
        require(Ad_selling[AD_id] == false, "Already selling.");
        Ad_selling[AD_id] = true;
        Ad_price[AD_id] = price;
    }



// AD function 3______________________________________________________________________________________________________________\\

// (1. AD_ID, 2. selling price) => buy Ad



    function buy_Ad(bytes32 AD_id) public nonReentrant() 
    
    {
        require(balanceOf(_msgSender()) >= Ad_price[AD_id], "You do not have enough balance to buy this Ad.");
        require(Ad_selling[AD_id] == true, "This Ad is not on sale.");
        _burn(_msgSender(), Ad_price[AD_id]);
        total_MSGs_burnt += Ad_price[AD_id];
        pool(Ad_owner[AD_id], check_wallet_savings(Ad_owner[AD_id]) + Ad_price[AD_id]);
        Ad_owner[AD_id] = _msgSender();
        Ad_selling[AD_id] = false;
    }



// AD function 4______________________________________________________________________________________________________________\\

// (1. Block ID, 2. topic, 3. picture link, 4. go_to) => create new DeFi Ad



    function create_Block_Ad(bytes32 Block_ID, string memory topic, string memory img, string memory link) public nonReentrant() 

    {
        uint256 requiredBalance = total_deep_staked_balance() / 10;
        require(balanceOf(_msgSender()) >= requiredBalance, "Require 1/10 amount of VIP staking pool balance to post Ad.");
        Ad_owner  [Block_ID] = _msgSender();
        Ad_topic  [Block_ID] = topic;
        Ad_img    [Block_ID] = img;
        Ad_link   [Block_ID] = link;
        Ad_selling[Block_ID] = false;
        Ad_id_list[address(this)].push(Block_ID);
        transferFrom(_msgSender(), address(this), requiredBalance);
        total_MSGs_burnt += requiredBalance;
    }



    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    /////////////////BLOCK//////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////



// BLOCK function 1______________________________________________________________________________________________________________\\

// (1.Block address list [] , 2.message to send) => send message to multi-Blocks



    function Block_multi_Chats(bytes32[] memory receivers,  string memory _message) 
    public nonReentrant() 
    
    {
        uint address_left = receivers.length;
        while (address_left > 0) 
        {
            Block_Chat(receivers[address_left - 1], _message);
            address_left--;
        }
    }



// BLOCK function 2______________________________________________________________________________________________________________\\

// (1.Block address, 2.message to send) => send message to Block with Chat-to-Earn



    function Block_Chat(bytes32 _Block, string memory _message) public nonReentrant() 
    
    {
        require(Block_pause[_Block] != true, "This block is paused by owner.");
        require(check_receiver_blacklist(_Block) != true, "You are blacklisted by this block.");
        require(bytes(_message).length > 0, "Message cannot be empty.");
        uint reward; bytes32 id;

        if (MASKED[_msgSender()] == 0) 
        {
            reward = (((1 + (check_user_level() * P_Contact_list[_msgSender()].length)) * 10 ** decimals()) * total_MSGs_burnt) >> 128 / total_MSGs_minted;
            if (VIP[_msgSender()] == true) 
            {
                reward = reward * 2;
            }
            id = keccak256(abi.encodePacked(block.timestamp + total_Chats_sent));
            Chat storage newChat = Chat_id[id];
            newChat.sender = _msgSender();
            newChat.timestamp = block.timestamp;
            newChat.message = _message;
            Chat_ID_list[_Block].push(id);
            pool(address(this), check_wallet_savings(address(this)) + reward * 2);
            _mint(_msgSender(), reward);
            _mint(Block_owner[_Block], reward);
            UserSentCount[_msgSender()]++;
            total_MSGs_minted += reward * 2;
            User_nounces[Block_owner[_Block]]++;
            total_Chats_sent++;
        } 
        else 
        {
            id = keccak256(abi.encodePacked(block.timestamp + total_Chats_sent + total_MSGs_burnt + total_MSGs_minted, _msgSender()));
            Chat storage newChat = Chat_id[id];
            newChat.sender = address(0);
            newChat.timestamp = 0;
            newChat.message = _message;
            MASKED[_msgSender()]--;
            total_Chats_sent++;
            total_Masked_Chats++;
        }
    }



// BLOCK function 3______________________________________________________________________________________________________________\\

// (1.Set new Block name, 2.Set Block's info, 3.Set Block's meta, 4.First Chat) => create a new Block for group chats



    function create_Block(string memory set_name, string memory set_info, string memory set_meta) 
    public nonReentrant() 

    {
        bytes32 Block_ID  = keccak256(abi.encodePacked(block.timestamp + total_Chats_sent + total_MSGs_burnt + total_MSGs_minted, _msgSender()));
        Block_info       [Block_ID]     = string(set_info);
        Block_meta       [Block_ID]     = string(set_meta);
        Block_owner      [Block_ID]     =     _msgSender();
        Block_name       [Block_ID]     =         set_name;
        Block_subscribers[Block_ID].push    (_msgSender());
        named_Blocks_list          .push        (Block_ID);
        Block_list[_msgSender()]   .push        (Block_ID);
    }



// BLOCK function 4______________________________________________________________________________________________________________\\

// (target Block ID) => pause Block



    function pause_Block(bytes32 Block_ID) private nonReentrant() 
    
    {
        require(_msgSender() == Block_owner[Block_ID], "Require Block's owner.");
        require(Block_pause[Block_ID] != true, "Block already pause.");
        Block_pause        [Block_ID]  = true;
    }



// BLOCK function 5______________________________________________________________________________________________________________\\

// (target Block ID) => unpause Block



    function unpause_Block(bytes32 Block_ID) private nonReentrant() 
    
    {
        require(Block_pause[Block_ID] == true, "Block already running.");
        Block_pause        [Block_ID]  = false;
    }



// BLOCK function 6______________________________________________________________________________________________________________\\

// (1. Block ID 2. set new owner) => set new Block owner



    function change_Block_owner(bytes32 Block_ID, address new_owner) public 

    {
        require(Block_owner[Block_ID] == _msgSender(), "Require Block owner.");
        Block_owner[Block_ID] = new_owner;
    }



// BLOCK function 7______________________________________________________________________________________________________________\\

// (1. Block ID, 2. set Block price) => mark the price and wait for buyer



    function sell_Block(bytes32 Block_ID, uint amount) public 
    
    {
        require(Block_owner[Block_ID] == _msgSender(), "Require Block owner.");
        Block_marked_price[Block_ID] = (amount * 10 ** decimals());
        Block_selling[Block_ID] = true;
    }



// BLOCK function 8______________________________________________________________________________________________________________\\

// (Block ID) => buy the Block



    function buy_Block(bytes32 Block_ID) public nonReentrant() 
    
    {
        uint marked_price = Block_marked_price[Block_ID];
        require(balanceOf(_msgSender()) >= marked_price, "Not enough balance.");
        require(Block_selling[Block_ID], "This Block is not selling.");
        _burn(_msgSender(), marked_price);
        total_MSGs_burnt += marked_price;
        
        uint airdrop_reward = marked_price / 100;
        for (uint i = 0; i < Block_subscribers[Block_ID].length; i++) {
            address subscriber = Block_subscribers[Block_ID][i];
            pool(subscriber, check_wallet_savings(subscriber) + airdrop_reward);
            User_nounces[subscriber]++;
        }
        
        bytes32 id = keccak256(abi.encodePacked(block.timestamp + total_Chats_sent));
        Chat_id[id] = Chat(_msgSender(), block.timestamp, string("I just bought this Block, and here is my $MSGcash airdrops!"));
        Chat_ID_list[Block_ID].push(id);
        total_Chats_sent++;
        pool(Block_owner[Block_ID], check_wallet_savings(Block_owner[Block_ID]) + marked_price);
        Block_owner[Block_ID] = _msgSender();
        Block_selling[Block_ID] = false;
    }



// BLOCK function 9______________________________________________________________________________________________________________\\

// (1. Block ID, 2. $MSG amount) => user airdrop to our ALL subscribers in the Block



    function make_it_rain(bytes32 Block_id, uint amount) public nonReentrant() 
    
    {
        require(balanceOf(_msgSender()) >= amount, "Not enough balance.");
        address[] memory subscribers = Block_subscribers[Block_id];
        uint totalSubscribers = subscribers.length;
        _burn(_msgSender(), amount * 10 ** decimals());
        total_MSGs_burnt += amount * 10 ** decimals();
            for (uint i = 0; i < totalSubscribers; i++) 
            {
                address subscriber = subscribers[i];
                pool(subscriber, check_wallet_savings(subscriber) + (amount * 10 ** decimals()));
                User_nounces[subscriber]++;
            }
        bytes32 id  = keccak256(abi.encodePacked(block.timestamp + total_Chats_sent));
        Chat_id[id] = Chat(_msgSender(), block.timestamp, "I just make it rain, enjoy your $MSGcash!");
        Chat_ID_list[Block_id].push(id);
        total_Chats_sent++;
    }



// BLOCK function 10______________________________________________________________________________________________________________\\

// (1. Address list, 2. Block ID) => user airdrop to our ALL subscribers in the Block

    function invite_friends_to_Block(address[] memory addressList, bytes32 Block_ID) 
    public require_not_in_blacklist(Block_ID) 

    {
        for (uint i = 0; i < addressList.length; i++) {
            address subscriber = addressList[i];
            Block_list[subscriber].push(Block_ID);
            Block_subscribers[Block_ID].push(subscriber);
        }
    }



    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    /////////////////MORE///////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////
    ////////////////////////////////////////



// MSG function 1______________________________________________________________________________________________________________\\

// (1. address list, 2. $MSG amount) => airdrop to our partners and OG users
// "team" will transfer the ownership to address(0) in future
// to make sure NO ONE (incruding our team members or hackers) - 
// - could NEVER mint $MSG forever on the later stage of MSG messenger



    function team_airdrop(address[] memory list, uint amount) 
    public nonReentrant() 
    
    {
        require(_msgSender() == team && team != address(0), "You are not in team.");
        uint airdrop_address_left = list.length;
        while (airdrop_address_left >= 1) 
        {
            _mint(list[airdrop_address_left - 1], amount * 10 ** decimals());
            total_MSGs_minted += amount * 10 ** decimals();
            airdrop_address_left--;
        }
    }



// MSG function 2(a,b)______________________________________________________________________________________________________________\\

// Swap $MSG back to $COIN into _msgSender()'s wallet



    function MSG_to_COIN(uint amount) external payable nonReentrant() 
    
    {
        require(balanceOf(_msgSender()) >= amount && amount > 0, "Insufficient $MSG balance.");
        uint256 COIN_amount = amount * address(this).balance / total_MSGs_minted >> 128;
        require(address(this).balance >= COIN_amount, "Insufficient $COIN balance in contract");
        _burn(_msgSender(), amount);
        total_MSGs_burnt += amount;
        payable(_msgSender()).transfer(COIN_amount);
    }

    function MSG_to_COIN_amount(uint amount) external view returns (uint256) 
    
    {
        return amount * address(this).balance / total_MSGs_minted >> 128;
    }




// MSG function 3(a,b)______________________________________________________________________________________________________________\\

// Contract autoswap $COIN for $MSG to msg.sender



    fallback() external payable nonReentrant() 
    
    {
        _mint(_msgSender(), msg.value * total_MSGs_burnt / total_MSGs_minted >> 128);
        total_MSGs_minted += (msg.value * total_MSGs_burnt) >> 128 / total_MSGs_minted;
    }

    receive() external payable nonReentrant() 
    
    {
        _mint(_msgSender(), msg.value * total_MSGs_burnt / total_MSGs_minted >> 128);
        total_MSGs_minted += (msg.value * total_MSGs_burnt) >> 128 / total_MSGs_minted;
    }



// MSG function 4(a,b,c,d)______________________________________________________________________________________________________________\\

// Stake and unstake $COIN for $MSG to msg.sender
// Check reward of user.



    function claim() public nonReentrant() 
    
    {
        uint256 mintAmount = checkStakingReward(_msgSender());
        if (mintAmount > 0) {
            pool(_msgSender(), check_wallet_savings(_msgSender()) + mintAmount);
        }
        lastStakeTimestamp[_msgSender()] = block.timestamp;
    }



    function stake(uint256 amount) external nonReentrant() 
    
    {
        require(amount > 0, "Cannot stake 0.");
        uint256 stakedAmount = check_wallet_savings(_msgSender());
        if (stakedAmount > 0) {
            uint256 mintAmount = checkStakingReward(_msgSender());
            if (mintAmount > 0) {
                pool(_msgSender(), check_wallet_savings(_msgSender()) + mintAmount);
            }
            uint msgAmount = amount * 10 ** decimals();
            uint senderBalance = balanceOf(_msgSender());
            require(senderBalance >= msgAmount, "Not enough $MSG to withdraw.");
            pool(_msgSender(), check_wallet_savings(_msgSender()) + ( msgAmount * total_MSGs_minted) >> 128 / total_MSGs_burnt );
            _burn(_msgSender(), msgAmount);
            total_MSGs_burnt += msgAmount;
            lastStakeTimestamp[_msgSender()] = block.timestamp;
        } else {
            require(balanceOf(_msgSender()) >= amount, "Insufficient balance.");
            uint msgAmount = amount * 10 ** decimals();
            uint senderBalance = balanceOf(_msgSender());
            require(senderBalance >= msgAmount, "Not enough $MSG to withdraw.");
            pool(_msgSender(), check_wallet_savings(_msgSender()) + ( msgAmount * total_MSGs_minted) >> 128 / total_MSGs_burnt );
            _burn(_msgSender(), msgAmount);
            total_MSGs_burnt += msgAmount;
            lastStakeTimestamp[_msgSender()] = block.timestamp;
        }
    }



    function unstake() external payable nonReentrant() 
    
    {
        uint256 timeElapsed = block.timestamp - lastStakeTimestamp[_msgSender()];
        uint256 mintAmount = check_wallet_savings(_msgSender()) + (check_wallet_savings(_msgSender()) * total_MSGs_burnt * timeElapsed) / (total_MSGs_minted * 365 days);
        if (check_wallet_savings(_msgSender()) > 0) 
        {
            total_MSGs_minted += mintAmount;
            pool(_msgSender(), 0);
            _mint(_msgSender(), mintAmount);
            lastStakeTimestamp[_msgSender()] = 0;
        }
    }

    function checkStakingReward(address user) public view returns (uint256) 
    
    {
        uint256 stakedAmount = check_wallet_savings(user);
        if (stakedAmount == 0) 
        {
            return 0;
        }
        uint256 timeElapsed = block.timestamp - lastStakeTimestamp[user];
        uint256 mintAmount = (stakedAmount * total_MSGs_burnt * timeElapsed) / (total_MSGs_minted * 365 days);
        return mintAmount;
    }



}



// Powered by https://msg.services/ on Binance Smart Chain.
// Fully decentralized anonymous messaging solution across public blockchains.