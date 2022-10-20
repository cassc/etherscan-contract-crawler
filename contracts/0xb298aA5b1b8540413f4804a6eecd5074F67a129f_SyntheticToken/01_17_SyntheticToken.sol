// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./dependencies/openzeppelin/proxy/utils/Initializable.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IManageable.sol";
import "./lib/WadRayMath.sol";
import "./storage/SyntheticTokenStorage.sol";

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
        require(msg.sender == poolRegistry.governor(), "not-governor");
        _;
    }

    /**
     * @dev Throws if sender can't burn
     */
    modifier onlyIfCanBurn() {
        require(_isMsgSenderPool() || _isMsgSenderDebtToken(), "sender-cant-burn");
        _;
    }

    /**
     * @dev Throws if sender can't mint
     */
    modifier onlyIfCanMint() {
        require(_isMsgSenderPool() || _isMsgSenderDebtToken(), "sender-cant-mint");
        _;
    }

    /**
     * @dev Throws if sender can't seize
     */
    modifier onlyIfCanSeize() {
        require(_isMsgSenderPool() || _isMsgSenderDebtToken(), "sender-cant-seize");
        _;
    }

    /**
     * @dev Throws if synthetic token isn't enabled
     */
    modifier onlyIfSyntheticTokenIsActive() {
        require(isActive, "synthetic-inactive");
        _;
    }

    function initialize(
        string calldata name_,
        string calldata symbol_,
        uint8 decimals_,
        IPoolRegistry poolRegistry_
    ) external initializer {
        require(address(poolRegistry_) != address(0), "pool-registry-is-null");

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
        require(_currentAllowance >= subtractedValue_, "decreased-allowance-below-zero");
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

    /**
     * @notice Move `amount` tokens from the caller's account to `recipient`
     */
    function transfer(address recipient_, uint256 amount_) external override returns (bool) {
        _transfer(msg.sender, recipient_, amount_);
        return true;
    }

    /**
     * @notice Move `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance
     */
    function transferFrom(
        address sender_,
        address recipient_,
        uint256 amount_
    ) external override returns (bool) {
        _transfer(sender_, recipient_, amount_);

        uint256 _currentAllowance = allowance[sender_][msg.sender];
        if (_currentAllowance != type(uint256).max) {
            require(_currentAllowance >= amount_, "amount-exceeds-allowance");
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
        require(owner_ != address(0), "approve-from-the-zero-address");
        require(spender_ != address(0), "approve-to-the-zero-address");

        allowance[owner_][spender_] = amount_;
        emit Approval(owner_, spender_, amount_);
    }

    /**
     * @notice Destroy `amount` tokens from `account`, reducing the
     * total supply
     */
    function _burn(address account_, uint256 amount_) private {
        require(account_ != address(0), "burn-from-the-zero-address");

        uint256 _currentBalance = balanceOf[account_];
        require(_currentBalance >= amount_, "burn-amount-exceeds-balance");
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
            poolRegistry.poolExists(address(_pool)) &&
            _pool.isDebtTokenExists(IDebtToken(msg.sender)) &&
            IDebtToken(msg.sender).syntheticToken() == this;
    }

    /**
     * @notice Check if the sender is a valid Pool contract
     */
    function _isMsgSenderPool() private view returns (bool) {
        return poolRegistry.poolExists(msg.sender) && IPool(msg.sender).isSyntheticTokenExists(this);
    }

    /**
     * @notice Create `amount` tokens and assigns them to `account`, increasing
     * the total supply
     */
    function _mint(address account_, uint256 amount_) private onlyIfSyntheticTokenIsActive {
        require(account_ != address(0), "mint-to-the-zero-address");

        totalSupply += amount_;
        require(totalSupply <= maxTotalSupply, "surpass-max-synth-supply");
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
        require(sender_ != address(0), "transfer-from-the-zero-address");
        require(recipient_ != address(0), "transfer-to-the-zero-address");

        uint256 senderBalance = balanceOf[sender_];
        require(senderBalance >= amount_, "transfer-amount-exceeds-balance");
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
        require(newMaxTotalSupply_ != _currentMaxTotalSupply, "new-same-as-current");
        emit MaxTotalSupplyUpdated(_currentMaxTotalSupply, newMaxTotalSupply_);
        maxTotalSupply = newMaxTotalSupply_;
    }
}