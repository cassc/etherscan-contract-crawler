/**
 *Submitted for verification at Etherscan.io on 2023-07-18
*/

// SPDX-License-Identifier: MIT
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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

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

// File: @openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

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
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// File: contracts/FlipCoin.sol

pragma solidity 0.8.19;

contract FlipCoin is ERC20, ERC20Burnable, Ownable {
    // uint256 price = 0.01 ether; // price of 1 token in ether
    //events
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event FundsDeposited(address indexed sender, uint256 amount);
    event TokensBurned(address indexed burner, uint256 amount);
    event TokensMinted(address indexed minter, uint256 amount);

    mapping(address => string) private referralCodes;
    mapping(string => address) private referralCodeToUser;
    mapping(address => string) private userToReferralCode;
    mapping(address => uint256) private referralRewards;
    mapping(address => uint256) private referralRewardsClaimed;
    mapping(address => uint256) private referralRewardsClaimedTotal;
    mapping(address => uint256) private referralRewardsClaimedTotalUSD;
    mapping(address => uint256) private referralRewardsClaimedTotalETH;

    // Wallet addresses
    address private marketingWallet;
    address private teamWallet;
    address private uniswapLiquidityWallet;
    address private cexLiquidityWallet;
    address private rewardsWallet;

    //wallets
    address private constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;
    address private constant UNISWAP_WALLET =
        0x81bb380C73B34a7385B8E2Aee2080f38d35c49Ac;
    address private constant MARKETING_WALLET =
        0x1A200dE668F641C97fF5e4Af5c1608995D9a0Cc1;
    address private constant CEX_WALLET =
        0xfBA41705a99657B9871bCd52e676B9e43E870A7a;
    address private constant REWARDS_WALLET =
        0x5360090AEB43ff0c24E9265D378DE20e6a653B12;
    address private constant TEAM_WALLET =
        0x54582dFB78E7002E15A68AB9E19266124BDdfCCd;

    //allocations
    uint256 private marketingAllocation = 50_000_000 * 10 ** 18;
    uint256 private teamAllocation = 50_000_000 * 10 ** 18;
    uint256 private uniswapLiquidityAllocation = 100_000_000 * 10 ** 18;
    uint256 private cexLiquidityAllocation = 100_000_000 * 10 ** 18;
    uint256 private rewardsAllocation = 50_000_000 * 10 ** 18;
    uint256 private publicFloat = 650_000_000 * 10 ** 18;
    uint256 private initialSupply = 1_000_000_000 * 10 ** 18;

    constructor() ERC20("FlipCoin", "FLP") {
        //mint allocations
        _mint(TEAM_WALLET, teamAllocation);
        _mint(MARKETING_WALLET, marketingAllocation);
        _mint(REWARDS_WALLET, rewardsAllocation);
        _mint(UNISWAP_WALLET, uniswapLiquidityAllocation);
        _mint(CEX_WALLET, cexLiquidityAllocation);
        _mint(address(this), (initialSupply - teamAllocation - marketingAllocation - rewardsAllocation - uniswapLiquidityAllocation - cexLiquidityAllocation));

        // Set initial wallet addresses
        marketingWallet = MARKETING_WALLET;
        teamWallet = TEAM_WALLET;
        uniswapLiquidityWallet = UNISWAP_WALLET;
        cexLiquidityWallet = CEX_WALLET;
        rewardsWallet = REWARDS_WALLET;
    }

    //  function buy() external payable {
    //     require(msg.value > 0, "You must send some ether");
    //     _mint(msg.sender, msg.value * 10 ** 18 / price);
    // }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        uint256 marketingFee = (amount * 2) / 100;
        uint256 teamFee = (amount * 2) / 100;
        uint256 burnFee = (amount * 1) / 100;
        super._transfer(sender, MARKETING_WALLET, marketingFee);
        super._transfer(sender, TEAM_WALLET, teamFee);
        super._transfer(sender, BURN_ADDRESS, burnFee);
        super._transfer(
            sender,
            recipient,
            amount - (marketingFee + teamFee + burnFee)
        );
    }

    function withdrawFunds(
        address payable recipient,
        uint256 amount
    ) external onlyOwner {
        require(
            address(this).balance >= amount,
            "Insufficient contract balance"
        );
        require(amount > 0, "Amount must be greater than zero");
        // Transfer the funds to the recipient
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed");
        emit FundsWithdrawn(recipient, amount);
    }

    function depositFunds() external payable {
        require(msg.value > 0, "Amount must be greater than zero");
        emit FundsDeposited(msg.sender, msg.value);
    }

    function burnTokens(uint256 amount) external onlyOwner {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        require(amount > 0, "Amount must be greater than zero");
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }

    function mintTokens(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        _mint(msg.sender, amount);
        emit TokensMinted(msg.sender, amount);
    }

    // Function to set the marketing wallet address
    function setMarketingWallet(address newWallet) external onlyOwner {
        marketingWallet = newWallet;
    }

    // Function to set the team wallet address
    function setTeamWallet(address newWallet) external onlyOwner {
        teamWallet = newWallet;
    }

    // Function to set the Uniswap liquidity wallet address
    function setUniswapLiquidityWallet(address newWallet) external onlyOwner {
        uniswapLiquidityWallet = newWallet;
    }

    // Function to set the CEX liquidity wallet address
    function setCexLiquidityWallet(address newWallet) external onlyOwner {
        cexLiquidityWallet = newWallet;
    }

    // Function to set the rewards wallet address
    function setRewardsWallet(address newWallet) external onlyOwner {
        rewardsWallet = newWallet;
    }

    // Function to allocate rewards to a recipient
    function allocateReferralRewards(
        string calldata referralCode,
        uint256 amount
    ) external onlyOwner {
        address referredUser = referralCodeToUser[referralCode];
        require(referredUser != address(0), "Invalid referral code");
        require(amount > 0, "Amount must be greater than zero");
        _mint(referredUser, amount);
        emit TokensMinted(referredUser, amount);
    }

    // Function to allow users to claim their rewards
    function claimRewards() external {
        uint256 rewards = balanceOf(msg.sender);
        require(rewards > 0, "No rewards to claim");
        _transfer(msg.sender, rewardsWallet, rewards);
        emit Transfer(msg.sender, rewardsWallet, rewards);
    }

    // Function to generate the referral code for a user as an 8 character string
    function generateReferralCode() internal view returns (string memory) {
        bytes memory code = new bytes(8);
        string
            memory characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        uint256 maxNum = bytes(characters).length;

        for (uint256 i = 0; i < 8; i++) {
            code[i] = bytes(characters)[block.timestamp % maxNum];
            maxNum--;
        }

        return string(code);
    }

    // Function to set the referral code for a user
    function setReferralCode() external {
        if (bytes(userToReferralCode[msg.sender]).length > 0) {
            revert("Referral code already set");
        }

        string memory referralCode = generateReferralCode();
        while (referralCodeToUser[referralCode] != address(0)) {
            referralCode = generateReferralCode();
        }

        referralCodeToUser[referralCode] = msg.sender;
        userToReferralCode[msg.sender] = referralCode;
    }

    // Function to get the referral code for a user
    function getReferralCode(
        address user
    ) external view returns (string memory) {
        return userToReferralCode[user];
    }

    // Array to store the addresses of token holders
    address[] private _holders;

    // Mapping to track staked balances for each user
    mapping(address => uint256) private stakedBalances;

    // Total staked balance
    uint256 private totalStakedBalance;

    // Function to stake tokens
    function stakeTokens(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(amount <= balanceOf(msg.sender), "Insufficient balance");

        // Transfer tokens from sender to contract
        _transfer(msg.sender, address(this), amount);

        // Update staked balance for the sender
        stakedBalances[msg.sender] += amount;

        // Add the sender to the holders array if not already present
        if (stakedBalances[msg.sender] == amount) {
            _holders.push(msg.sender);
        }

        // Update total staked balance
        totalStakedBalance += amount;
    }

    // Function to unstake tokens
    function unstakeTokens(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(
            amount <= stakedBalances[msg.sender],
            "Insufficient staked balance"
        );

        // Update staked balance for the sender
        stakedBalances[msg.sender] -= amount;

        // Remove the sender from the holders array if their staked balance becomes zero
        if (stakedBalances[msg.sender] == 0) {
            _removeHolder(msg.sender);
        }

        // Update total staked balance
        totalStakedBalance -= amount;

        // Transfer tokens from contract to sender
        _transfer(address(this), msg.sender, amount);
    }

    // Internal function to remove a holder from the holders array
    function _removeHolder(address holder) internal {
        for (uint256 i = 0; i < _holders.length; i++) {
            if (_holders[i] == holder) {
                if (i != _holders.length - 1) {
                    _holders[i] = _holders[_holders.length - 1];
                }
                _holders.pop();
                break;
            }
        }
    }

    // Mapping to track issued referral codes and rewards balance
    mapping(address => string) private issuedReferralCodes;
    mapping(address => uint256) private rewardsBalance;

    // Function to get a user's issued referral code
    function getIssuedReferralCode(address user) external view returns (string memory) {
        return issuedReferralCodes[user];
    }

    // Function to get a user's rewards balance
    function getRewardsBalance(address user) external view returns (uint256) {
        return rewardsBalance[user];
    }

    // Mapping to track valid referral codes
    mapping(string => bool) private validReferralCodes;

    // Function to validate a referral code
    function validateReferralCode(string calldata referralCode) external view returns (bool) {
        return validReferralCodes[referralCode];
    }

    // Function to set the validity of a referral code
    function setReferralCodeValidity(string calldata referralCode, bool isValid) external onlyOwner {
        validReferralCodes[referralCode] = isValid;
    }

}