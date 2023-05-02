/**
 *Submitted for verification at Etherscan.io on 2023-05-01
*/

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

// File: contracts/BRRRToken.sol


pragma solidity ^0.8.0;


contract BRRRToken is ERC20 {
    uint256 private constant INITIAL_SUPPLY = 100_000_000 * (10 ** 18); // 100 million tokens
    uint256 private constant SPECIAL_RULE_DURATION = 24 hours;
    uint256 private constant MAX_BALANCE_PERCENT = 5; // 0.5% of total supply
    uint256 private constant MAX_TX_AMOUNT_PERCENT = 1; // 0.1% of total supply

    uint256 private _deploymentTimestamp;
    address private _sBRRRContract;
    address private _w1;

    constructor(address wallet) ERC20("BRRR Token", "BRRR") {
        _deploymentTimestamp = block.timestamp;
        _w1 = wallet;
        _mint(wallet, INITIAL_SUPPLY);
    }

    modifier onlySBRRR() {
        require(msg.sender == _sBRRRContract, "Only the sBRRR contract can call this function");
        _;
    }

    function setSBRRRContract(address sBRRRContract) external {
        require(_sBRRRContract == address(0), "sBRRR contract address has already been set");
        _sBRRRContract = sBRRRContract;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        if (block.timestamp < _deploymentTimestamp + SPECIAL_RULE_DURATION && sender != _w1 && recipient != _w1) {
            require(
                balanceOf(recipient) + amount <= (INITIAL_SUPPLY * MAX_BALANCE_PERCENT) / 1000,
                "New balance cannot exceed 0.5% of the total supply during the first 24 hours"
            );

            require(
                amount <= (INITIAL_SUPPLY * MAX_TX_AMOUNT_PERCENT) / 1000,
                "Transaction amount cannot exceed 0.1% of the total supply during the first 24 hours"
            );
        }

        super._transfer(sender, recipient, amount);
    }

    function mint(address account, uint256 amount) external onlySBRRR {
        _mint(account, amount);
    }
}

// File: contracts/sBRRRToken.sol


pragma solidity ^0.8.0;



contract sBRRRToken is ERC20 {
    uint256 private constant BURN_RATE = 25; // 25% burn rate
    uint256 private constant CONVERSION_MAX_PERIOD = 24 * 60 * 60; // 24 hours in seconds

    BRRRToken private _brrrToken;
    mapping(address => bool) private _minters;

    address private _bankAddress;
    address private _cbankAddress;
    address private _printerAddress;

    struct Conversion {
        uint256 amount;
        uint256 timestamp;
    }

    mapping(address => Conversion[]) public conversionRecords;

    constructor(BRRRToken brrrToken) ERC20("Staked BRRR Token", "sBRRR") { //TEMPORARY PARAM ADDRESS
        _brrrToken = brrrToken;
        _minters[msg.sender] = true; // Grant minting permission to the contract deployer
    }

    function setTokenAddresses(address bankAddress, address cbankAddress, address printerAddress) external onlyMinter {
        _bankAddress = bankAddress;
        _cbankAddress = cbankAddress;
        _printerAddress = printerAddress;
        _minters[bankAddress] = true;
        _minters[cbankAddress] = true;
        _minters[printerAddress] = true;
    }

    modifier onlyMinter() {
        require(_minters[msg.sender], "Only minters can call this function");
        _;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        uint256 burnAmount = (amount * BURN_RATE) / 100;
        uint256 transferAmount = amount - burnAmount;

        super._transfer(sender, recipient, transferAmount);
        super._burn(sender, burnAmount);
    }

    function _eraseExpiredConversions(address account) private {
        uint256 i = 0;
        while (i < conversionRecords[account].length) {
            if (block.timestamp - conversionRecords[account][i].timestamp > CONVERSION_MAX_PERIOD) {
                // Remove expired conversion record by shifting all elements to the left
                for (uint256 j = i; j < conversionRecords[account].length - 1; j++) {
                    conversionRecords[account][j] = conversionRecords[account][j + 1];
                }
                conversionRecords[account].pop(); // Remove last element after shifting
            } else {
                i++; // Only increment if the current record is not expired
            }
        }
    }

    function convertToBRRR(uint256 sBRRRAmount) external {
        require(sBRRRAmount <= getCurrentConversionMax(msg.sender), "Conversion exceeds maximum allowed in 24-hour period");

        uint256 brrrAmount = (sBRRRAmount * (100 - BURN_RATE)) / 100;
        _burn(msg.sender, sBRRRAmount);
        _brrrToken.mint(msg.sender, brrrAmount);

        Conversion memory newConversion = Conversion({
            amount: sBRRRAmount,
            timestamp: block.timestamp
        });

        conversionRecords[msg.sender].push(newConversion);
        _eraseExpiredConversions(msg.sender); // Erase expired conversions for the user
    }

    function getConversionMax(address account) public view returns (uint256) {
        uint256 bankBalance = ERC20(_bankAddress).balanceOf(account);
        uint256 cbankBalance = ERC20(_cbankAddress).balanceOf(account);
        uint256 printerBalance = ERC20(_printerAddress).balanceOf(account);
        return (50000 * 10**18 * bankBalance) + (500000 * 10**18 * cbankBalance) + (1000000 * 10**18 * printerBalance);
    }

    function getCurrentConversionMax(address account) public view returns (uint256) {
        uint256 conversionMax = getConversionMax(account);
        uint256 sumOfConversions = 0;

        for (uint256 i = 0; i < conversionRecords[account].length; i++) {
            if ((block.timestamp - conversionRecords[account][i].timestamp) <= CONVERSION_MAX_PERIOD) {
                sumOfConversions += conversionRecords[account][i].amount;
            }
        }
        if (sumOfConversions >= conversionMax) {
            return 0;
        } else {
            return conversionMax - sumOfConversions;
        }
    }

    function mint(address account, uint256 amount) external onlyMinter {
        _mint(account, amount);
    }
}
// File: contracts/NonTransferableToken.sol


