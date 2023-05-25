// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import {IOracle} from "./interfaces/IOracle.sol";
import "./interfaces/IButtonToken.sol";
import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title The ButtonToken ERC20 wrapper.
 *
 * @dev The ButtonToken is a rebasing wrapper for fixed balance ERC-20 tokens.
 *
 *      Users deposit the "underlying" (wrapped) tokens and are
 *      minted button (wrapper) tokens with elastic balances
 *      which change up or down when the value of the underlying token changes.
 *
 *      For example: Manny “wraps” 1 Ether when the price of Ether is $1800.
 *      Manny receives 1800 ButtonEther tokens in return.
 *      The overall value of their ButtonEther is the same as their original Ether,
 *      however each unit is now priced at exactly $1. The next day,
 *      the price of Ether changes to $1900. The ButtonEther system detects
 *      this price change, and rebases such that Manny’s balance is
 *      now 1900 ButtonEther tokens, still priced at $1 each.
 *
 *      The ButtonToken math is almost identical to Ampleforth's μFragments.
 *
 *      For AMPL, internal balances are represented using `gons` and
 *          -> internal account balance     `_gonBalances[account]`
 *          -> internal supply scalar       `gonsPerFragment = TOTAL_GONS / _totalSupply`
 *          -> public balance               `_gonBalances[account] * gonsPerFragment`
 *          -> public total supply          `_totalSupply`
 *
 *      In our case internal balances are stored as 'bits'.
 *          -> underlying token unit price  `p_u = price / 10 ^ (PRICE_DECIMALS)`
 *          -> total underlying tokens      `_totalUnderlying`
 *          -> internal account balance     `_accountBits[account]`
 *          -> internal supply scalar       `_bitsPerToken`
                                            ` = TOTAL_BITS / (MAX_UNDERLYING*p_u)`
 *                                          ` = BITS_PER_UNDERLYING*(10^PRICE_DECIMALS)/price`
 *                                          ` = PRICE_BITS / price`
 *          -> user's underlying balance    `(_accountBits[account] / BITS_PER_UNDERLYING`
 *          -> public balance               `_accountBits[account] * _bitsPerToken`
 *          -> public total supply          `_totalUnderlying * p_u`
 *
 *
 */
