// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./dependencies/openzeppelin/proxy/utils/Initializable.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IManageable.sol";
import "./lib/WadRayMath.sol";
import "./storage/SyntheticTokenStorage.sol";

error SenderIsNotGovernor();
error SenderCanNotBurn();
error SenderCanNotMint();
error SenderCanNotSeize();
error SyntheticIsInactive();
error NameIsNull();
error SymbolIsNull();
error DecimalsIsNull();
error PoolRegistryIsNull();
error DecreasedAllowanceBelowZero();
error AmountExceedsAllowance();
error ApproveFromTheZeroAddress();
error ApproveToTheZeroAddress();
error BurnFromTheZeroAddress();
error BurnAmountExceedsBalance();
error MintToTheZeroAddress();
error SurpassMaxSynthSupply();
error TransferFromTheZeroAddress();
error TransferToTheZeroAddress();
error TransferAmountExceedsBalance();
error NewValueIsSameAsCurrent();

/**
 * @title Synthetic Token contract
 */
contract SyntheticToken is Initializable, SyntheticTokenStorageV1 {
    using WadRayMath for uint256;

    string public constant VERSION = "1.0.0";

    /// @notice Emitted when active flag is updated
    event SyntheticTokenActiveUpdated(bool newActive);

    /// @notice Emitted when max total supply is updated
    event MaxTotalSupplyUpdated(uint256 oldMaxTotalSupply, uint256 newMaxTotalSupply);

    /**
     * @notice Throws if caller isn't the governor
     */
    modifier onlyGovernor() {
        if (msg.sender != poolRegistry.governor()) revert SenderIsNotGovernor();
        _;
    }

    /**
     * @dev Throws if sender can't burn
     */
    modifier onlyIfCanBurn() {
        if (!_isMsgSenderPool() && !_isMsgSenderDebtToken()) revert SenderCanNotBurn();
        _;
    }

    /**
     * @dev Throws if sender can't mint
     */
    modifier onlyIfCanMint() {
        if (!_isMsgSenderPool() && !_isMsgSenderDebtToken()) revert SenderCanNotMint();
        _;
    }

    /**
     * @dev Throws if sender can't seize
     */
    modifier onlyIfCanSeize() {
        if (!_isMsgSenderPool() && !_isMsgSenderDebtToken()) revert SenderCanNotSeize();
        _;
    }

    /**
     * @dev Throws if synthetic token isn't enabled
     */
    modifier onlyIfSyntheticTokenIsActive() {
        if (!isActive) revert SyntheticIsInactive();
        _;
    }

    function initialize(
        string calldata name_,
        string calldata symbol_,
        uint8 decimals_,
        IPoolRegistry poolRegistry_
    ) external initializer {
        if (bytes(name_).length == 0) revert NameIsNull();
        if (bytes(symbol_).length == 0) revert SymbolIsNull();
        if (decimals_ == 0) revert DecimalsIsNull();
        if (address(poolRegistry_) == address(0)) revert PoolRegistryIsNull();

        poolRegistry = poolRegistry_;
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        isActive = true;
        maxTotalSupply = type(uint256).max;
    }

    /**
     * @notice Set `amount` as the allowance of `spender` over the caller's tokens
     */
    function approve(address spender_, uint256 amount_) external override returns (bool) {
        _approve(msg.sender, spender_, amount_);
        return true;
    }

    /**
     * @notice Burn synthetic token
     * @param from_ The account to burn from
     * @param amount_ The amount to burn
     */
    function burn(address from_, uint256 amount_) external override onlyIfCanBurn {
        _burn(from_, amount_);
    }

    /**
     * @notice Atomically decrease the allowance granted to `spender` by the caller
     */
    function decreaseAllowance(address spender_, uint256 subtractedValue_) external returns (bool) {
        uint256 _currentAllowance = allowance[msg.sender][spender_];
        if (_currentAllowance < subtractedValue_) revert DecreasedAllowanceBelowZero();
        unchecked {
            _approve(msg.sender, spender_, _currentAllowance - subtractedValue_);
        }
        return true;
    }

    /**
     * @notice Atomically increase the allowance granted to `spender` by the caller
     */
    function increaseAllowance(address spender_, uint256 addedValue_) external returns (bool) {
        _approve(msg.sender, spender_, allowance[msg.sender][spender_] + addedValue_);
        return true;
    }

    /**
     * @notice Mint synthetic token
     * @param to_ The account to mint to
     * @param amount_ The amount to mint
     */
    function mint(address to_, uint256 amount_) external override onlyIfCanMint {
        _mint(to_, amount_);
    }

    /**
     * @notice Seize synthetic tokens
     * @dev Same as _transfer
     * @param to_ The account to seize from
     * @param to_ The beneficiary account
     * @param amount_ The amount to seize
     */
    function seize(
        address from_,
        address to_,
        uint256 amount_
    ) external override onlyIfCanSeize {
        _transfer(from_, to_, amount_);
    }

    /// @inheritdoc IERC20
    function transfer(address recipient_, uint256 amount_) external override returns (bool) {
        _transfer(msg.sender, recipient_, amount_);
        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(
        address sender_,
        address recipient_,
        uint256 amount_
    ) external override returns (bool) {
        _transfer(sender_, recipient_, amount_);

        uint256 _currentAllowance = allowance[sender_][msg.sender];
        if (_currentAllowance != type(uint256).max) {
            if (_currentAllowance < amount_) revert AmountExceedsAllowance();
            unchecked {
                _approve(sender_, msg.sender, _currentAllowance - amount_);
            }
        }

        return true;
    }

    /**
     * @notice Set `amount` as the allowance of `spender` over the `owner` s tokens
     */
    function _approve(
        address owner_,
        address spender_,
        uint256 amount_
    ) private {
        if (owner_ == address(0)) revert ApproveFromTheZeroAddress();
        if (spender_ == address(0)) revert ApproveToTheZeroAddress();

        allowance[owner_][spender_] = amount_;
        emit Approval(owner_, spender_, amount_);
    }

    /**
     * @notice Destroy `amount` tokens from `account`, reducing the
     * total supply
     */
    function _burn(address account_, uint256 amount_) private {
        if (account_ == address(0)) revert BurnFromTheZeroAddress();

        uint256 _currentBalance = balanceOf[account_];
        if (_currentBalance < amount_) revert BurnAmountExceedsBalance();
        unchecked {
            balanceOf[account_] = _currentBalance - amount_;
            totalSupply -= amount_;
        }

        emit Transfer(account_, address(0), amount_);
    }

    /**
     * @notice Check if the sender is a valid DebtToken contract
     */
    function _isMsgSenderDebtToken() private view returns (bool) {
        IPool _pool = IManageable(msg.sender).pool();

        return
            poolRegistry.isPoolRegistered(address(_pool)) &&
            _pool.doesDebtTokenExist(IDebtToken(msg.sender)) &&
            IDebtToken(msg.sender).syntheticToken() == this;
    }

    /**
     * @notice Check if the sender is a valid Pool contract
     */
    function _isMsgSenderPool() private view returns (bool) {
        return poolRegistry.isPoolRegistered(msg.sender) && IPool(msg.sender).doesSyntheticTokenExist(this);
    }

    /**
     * @notice Create `amount` tokens and assigns them to `account`, increasing
     * the total supply
     */
    function _mint(address account_, uint256 amount_) private onlyIfSyntheticTokenIsActive {
        if (account_ == address(0)) revert MintToTheZeroAddress();

        totalSupply += amount_;
        if (totalSupply > maxTotalSupply) revert SurpassMaxSynthSupply();
        balanceOf[account_] += amount_;
        emit Transfer(address(0), account_, amount_);
    }

    /**
     * @notice Move `amount` of tokens from `sender` to `recipient`
     */
    function _transfer(
        address sender_,
        address recipient_,
        uint256 amount_
    ) private {
        if (sender_ == address(0)) revert TransferFromTheZeroAddress();
        if (recipient_ == address(0)) revert TransferToTheZeroAddress();

        uint256 senderBalance = balanceOf[sender_];
        if (senderBalance < amount_) revert TransferAmountExceedsBalance();
        unchecked {
            balanceOf[sender_] = senderBalance - amount_;
            balanceOf[recipient_] += amount_;
        }

        emit Transfer(sender_, recipient_, amount_);
    }

    /**
     * @notice Enable/Disable Synthetic Token
     */
    function toggleIsActive() external override onlyGovernor {
        bool _newIsActive = !isActive;
        emit SyntheticTokenActiveUpdated(_newIsActive);
        isActive = _newIsActive;
    }

    /**
     * @notice Update max total supply
     * @param newMaxTotalSupply_ The new max total supply
     */
    function updateMaxTotalSupply(uint256 newMaxTotalSupply_) external override onlyGovernor {
        uint256 _currentMaxTotalSupply = maxTotalSupply;
        if (newMaxTotalSupply_ == _currentMaxTotalSupply) revert NewValueIsSameAsCurrent();
        emit MaxTotalSupplyUpdated(_currentMaxTotalSupply, newMaxTotalSupply_);
        maxTotalSupply = newMaxTotalSupply_;
    }
}