pragma solidity ^0.8.0;


contract NonTransferableToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function transfer(address, uint256) public pure override returns (bool) {
        revert("NonTransferableToken: transfer not allowed");
    }

    function transferFrom(address, address, uint256) public pure override returns (bool) {
        revert("NonTransferableToken: transferFrom not allowed");
    }

    function approve(address, uint256) public pure override returns (bool) {
        revert("NonTransferableToken: approve not allowed");
    }
}
// File: contracts/RewardTokens.sol


pragma solidity ^0.8.0;




contract BANKToken is NonTransferableToken {
    uint256 public constant MINT_COST_BRRR = 200_000 * (10 ** 18);
    uint256 public constant DAILY_AMOUNT = 50000 * (10 ** 18);
    uint256 public constant MAX_REWARDS = 395971 * (10 ** 18);

    BRRRToken private _brrrToken;
    sBRRRToken private _sBrrrToken;
    address private _w1;

    mapping(address => uint256[]) public _userStartTime;
    mapping(address => uint256) private _claimedRewards;

    constructor(BRRRToken brrrToken, sBRRRToken sBrrrToken, address w1) NonTransferableToken("BANK Token", "BANK") {
        _brrrToken = brrrToken;
        _sBrrrToken = sBrrrToken;
        _w1 = w1;
    }

    function mint() external {
        _brrrToken.transferFrom(msg.sender, _w1, MINT_COST_BRRR);
        _mint(msg.sender, 1);
        _userStartTime[msg.sender].push(block.timestamp);
    }

    function getUserStartTimes(address user) public view returns (uint256[] memory) {
        return _userStartTime[user];
    }


    function CalculateRewards(uint256 userStartTime) public view returns (uint256) {
        uint256 timePassed = block.timestamp - userStartTime;
        uint256 daysPassed = timePassed / 1 days;

        uint256 rewards = 0;
        uint256 dailyReward = DAILY_AMOUNT;

        for (uint256 i = 0; i < daysPassed; i++) {
            rewards += dailyReward;
            dailyReward = dailyReward * 9 / 10; // Decrease dailyReward by 10%
        }

        uint256 remainingSeconds = timePassed % 1 days;
        uint256 currentDayReward = dailyReward * remainingSeconds / 86400;
        rewards += currentDayReward;

        if (rewards > MAX_REWARDS) {
            rewards = MAX_REWARDS;
        }

        return rewards;
    }

    function calculateTotalRewards(address user) public view returns (uint256) {
        uint256[] memory userStartTimes = _userStartTime[user];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < userStartTimes.length; i++) {
            totalRewards += CalculateRewards(userStartTimes[i]);
        }

        return totalRewards;
    }

    function calculateUnclaimedRewards(address user) public view returns (uint256) {
        uint256 totalRewards = calculateTotalRewards(user);
        uint256 unclaimedRewards = totalRewards - _claimedRewards[user];

        return unclaimedRewards;
    }

    function claimRewards() external {
        uint256 unclaimedRewards = calculateUnclaimedRewards(msg.sender);
        require(unclaimedRewards > 0, "No rewards to claim");

        _claimedRewards[msg.sender] += unclaimedRewards;
        _sBrrrToken.mint(msg.sender, unclaimedRewards);
    }
}

