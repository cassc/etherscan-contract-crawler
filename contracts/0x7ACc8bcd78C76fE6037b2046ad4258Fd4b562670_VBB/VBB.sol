/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// Sources flattened with hardhat v2.10.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

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

// File @openzeppelin/contracts/utils/[email protected]

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

// File @openzeppelin/contracts/token/ERC20/[email protected]

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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
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
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
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
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
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

// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File contracts/VBB.sol

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);
}

contract VBB is ERC20, Ownable {
    // Fees are expressed in integer %.
    struct Fees {
        uint8 total;
        uint8 reflection; // for reflecting `rewardToken` back to holders
        uint8 liquidity; // for automatically buying liquidity tokens
        uint8 marketing; // for marketing
    }

    Fees public fees;

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    uint256 public totalShares;

    // Struct to manage data for each holder.
    struct HolderInfo {
        bool feeExempt;
        bool dividendExempt;
        bool walletSizeExempt;
        Share share;
    }

    mapping(address => HolderInfo) public holderinfo;

    uint256 public maxWalletBalance;
    uint256 public swapThreshold;

    uint256 public targetLiquidityPct = 25;

    IDEXRouter router;
    address public routerAddress;
    address[] public rewardPath;
    address public rewardToken;

    bool public maxPerWalletEnabled = false;

    bool public dividendsEnabled = true;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10**36;
    uint256 public totalDividends;
    uint256 public totalDistributed;

    bool inSwap = false;

    address public pairToken;
    address public pairAddress;

    address public WETH;

    event AutoLiquify(uint256 amountETH, uint256 amountDIV);

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(
        address _router,
        address _pairToken,
        address _initialWallet,
        uint256 _initial_supply,
        address[] memory _reward_path
    ) ERC20("Vitalik Buterin Boner", "VBB") {
        setFeeOptions(5, 0, 5);

        setFeeReceivers(_initialWallet, _initialWallet);

        setExemptFromAll(address(this), true);
        setExemptFromAll(address(0), true);
        setExemptFromAll(msg.sender, true);

        _mint(msg.sender, _initial_supply * (10**decimals()));
        swapThreshold = totalSupply() / 2000;
        maxWalletBalance = totalSupply() / 20; // Maximum of 5% in any wallet

        setRouter(_router);
        setRewardPath(_reward_path);

        setPairToken(_pairToken);
    }

    // PUBLIC / EXTERNAL FUNCTIONS

    receive() external payable {}

    function setShare(address shareholder) public {
        distributeDividend(shareholder);

        uint256 amount = holderinfo[shareholder].dividendExempt
            ? 0
            : balanceOf(shareholder);
        totalShares =
            totalShares -
            holderinfo[shareholder].share.amount +
            amount;
        holderinfo[shareholder].share.amount = amount;
        holderinfo[shareholder].share.totalExcluded = getCumulativeDividends(
            holderinfo[shareholder].share.amount
        );
    }

    function distributeDividend(address shareholder) public {
        uint256 earnings = getUnpaidEarnings(shareholder);
        if (earnings > 0) {
            if (rewardPath.length == 0) {
                payable(shareholder).transfer(earnings);
            } else {
                router.swapExactETHForTokensSupportingFeeOnTransferTokens{
                    value: earnings
                }(0, rewardPath, shareholder, block.timestamp);
            }
        }
        totalDistributed += earnings;
        holderinfo[shareholder].share.totalRealised += earnings;
        holderinfo[shareholder].share.totalExcluded = getCumulativeDividends(
            holderinfo[shareholder].share.amount
        );
    }

    function claimRewards() external {
        distributeDividend(msg.sender);
    }

    // INTERNAL FUNCTIONS

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (inSwap) {
            super._transfer(sender, recipient, amount);
            return;
        }

        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(
            balanceOf(sender) >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        bool isSell = (recipient == pairAddress || recipient == routerAddress);

        if (
            swapThreshold > 0 &&
            !inSwap &&
            isSell &&
            msg.sender != pairAddress &&
            balanceOf(address(this)) >= swapThreshold
        ) {
            swapBack();
        }

        if (fees.total > 0 && !isFeeExempt(sender)) {
            uint256 feeAmount = (amount * fees.total) / 100;
            super._transfer(sender, address(this), feeAmount);
            amount -= feeAmount;
        }

        if (maxPerWalletEnabled && !isWalletSizeExempt(recipient)) {
            require(
                (balanceOf(recipient) + amount) <= maxWalletBalance,
                "Max balance per wallet exceeded"
            );
        }

        super._transfer(sender, recipient, amount);

        if (dividendsEnabled) {
            setShare(sender);
            setShare(recipient);
            distributeDividend(sender);
            distributeDividend(recipient);
        }
    }

    function swapBack() internal swapping {
        uint256 circulating_supply = totalSupply() - balanceOf(address(0));
        uint256 total_liquidity_backing = (balanceOf(pairAddress) * 100) /
            circulating_supply;
        uint256 dynamicLiquidityFee = (total_liquidity_backing >
            targetLiquidityPct)
            ? 0
            : fees.liquidity;
        uint256 amountToLiquify = (swapThreshold * dynamicLiquidityFee) /
            (fees.total * 2);
        uint256 amountToSwap = swapThreshold - amountToLiquify;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;
        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETH(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance - balanceBefore;

        uint256 totalETHFee = fees.total - (dynamicLiquidityFee / 2);

        uint256 amountETHLiquidity = (amountETH * dynamicLiquidityFee) /
            (totalETHFee / 2);
        uint256 amountETHReflection = (amountETH * fees.reflection) /
            totalETHFee;
        uint256 amountETHMarketing = (amountETH * fees.marketing) / totalETHFee;

        payable(marketingFeeReceiver).transfer(amountETHMarketing);

        if (dividendsEnabled) {
            totalDividends += amountETHReflection;
            dividendsPerShare +=
                (dividendsPerShareAccuracyFactor * amountETHReflection) /
                totalShares;
        }

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
    }

    // VIEWS

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function getRealizedAmount(address shareholder)
        public
        view
        returns (uint256)
    {
        return holderinfo[shareholder].share.totalRealised;
    }

    function getUnpaidEarnings(address shareholder)
        public
        view
        returns (uint256)
    {
        if (holderinfo[shareholder].share.amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = getCumulativeDividends(
            holderinfo[shareholder].share.amount
        );
        uint256 shareholderTotalExcluded = holderinfo[shareholder]
            .share
            .totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalDividends - shareholderTotalExcluded;
    }

    function getShareAmount(address shareholder) public view returns (uint256) {
        return holderinfo[shareholder].share.amount;
    }

    function getCumulativeDividends(uint256 share)
        internal
        view
        returns (uint256)
    {
        return (share * dividendsPerShare) / dividendsPerShareAccuracyFactor;
    }

    function isWalletSizeExempt(address _addr) public view returns (bool) {
        return holderinfo[_addr].walletSizeExempt;
    }

    function isDividendExempt(address _addr) public view returns (bool) {
        return holderinfo[_addr].dividendExempt;
    }

    function isFeeExempt(address _addr) public view returns (bool) {
        return holderinfo[_addr].feeExempt;
    }

    // OWNER-ONLY FUNCTIONS

    function Sweep() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function SweepToken(address _token) external onlyOwner {
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function setFeeReceivers(
        address _autoLiquidityReceiver,
        address _marketingFeeReceiver
    ) public onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        setWalletSizeExempt(autoLiquidityReceiver, true);
        setFeeExempt(autoLiquidityReceiver, true);

        marketingFeeReceiver = _marketingFeeReceiver;
        setWalletSizeExempt(marketingFeeReceiver, true);
        setFeeExempt(marketingFeeReceiver, true);
    }

    function setSwapThreshold(uint256 _amount) external onlyOwner {
        swapThreshold = _amount;
    }

    function setTargetLiquidityPct(uint256 _target) external onlyOwner {
        require(
            _target < 99,
            "Target liquidity percentage can't be 100 or more"
        );
        targetLiquidityPct = _target;
    }

    function setFeeOptions(
        uint8 _reflectionFee,
        uint8 _liquidityFee,
        uint8 _marketingFee
    ) public onlyOwner {
        uint8 totalFee = _reflectionFee + _liquidityFee + _marketingFee;
        require(totalFee < 25, "Fees are too high");

        fees = Fees(totalFee, _reflectionFee, _liquidityFee, _marketingFee);
    }

    function setMaxPerWalletEnabled(bool _enabled) external onlyOwner {
        maxPerWalletEnabled = _enabled;
    }

    function setMaxPerWallet(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Max balance per wallet must be > 0");
        maxWalletBalance = _amount;
    }

    function setDividendsEnabled(bool _enabled) external onlyOwner {
        dividendsEnabled = _enabled;
    }

    function setDividendExempt(address _addr, bool _exempt) public onlyOwner {
        holderinfo[_addr].dividendExempt = _exempt;
        setShare(_addr);
    }

    function setFeeExempt(address _addr, bool _exempt) public onlyOwner {
        holderinfo[_addr].feeExempt = _exempt;
    }

    function setWalletSizeExempt(address _addr, bool _exempt) public onlyOwner {
        holderinfo[_addr].walletSizeExempt = _exempt;
    }

    function setExemptFromAll(address _addr, bool _exempt) public onlyOwner {
        setDividendExempt(_addr, _exempt);
        setWalletSizeExempt(_addr, _exempt);
        setFeeExempt(_addr, _exempt);
    }

    function setRouter(address _routerAddress) public onlyOwner {
        router = IDEXRouter(_routerAddress);
        routerAddress = _routerAddress;
        _approve(address(this), _routerAddress, totalSupply());
        setDividendExempt(_routerAddress, true);
        setWalletSizeExempt(_routerAddress, true);
        WETH = router.WETH();
    }

    function setRewardPath(address[] memory _path) public onlyOwner {
        rewardPath = _path;
        rewardToken = (_path.length == 0 ? WETH : _path[_path.length - 1]);
    }

    function setPairToken(address _pairToken) public onlyOwner {
        pairToken = _pairToken;
        pairAddress = IDEXFactory(router.factory()).createPair(
            pairToken,
            address(this)
        );
        setDividendExempt(pairAddress, true);
        setWalletSizeExempt(pairAddress, true);

        _approve(address(this), pairAddress, totalSupply());
    }
}