contract ButtonToken is IButtonToken, Initializable, OwnableUpgradeable {
    // PLEASE READ BEFORE CHANGING ANY ACCOUNTING OR MATH
    // We make the following guarantees:
    // - If address 'A' transfers x button tokens to address 'B'.
    //   A's resulting external balance will be decreased by "precisely" x button tokens,
    //   and B's external balance will be "precisely" increased by x button tokens.
    // - If address 'A' deposits y underlying tokens,
    //   A's resulting underlying balance will increase by "precisely" y.
    // - If address 'A' withdraws y underlying tokens,
    //   A's resulting underlying balance will decrease by "precisely" y.
    //
    using SafeERC20 for IERC20;

    //--------------------------------------------------------------------------
    // Constants

    /// @dev The price has a 8 decimal point precision.
    uint256 public constant PRICE_DECIMALS = 8;

    /// @dev Math constants.
    uint256 private constant MAX_UINT256 = type(uint256).max;

    /// @dev The maximum units of the underlying token that can be deposited into this contract
    ///      ie) for a underlying token with 18 decimals, MAX_UNDERLYING is 1B tokens.
    uint256 public constant MAX_UNDERLYING = 1_000_000_000e18;

    /// @dev TOTAL_BITS is a multiple of MAX_UNDERLYING so that {BITS_PER_UNDERLYING} is an integer.
    ///      Use the highest value that fits in a uint256 for max granularity.
    uint256 private constant TOTAL_BITS = MAX_UINT256 - (MAX_UINT256 % MAX_UNDERLYING);

    /// @dev Number of BITS per unit of deposit.
    uint256 private constant BITS_PER_UNDERLYING = TOTAL_BITS / MAX_UNDERLYING;

    /// @dev Number of BITS per unit of deposit * (1 USD).
    uint256 private constant PRICE_BITS = BITS_PER_UNDERLYING * (10**PRICE_DECIMALS);

    /// @dev TRUE_MAX_PRICE = maximum integer < (sqrt(4*PRICE_BITS + 1) - 1) / 2
    ///      Setting MAX_PRICE to the closest two power which is just under TRUE_MAX_PRICE.
    uint256 public constant MAX_PRICE = (2**96 - 1); // (2^96) - 1

    //--------------------------------------------------------------------------
    // Attributes

    /// @inheritdoc IButtonWrapper
    address public override underlying;

    /// @inheritdoc IButtonToken
    address public override oracle;

    /// @inheritdoc IButtonToken
    uint256 public override lastPrice;

    /// @dev Rebase counter
    uint256 _epoch;

    /// @inheritdoc IERC20Metadata
    string public override name;

    /// @inheritdoc IERC20Metadata
    string public override symbol;

    /// @dev internal balance, bits issued per account
    mapping(address => uint256) private _accountBits;

    /// @dev ERC20 allowances
    mapping(address => mapping(address => uint256)) private _allowances;

    //--------------------------------------------------------------------------
    // Modifiers
    modifier validRecipient(address to) {
        require(to != address(0x0), "ButtonToken: recipient zero address");
        require(to != address(this), "ButtonToken: recipient token address");
        _;
    }

    modifier onAfterRebase() {
        uint256 price;
        bool valid;
        (price, valid) = _queryPrice();
        if (valid) {
            _rebase(price);
        }
        _;
    }

    //--------------------------------------------------------------------------

    /// @param underlying_ The underlying ERC20 token address.
    /// @param name_ The ERC20 name.
    /// @param symbol_ The ERC20 symbol.
    /// @param oracle_ The oracle which provides the underlying token price.
    function initialize(
        address underlying_,
        string memory name_,
        string memory symbol_,
        address oracle_
    ) public override initializer {
        require(underlying_ != address(0), "ButtonToken: invalid underlying reference");

        // Initializing ownership to `msg.sender`
        __Ownable_init();
        underlying = underlying_;
        name = name_;
        symbol = symbol_;

        // MAX_UNDERLYING worth bits are 'pre-mined' to `address(0x)`
        // at the time of construction.
        //
        // During mint, bits are transferred from `address(0x)`
        // and during burn, bits are transferred back to `address(0x)`.
        //
        // No more than MAX_UNDERLYING can be deposited into the ButtonToken contract.
        _accountBits[address(0)] = TOTAL_BITS;

        updateOracle(oracle_);
    }

    //--------------------------------------------------------------------------
    // Owner only actions

    /// @inheritdoc IButtonToken
    function updateOracle(address oracle_) public override onlyOwner {
        uint256 price;
        bool valid;

        oracle = oracle_;
        (price, valid) = _queryPrice();
        require(valid, "ButtonToken: unable to fetch data from oracle");

        emit OracleUpdated(oracle);
        _rebase(price);
    }

    //--------------------------------------------------------------------------
    // ERC20 description attributes

    /// @inheritdoc IERC20Metadata
    function decimals() external view override returns (uint8) {
        return IERC20Metadata(underlying).decimals();
    }

    //--------------------------------------------------------------------------
    // ERC-20 token view methods

    /// @inheritdoc IERC20
    function totalSupply() external view override returns (uint256) {
        uint256 price;
        (price, ) = _queryPrice();
        return _bitsToAmount(_activeBits(), price);
    }

    /// @inheritdoc IERC20
    function balanceOf(address account) external view override returns (uint256) {
        if (account == address(0)) {
            return 0;
        }
        uint256 price;
        (price, ) = _queryPrice();
        return _bitsToAmount(_accountBits[account], price);
    }

    /// @inheritdoc IRebasingERC20
    function scaledTotalSupply() external view override returns (uint256) {
        return _bitsToUAmount(_activeBits());
    }

    /// @inheritdoc IRebasingERC20
    function scaledBalanceOf(address account) external view override returns (uint256) {
        if (account == address(0)) {
            return 0;
        }
        return _bitsToUAmount(_accountBits[account]);
    }

    /// @inheritdoc IERC20
    function allowance(address owner_, address spender) external view override returns (uint256) {
        return _allowances[owner_][spender];
    }

    //--------------------------------------------------------------------------
    // ButtonWrapper view methods

    /// @inheritdoc IButtonWrapper
    function totalUnderlying() external view override returns (uint256) {
        return _bitsToUAmount(_activeBits());
    }

    /// @inheritdoc IButtonWrapper
    function balanceOfUnderlying(address who) external view override returns (uint256) {
        if (who == address(0)) {
            return 0;
        }
        return _bitsToUAmount(_accountBits[who]);
    }

    /// @inheritdoc IButtonWrapper
    function underlyingToWrapper(uint256 uAmount) external view override returns (uint256) {
        uint256 price;
        (price, ) = _queryPrice();
        return _bitsToAmount(_uAmountToBits(uAmount), price);
    }

    /// @inheritdoc IButtonWrapper
    function wrapperToUnderlying(uint256 amount) external view override returns (uint256) {
        uint256 price;
        (price, ) = _queryPrice();
        return _bitsToUAmount(_amountToBits(amount, price));
    }

    //--------------------------------------------------------------------------
    // ERC-20 write methods

    /// @inheritdoc IERC20
    function transfer(address to, uint256 amount)
        external
        override
        validRecipient(to)
        onAfterRebase
        returns (bool)
    {
        _transfer(_msgSender(), to, _amountToBits(amount, lastPrice), amount);
        return true;
    }

    /// @inheritdoc IRebasingERC20
    function transferAll(address to)
        external
        override
        validRecipient(to)
        onAfterRebase
        returns (bool)
    {
        uint256 bits = _accountBits[_msgSender()];
        _transfer(_msgSender(), to, bits, _bitsToAmount(bits, lastPrice));
        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override validRecipient(to) onAfterRebase returns (bool) {
        if (_allowances[from][_msgSender()] != type(uint256).max) {
            _allowances[from][_msgSender()] -= amount;
            emit Approval(from, _msgSender(), _allowances[from][_msgSender()]);
        }

        _transfer(from, to, _amountToBits(amount, lastPrice), amount);
        return true;
    }

    /// @inheritdoc IRebasingERC20
    function transferAllFrom(address from, address to)
        external
        override
        validRecipient(to)
        onAfterRebase
        returns (bool)
    {
        uint256 bits = _accountBits[from];
        uint256 amount = _bitsToAmount(bits, lastPrice);

        if (_allowances[from][_msgSender()] != type(uint256).max) {
            _allowances[from][_msgSender()] -= amount;
            emit Approval(from, _msgSender(), _allowances[from][_msgSender()]);
        }

        _transfer(from, to, bits, amount);
        return true;
    }

    /// @inheritdoc IERC20
    function approve(address spender, uint256 amount) external override returns (bool) {
        _allowances[_msgSender()][spender] = amount;

        emit Approval(_msgSender(), spender, amount);
        return true;
    }

    // @inheritdoc IERC20
    function increaseAllowance(address spender, uint256 addedAmount) external returns (bool) {
        _allowances[_msgSender()][spender] += addedAmount;

        emit Approval(_msgSender(), spender, _allowances[_msgSender()][spender]);
        return true;
    }

    // @inheritdoc IERC20
    function decreaseAllowance(address spender, uint256 subtractedAmount) external returns (bool) {
        if (subtractedAmount >= _allowances[_msgSender()][spender]) {
            delete _allowances[_msgSender()][spender];
        } else {
            _allowances[_msgSender()][spender] -= subtractedAmount;
        }

        emit Approval(_msgSender(), spender, _allowances[_msgSender()][spender]);
        return true;
    }

    //--------------------------------------------------------------------------
    // RebasingERC20 write methods

    /// @inheritdoc IRebasingERC20
    function rebase() external override onAfterRebase {
        return;
    }

    //--------------------------------------------------------------------------
    // ButtonWrapper write methods

    /// @inheritdoc IButtonWrapper
    function mint(uint256 amount) external override onAfterRebase returns (uint256) {
        uint256 bits = _amountToBits(amount, lastPrice);
        uint256 uAmount = _bitsToUAmount(bits);
        _deposit(_msgSender(), _msgSender(), uAmount, amount, bits);
        return uAmount;
    }

    /// @inheritdoc IButtonWrapper
    function mintFor(address to, uint256 amount) external override onAfterRebase returns (uint256) {
        uint256 bits = _amountToBits(amount, lastPrice);
        uint256 uAmount = _bitsToUAmount(bits);
        _deposit(_msgSender(), to, uAmount, amount, bits);
        return uAmount;
    }

    /// @inheritdoc IButtonWrapper
    function burn(uint256 amount) external override onAfterRebase returns (uint256) {
        uint256 bits = _amountToBits(amount, lastPrice);
        uint256 uAmount = _bitsToUAmount(bits);
        _withdraw(_msgSender(), _msgSender(), uAmount, amount, bits);
        return uAmount;
    }

    /// @inheritdoc IButtonWrapper
    function burnTo(address to, uint256 amount) external override onAfterRebase returns (uint256) {
        uint256 bits = _amountToBits(amount, lastPrice);
        uint256 uAmount = _bitsToUAmount(bits);
        _withdraw(_msgSender(), to, uAmount, amount, bits);
        return uAmount;
    }

    /// @inheritdoc IButtonWrapper
    function burnAll() external override onAfterRebase returns (uint256) {
        uint256 bits = _accountBits[_msgSender()];
        uint256 uAmount = _bitsToUAmount(bits);
        uint256 amount = _bitsToAmount(bits, lastPrice);
        _withdraw(_msgSender(), _msgSender(), uAmount, amount, bits);
        return uAmount;
    }

    /// @inheritdoc IButtonWrapper
    function burnAllTo(address to) external override onAfterRebase returns (uint256) {
        uint256 bits = _accountBits[_msgSender()];
        uint256 uAmount = _bitsToUAmount(bits);
        uint256 amount = _bitsToAmount(bits, lastPrice);
        _withdraw(_msgSender(), to, uAmount, amount, bits);
        return uAmount;
    }

    /// @inheritdoc IButtonWrapper
    function deposit(uint256 uAmount) external override onAfterRebase returns (uint256) {
        uint256 bits = _uAmountToBits(uAmount);
        uint256 amount = _bitsToAmount(bits, lastPrice);
        _deposit(_msgSender(), _msgSender(), uAmount, amount, bits);
        return amount;
    }

    /// @inheritdoc IButtonWrapper
    function depositFor(address to, uint256 uAmount)
        external
        override
        onAfterRebase
        returns (uint256)
    {
        uint256 bits = _uAmountToBits(uAmount);
        uint256 amount = _bitsToAmount(bits, lastPrice);
        _deposit(_msgSender(), to, uAmount, amount, bits);
        return amount;
    }

    /// @inheritdoc IButtonWrapper
    function withdraw(uint256 uAmount) external override onAfterRebase returns (uint256) {
        uint256 bits = _uAmountToBits(uAmount);
        uint256 amount = _bitsToAmount(bits, lastPrice);
        _withdraw(_msgSender(), _msgSender(), uAmount, amount, bits);
        return amount;
    }

    /// @inheritdoc IButtonWrapper
    function withdrawTo(address to, uint256 uAmount)
        external
        override
        onAfterRebase
        returns (uint256)
    {
        uint256 bits = _uAmountToBits(uAmount);
        uint256 amount = _bitsToAmount(bits, lastPrice);
        _withdraw(_msgSender(), to, uAmount, amount, bits);
        return amount;
    }

    /// @inheritdoc IButtonWrapper
    function withdrawAll() external override onAfterRebase returns (uint256) {
        uint256 bits = _accountBits[_msgSender()];
        uint256 uAmount = _bitsToUAmount(bits);
        uint256 amount = _bitsToAmount(bits, lastPrice);
        _withdraw(_msgSender(), _msgSender(), uAmount, amount, bits);
        return amount;
    }

    /// @inheritdoc IButtonWrapper
    function withdrawAllTo(address to) external override onAfterRebase returns (uint256) {
        uint256 bits = _accountBits[_msgSender()];
        uint256 uAmount = _bitsToUAmount(bits);
        uint256 amount = _bitsToAmount(bits, lastPrice);
        _withdraw(_msgSender(), to, uAmount, amount, bits);
        return amount;
    }

    //--------------------------------------------------------------------------
    // Private methods

    /// @dev Internal method to commit deposit state.
    ///      NOTE: Expects bits, uAmount, amount to be pre-calculated.
    function _deposit(
        address from,
        address to,
        uint256 uAmount,
        uint256 amount,
        uint256 bits
    ) private {
        require(amount > 0, "ButtonToken: too few button tokens to mint");

        IERC20(underlying).safeTransferFrom(from, address(this), uAmount);

        _transfer(address(0), to, bits, amount);
    }

    /// @dev Internal method to commit withdraw state.
    ///      NOTE: Expects bits, uAmount, amount to be pre-calculated.
    function _withdraw(
        address from,
        address to,
        uint256 uAmount,
        uint256 amount,
        uint256 bits
    ) private {
        require(amount > 0, "ButtonToken: too few button tokens to burn");

        _transfer(from, address(0), bits, amount);

        IERC20(underlying).safeTransfer(to, uAmount);
    }

    /// @dev Internal method to commit transfer state.
    ///      NOTE: Expects bits/amounts to be pre-calculated.
    function _transfer(
        address from,
        address to,
        uint256 bits,
        uint256 amount
    ) private {
        _accountBits[from] -= bits;
        _accountBits[to] += bits;

        emit Transfer(from, to, amount);

        if (_accountBits[from] == 0) {
            delete _accountBits[from];
        }
    }

    /// @dev Updates the `lastPrice` and recomputes the internal scalar.
    function _rebase(uint256 price) private {
        if (price > MAX_PRICE) {
            price = MAX_PRICE;
        }

        lastPrice = price;

        _epoch++;

        emit Rebase(_epoch, price);
    }

    /// @dev Returns the active "un-mined" bits
    function _activeBits() private view returns (uint256) {
        return TOTAL_BITS - _accountBits[address(0)];
    }

    /// @dev Queries the oracle for the latest price
    ///      If fetched oracle price isn't valid returns the last price,
    ///      else returns the new price from the oracle.
    function _queryPrice() private view returns (uint256, bool) {
        uint256 newPrice;
        bool valid;
        (newPrice, valid) = IOracle(oracle).getData();

        // Note: we consider newPrice == 0 to be invalid because accounting fails with price == 0
        // For example, _bitsPerToken needs to be able to divide by price so a div/0 is caused
        return (valid && newPrice > 0 ? newPrice : lastPrice, valid && newPrice > 0);
    }

    /// @dev Convert button token amount to bits.
    function _amountToBits(uint256 amount, uint256 price) private pure returns (uint256) {
        return amount * _bitsPerToken(price);
    }

    /// @dev Convert underlying token amount to bits.
    function _uAmountToBits(uint256 uAmount) private pure returns (uint256) {
        return uAmount * BITS_PER_UNDERLYING;
    }

    /// @dev Convert bits to button token amount.
    function _bitsToAmount(uint256 bits, uint256 price) private pure returns (uint256) {
        return bits / _bitsPerToken(price);
    }

    /// @dev Convert bits to underlying token amount.
    function _bitsToUAmount(uint256 bits) private pure returns (uint256) {
        return bits / BITS_PER_UNDERLYING;
    }

    /// @dev Internal scalar to convert bits to button tokens.
    function _bitsPerToken(uint256 price) private pure returns (uint256) {
        return PRICE_BITS / price;
    }
}