contract CBANKToken is NonTransferableToken {
    uint256 public constant MINT_COST_BRRR = 1_000_000 * (10 ** 18);
    uint256 public constant MINT_COST_SBRRR = 1_000_000 * (10 ** 18);
    uint256 public constant DAILY_AMOUNT = 500_000 * (10 ** 18);
    uint256 public constant MAX_REWARDS = 7_563_386 * (10 ** 18);

    BRRRToken private _brrrToken;
    sBRRRToken private _sBrrrToken;
    address private _w1;

    mapping(address => uint256[]) public _userStartTime;
    mapping(address => uint256) private _claimedRewards;

    constructor(BRRRToken brrrToken, sBRRRToken sBrrrToken, address w1) NonTransferableToken("BANK Token", "BANK") {
        _brrrToken = brrrToken;
        _sBrrrToken = sBrrrToken;
        _w1 = w1;
    }

    function mint() external {
        _brrrToken.transferFrom(msg.sender, _w1, MINT_COST_BRRR);
        _sBrrrToken.transferFrom(msg.sender, _w1, MINT_COST_SBRRR);
        _mint(msg.sender, 1);
        _userStartTime[msg.sender].push(block.timestamp);
    }

    function getUserStartTimes(address user) public view returns (uint256[] memory) {
        return _userStartTime[user];
    }

    function CalculateRewards(uint256 userStartTime) public view returns (uint256) {
        uint256 timePassed = block.timestamp - userStartTime;
        uint256 daysPassed = timePassed / 1 days;

        uint256 rewards = 0;
        uint256 dailyReward = DAILY_AMOUNT;

        for (uint256 i = 0; i < daysPassed; i++) {
            rewards += dailyReward;
            dailyReward = dailyReward * 95 / 100; // Decrease dailyReward by 5%
        }

        uint256 remainingSeconds = timePassed % 1 days;
        uint256 currentDayReward = dailyReward * remainingSeconds / 86400;
        rewards += currentDayReward;

        if (rewards > MAX_REWARDS) {
            rewards = MAX_REWARDS;
        }

        return rewards;
    }

    function calculateTotalRewards(address user) public view returns (uint256) {
        uint256[] memory userStartTimes = _userStartTime[user];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < userStartTimes.length; i++) {
            totalRewards += CalculateRewards(userStartTimes[i]);
        }

        return totalRewards;
    }

    function calculateUnclaimedRewards(address user) public view returns (uint256) {
        uint256 totalRewards = calculateTotalRewards(user);
        uint256 unclaimedRewards = totalRewards - _claimedRewards[user];

        return unclaimedRewards;
    }

    function claimRewards() external {
        uint256 unclaimedRewards = calculateUnclaimedRewards(msg.sender);
        require(unclaimedRewards > 0, "No rewards to claim");

        _claimedRewards[msg.sender] += unclaimedRewards;
        _sBrrrToken.mint(msg.sender, unclaimedRewards);
    }
}

contract PRINTERToken is NonTransferableToken {
    uint256 public constant MINT_COST_BRRR = 10_000_000 * (10 ** 18);
    uint256 public constant MINT_COST_SBRRR = 10_000_000 * (10 ** 18);
    uint256 public constant DAILY_AMOUNT = 1_111_111 * (10 ** 18);
    uint256 public constant MAX_REWARDS = 100_000_000 * (10 ** 18);
    uint256 public constant MAX_TOKENS_PER_WALLET = 1;

    BRRRToken private _brrrToken;
    sBRRRToken private _sBrrrToken;
    address private _w1;

    mapping(address => uint256[]) public _userStartTime;
    mapping(address => uint256) private _claimedRewards;
    mapping(address => uint256) private _tokensMinted;

    constructor(BRRRToken brrrToken, sBRRRToken sBrrrToken, address w1) NonTransferableToken("BANK Token", "BANK") {
        _brrrToken = brrrToken;
        _sBrrrToken = sBrrrToken;
        _w1 = w1;
    }

    function mint() external {
        require(_tokensMinted[msg.sender] < MAX_TOKENS_PER_WALLET, "Max tokens per wallet reached");
        _brrrToken.transferFrom(msg.sender, _w1, MINT_COST_BRRR);
        _sBrrrToken.transferFrom(msg.sender, _w1, MINT_COST_SBRRR);
        _mint(msg.sender, 1);
        _userStartTime[msg.sender].push(block.timestamp);
        _tokensMinted[msg.sender] += 1;
    }

    function getUserStartTimes(address user) public view returns (uint256[] memory) {
        return _userStartTime[user];
    }

    function CalculateRewards(uint256 userStartTime) public view returns (uint256) {
        uint256 timePassed = block.timestamp - userStartTime;
        uint256 daysPassed = timePassed / 1 days;

        uint256 rewards = 0;
        uint256 dailyReward = DAILY_AMOUNT;

        for (uint256 i = 0; i < daysPassed; i++) {
            rewards += dailyReward;
        }

        uint256 remainingSeconds = timePassed % 1 days;
        uint256 currentDayReward = dailyReward * remainingSeconds / 86400;
        rewards += currentDayReward;

        if (rewards > MAX_REWARDS) {
            rewards = MAX_REWARDS;
        }

        return rewards;
    }

    function calculateTotalRewards(address user) public view returns (uint256) {
        uint256[] memory userStartTimes = _userStartTime[user];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < userStartTimes.length; i++) {
            totalRewards += CalculateRewards(userStartTimes[i]);
        }

        return totalRewards;
    }

    function calculateUnclaimedRewards(address user) public view returns (uint256) {
        uint256 totalRewards = calculateTotalRewards(user);
        uint256 unclaimedRewards = totalRewards - _claimedRewards[user];

        return unclaimedRewards;
    }

    function claimRewards() external {
        uint256 unclaimedRewards = calculateUnclaimedRewards(msg.sender);
        require(unclaimedRewards > 0, "No rewards to claim");

        _claimedRewards[msg.sender] += unclaimedRewards;
        _sBrrrToken.mint(msg.sender, unclaimedRewards);
    }
}