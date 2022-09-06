/**
 *Submitted for verification at Etherscan.io on 2022-08-31
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol



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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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

// File: @openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol



pragma solidity ^0.8.0;



/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}


pragma solidity ^0.8.4;



interface DuckNFT {
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
}
interface DucklingNFT {
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
}
interface AlphaNFT {
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
}

contract odycstaking is ERC20Burnable, Ownable {
    uint256 public constant MAX_SUPPLY = 200000000 * 1 ether;
    uint256 public constant ALPHA_EMISSION_RATE = 17; // 17 per day
    uint256 public constant DUCK_EMISSION_RATE = 10; // 10 per day
    uint256 public constant DUCKLING_EMISSION_RATE = 5; // 5 per day
    address public DUCK_ADDRESS = 0x36D7b711390D34e8fe26ad8f2bB14E7C8f0c56e9; 
    address public DUCKLING_ADDRESS = 0xeB4A28587503d84dc29DE8e4Fc8bF0A57A7Ddb0d;
    address public ALPHA_ADDRESS = 0x258cc47A6C4fb69458F87825d8E3f7B57c90748D;
    bool public live = false;

    mapping(uint256 => uint256) internal duckTimeStaked;
    mapping(uint256 => address) internal duckStaker;
    mapping(address => uint256[]) internal stakerToDuck;
    
    mapping(uint256 => uint256) internal ducklingTimeStaked;
    mapping(uint256 => address) internal ducklingStaker;
    mapping(address => uint256[]) internal stakerToDuckling;
    
    mapping(uint256 => uint256) internal alphaTimeStaked;
    mapping(uint256 => address) internal alphaStaker;
    mapping(address => uint256[]) internal stakerToAlpha;


    DuckNFT private _duckContract = DuckNFT(DUCK_ADDRESS);
    DucklingNFT private _ducklingContract = DucklingNFT(DUCKLING_ADDRESS);
    AlphaNFT private _alphaContract = AlphaNFT(ALPHA_ADDRESS);

    constructor() ERC20("GRAPES", "GRAPES") {
        _mint(msg.sender, 2100 * 1 ether);
    }

    modifier stakingEnabled {
        require(live, "NOT_LIVE");
        _;
    }

    function getStakedDuck(address staker) public view returns (uint256[] memory) {
        return stakerToDuck[staker];
    }
    
    function getStakedAmount(address staker) public view returns (uint256) {
        return stakerToDuck[staker].length;
    }

    function getDuckStaker(uint256 tokenId) public view returns (address) {
        return duckStaker[tokenId];
    }

    function getStakedDuckling(address staker) public view returns (uint256[] memory) {
        return stakerToDuckling[staker];
    }
    
    function getDucklingStakedAmount(address staker) public view returns (uint256) {
        return stakerToDuckling[staker].length;
    }

    function getDucklingStaker(uint256 tokenId) public view returns (address) {
        return ducklingStaker[tokenId];
    }

    function getStakedAlpha(address staker) public view returns (uint256[] memory) {
        return stakerToAlpha[staker];
    }
    
    function getAlphaStakedAmount(address staker) public view returns (uint256) {
        return stakerToAlpha[staker].length;
    }

    function getAlphaStaker(uint256 tokenId) public view returns (address) {
        return alphaStaker[tokenId];
    }

    function getAllRewards(address staker) public view returns (uint256) {
        uint256 totalRewards = 0;

        uint256[] memory duckTokens = stakerToDuck[staker];
        for (uint256 i = 0; i < duckTokens.length; i++) {
            totalRewards += getReward(duckTokens[i]);
        }

        uint256[] memory ducklingTokens = stakerToDuckling[staker];
        for (uint256 i = 0; i < ducklingTokens.length; i++) {
            totalRewards += getDucklingReward(ducklingTokens[i]);
        }

        uint256[] memory alphaTokens = stakerToAlpha[staker];
        for (uint256 i = 0; i < alphaTokens.length; i++) {
            totalRewards += getAlphaReward(alphaTokens[i]);
        }

        return totalRewards;
    }

    function stakeDuckById(uint256[] calldata tokenIds) external stakingEnabled {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            _duckContract.transferFrom(msg.sender, address(this), id);

            stakerToDuck[msg.sender].push(id);
            duckTimeStaked[id] = block.timestamp;
            duckStaker[id] = msg.sender;
        }
    }

    function unstakeDuckByIds(uint256[] calldata tokenIds) external {
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(duckStaker[id] == msg.sender, "NEEDS_TO_BE_OWNER");

            _duckContract.transferFrom(address(this), msg.sender, id);
            totalRewards += getReward(id);

            removeTokenIdFromArray(stakerToDuck[msg.sender], id);
            duckStaker[id] = address(0);
        }

        uint256 remaining = MAX_SUPPLY - totalSupply();
        _mint(msg.sender, totalRewards > remaining ? remaining : totalRewards);
    }

    function stakeDucklingsById(uint256[] calldata tokenIds) external stakingEnabled {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            _ducklingContract.transferFrom(msg.sender, address(this), id);

            stakerToDuckling[msg.sender].push(id);
            ducklingTimeStaked[id] = block.timestamp;
            ducklingStaker[id] = msg.sender;
        }
    }

    function unstakeDucklingsByIds(uint256[] calldata tokenIds) external {
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(ducklingStaker[id] == msg.sender, "NEEDS_TO_BE_OWNER");

            _ducklingContract.transferFrom(address(this), msg.sender, id);
            totalRewards += getReward(id);

            removeTokenIdFromArray(stakerToDuckling[msg.sender], id);
            ducklingStaker[id] = address(0);
        }

        uint256 remaining = MAX_SUPPLY - totalSupply();
        _mint(msg.sender, totalRewards > remaining ? remaining : totalRewards);
    }

    function stakeAlphaById(uint256[] calldata tokenIds) external stakingEnabled {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            _alphaContract.transferFrom(msg.sender, address(this), id);

            stakerToAlpha[msg.sender].push(id);
            alphaTimeStaked[id] = block.timestamp;
            alphaStaker[id] = msg.sender;
        }
    }

    function unstakeAlphaByIds(uint256[] calldata tokenIds) external {
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(alphaStaker[id] == msg.sender, "NEEDS_TO_BE_OWNER");

            _alphaContract.transferFrom(address(this), msg.sender, id);
            totalRewards += getReward(id);

            removeTokenIdFromArray(stakerToAlpha[msg.sender], id);
            alphaStaker[id] = address(0);
        }

        uint256 remaining = MAX_SUPPLY - totalSupply();
        _mint(msg.sender, totalRewards > remaining ? remaining : totalRewards);
    }

    function unstakeAll() external {
        require(getStakedAmount(msg.sender) > 0 || getDucklingStakedAmount(msg.sender) > 0 || getAlphaStakedAmount(msg.sender) > 0, "None Staked");
        uint256 totalRewards = 0;

        for (uint256 i = stakerToDuck[msg.sender].length; i > 0; i--) {
            uint256 id = stakerToDuck[msg.sender][i - 1];

            _duckContract.transferFrom(address(this), msg.sender, id);
            totalRewards += getReward(id);

            stakerToDuck[msg.sender].pop();
            duckStaker[id] = address(0);
        }

        for (uint256 i = stakerToDuckling[msg.sender].length; i > 0; i--) {
            uint256 id = stakerToDuckling[msg.sender][i - 1];

            _ducklingContract.transferFrom(address(this), msg.sender, id);
            totalRewards += getDucklingReward(id);

            stakerToDuckling[msg.sender].pop();
            ducklingStaker[id] = address(0);
        }

        for (uint256 i = stakerToAlpha[msg.sender].length; i > 0; i--) {
            uint256 id = stakerToAlpha[msg.sender][i - 1];

            _alphaContract.transferFrom(address(this), msg.sender, id);
            totalRewards += getAlphaReward(id);

            stakerToAlpha[msg.sender].pop();
            alphaStaker[id] = address(0);
        }

        uint256 remaining = MAX_SUPPLY - totalSupply();
        _mint(msg.sender, totalRewards > remaining ? remaining : totalRewards);
    }

    function claimAll() external {
        uint256 totalRewards = 0;

        uint256[] memory duckTokens = stakerToDuck[msg.sender];
        for (uint256 i = 0; i < duckTokens.length; i++) {
            uint256 id = duckTokens[i];

            totalRewards += getReward(duckTokens[i]);
            duckTimeStaked[id] = block.timestamp;
        }

        uint256[] memory ducklingTokens = stakerToDuckling[msg.sender];
        for (uint256 i = 0; i < ducklingTokens.length; i++) {
            uint256 id = ducklingTokens[i];

            totalRewards += getDucklingReward(ducklingTokens[i]);
            ducklingTimeStaked[id] = block.timestamp;
        }

        uint256[] memory alphaTokens = stakerToAlpha[msg.sender];
        for (uint256 i = 0; i < alphaTokens.length; i++) {
            uint256 id = alphaTokens[i];

            totalRewards += getAlphaReward(alphaTokens[i]);
            alphaTimeStaked[id] = block.timestamp;
        }

        uint256 remaining = MAX_SUPPLY - totalSupply();
        _mint(msg.sender, totalRewards > remaining ? remaining : totalRewards);
    }


    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }

    function setAlphaAddress(address ALPHA_ADDRESS_) public onlyOwner {
        ALPHA_ADDRESS = ALPHA_ADDRESS_;
    }
    
    function toggle() external onlyOwner {
        live = !live;
    }

    function getReward(uint256 tokenId) internal view returns(uint256) {
        return (block.timestamp - duckTimeStaked[tokenId]) * DUCK_EMISSION_RATE / 86400 * 1 ether;
    }

    function getDucklingReward(uint256 tokenId) internal view returns(uint256) {
        return (block.timestamp - ducklingTimeStaked[tokenId]) * DUCKLING_EMISSION_RATE / 86400 * 1 ether;
    }

    function getAlphaReward(uint256 tokenId) internal view returns(uint256) {
        return (block.timestamp - alphaTimeStaked[tokenId]) * ALPHA_EMISSION_RATE / 86400 * 1 ether;
    }

    function removeTokenIdFromArray(uint256[] storage array, uint256 tokenId) internal {
        uint256 length = array.length;
        for (uint256 i = 0; i < length; i++) {
            if (array[i] == tokenId) {
                length--;
                if (i < length) {
                    array[i] = array[length];
                }
                array.pop();
                break;
            }
        }
    }
}