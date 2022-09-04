// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../access-control/AccessControlMixin.sol";
import "./IPegToken.sol";
import "../vault/IVault.sol";
import "../library/BocRoles.sol";

contract PegToken is IPegToken, Initializable, AccessControlMixin {
    event MintShares(address _account,uint256 _shareAmount);
    event BurnShares(address _account,uint256 _shareAmount);
    event PauseStateChanged(bool _isPaused);
    event Migrate(address[] _accounts);

    string private mName;

    string private mSymbol;

    uint8 private mDecimals;

    uint256 private mTotalShares;

    bool public isPaused;

    address public vaultAddr;


    /**
     * @dev Logic data，decimals：1e27
     */
    mapping(address => uint256) private shares;

    /**
     * @dev Allowances are nominated in tokens, not token shares.
     */
    mapping(address => mapping(address => uint256)) private allowances;

    modifier onlyVault() {
        require(msg.sender == vaultAddr, "Only Vault can operate.");
        _;
    }

    modifier whenNotPaused() {
        require(!isPaused, "No operate during pause.");
        _;
    }

    function changePauseState(bool _isPaused)
        external
        override
        onlyRole(BocRoles.GOV_ROLE)
    {
        isPaused = _isPaused;
        emit PauseStateChanged(isPaused);
    }

    function initialize(
        string calldata _nameArg,
        string calldata _symbolArg,
        uint8 _decimalsArg,
        address _vault,
        address _accessControlProxy
    ) external initializer {
        mName = _nameArg;
        mSymbol = _symbolArg;
        mDecimals = _decimalsArg;
        vaultAddr = _vault;
        _initAccessControl(_accessControlProxy);
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return mName;
    }

    /**
     * @return the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return mSymbol;
    }

    /**
     * @return the number of decimals for getting user representation of a token amount.
     */
    function decimals() public view returns (uint8) {
        return mDecimals;
    }

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() public view override returns (uint256) {
        return (mTotalShares * IVault(vaultAddr).underlyingUnitsPerShare()) / 1e27;
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return getUnderlyingUnitsByShares(_sharesOf(account));
    }

    function totalShares() external view override returns (uint256) {
        return mTotalShares;
    }

    /**
     * @return the amount of shares owned by `_account`.
     */
    function sharesOf(address _account) public view override returns (uint256) {
        return _sharesOf(_account);
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address _recipient, uint256 _amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address _spender)
        public
        view
        override
        returns (uint256)
    {
        return allowances[_owner][_spender];
    }

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
    function approve(address _spender, uint256 _amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

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
        address _sender,
        address _recipient,
        uint256 _amount
    ) public override returns (bool) {
        uint256 currentAllowance = allowances[_sender][msg.sender];
        require(
            currentAllowance >= _amount,
            "TRANSFER_AMOUNT_EXCEEDS_ALLOWANCE"
        );

        _transfer(_sender, _recipient, _amount);
        _approve(_sender, msg.sender, currentAllowance - _amount);
        return true;
    }

    /**
     * @notice Atomically increases the allowance granted to `_spender` by the caller by `_addedValue`.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in:
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol#L42
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `_spender` cannot be the the zero address.
     * - the contract must not be paused.
     */
    function increaseAllowance(address _spender, uint256 _addedValue)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            _spender,
            allowances[msg.sender][_spender] + _addedValue
        );
        return true;
    }

    /**
     * @notice Atomically decreases the allowance granted to `_spender` by the caller by `_subtractedValue`.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in:
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol#L42
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `_spender` cannot be the zero address.
     * - `_spender` must have allowance for the caller of at least `_subtractedValue`.
     * - the contract must not be paused.
     */
    function decreaseAllowance(address _spender, uint256 _subtractedValue)
        public
        returns (bool)
    {
        uint256 _currentAllowance = allowances[msg.sender][_spender];
        require(
            _currentAllowance >= _subtractedValue,
            "DECREASED_ALLOWANCE_BELOW_ZERO"
        );
        _approve(msg.sender, _spender, _currentAllowance - _subtractedValue);
        return true;
    }

    /**
     * @return the amount of shares that corresponds to `underlying units` .
     */
    function getUnderlyingUnitsByShares(uint256 _sharesAmount)
        public
        view
        override
        returns (uint256)
    {
        return (_sharesAmount * IVault(vaultAddr).underlyingUnitsPerShare()) / 1e27;
    }

    /**
     * @return the amount of Ether that corresponds to `_sharesAmount` token shares.
     */
    function getSharesByUnderlyingUnits(uint256 _underlyingUnits)
        public
        view
        override
        returns (uint256)
    {
        return (_underlyingUnits * 1e27) / IVault(vaultAddr).underlyingUnitsPerShare();
    }

    /**
     * @notice Moves `_amount` tokens from `_sender` to `_recipient`.
     * Emits a `Transfer` event.
     */
    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal {
        uint256 senderBalance = balanceOf(_sender);
        uint256 _sharesToTransfer;
        if (senderBalance == _amount) {
            _sharesToTransfer = sharesOf(_sender);
        } else {
            _sharesToTransfer = getSharesByUnderlyingUnits(_amount);
        }
        _transferShares(_sender, _recipient, _sharesToTransfer);
        emit Transfer(_sender, _recipient, _amount);
    }

    /**
     * @notice Sets `_amount` as the allowance of `_spender` over the `_owner` s tokens.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `_owner` cannot be the zero address.
     * - `_spender` cannot be the zero address.
     * - the contract must not be paused.
     */
    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) internal whenNotPaused {
        require(_owner != address(0), "APPROVE_FROM_ZERO_ADDRESS");
        require(_spender != address(0), "APPROVE_TO_ZERO_ADDRESS");

        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    /**
     * @return the amount of shares owned by `_account`.
     */
    function _sharesOf(address _account) internal view returns (uint256) {
        return shares[_account];
    }

    /**
     * @notice Moves `_sharesAmount` shares from `_sender` to `_recipient`.
     *
     * Requirements:
     *
     * - `_sender` cannot be the zero address.
     * - `_recipient` cannot be the zero address.
     * - `_sender` must hold at least `_sharesAmount` shares.
     * - the contract must not be paused.
     */
    function _transferShares(
        address _sender,
        address _recipient,
        uint256 _sharesAmount
    ) internal whenNotPaused {
        require(_sender != address(0), "TRANSFER_FROM_THE_ZERO_ADDRESS");
        require(_recipient != address(0), "TRANSFER_TO_THE_ZERO_ADDRESS");

        uint256 currentSenderShares = shares[_sender];
        require(
            _sharesAmount <= currentSenderShares,
            "TRANSFER_AMOUNT_EXCEEDS_BALANCE"
        );

        shares[_sender] = currentSenderShares - _sharesAmount;
        shares[_recipient] = shares[_recipient] + _sharesAmount;
    }

    /**
     * @notice Creates `_sharesAmount` shares and assigns them to `_recipient`, increasing the total amount of shares.
     * @dev This doesn't increase the token total supply.
     *
     * Requirements:
     *
     * - `_recipient` cannot be the zero address.
     * - the contract must not be paused.
     */
    function mintShares(address _recipient, uint256 _sharesAmount)
        external
        override
        onlyVault
        whenNotPaused
    {
        require(_recipient != address(0), "MINT_TO_THE_ZERO_ADDRESS");

        mTotalShares = mTotalShares + _sharesAmount;
        shares[_recipient] = shares[_recipient] + _sharesAmount;

        emit MintShares(_recipient,_sharesAmount);
    }

    /**
     * @notice Destroys `_sharesAmount` shares from `_account`'s holdings, decreasing the total amount of shares.
     * @dev This doesn't decrease the token total supply.
     *
     * Requirements:
     *
     * - `_account` cannot be the zero address.
     * - `_account` must hold at least `_sharesAmount` shares.
     * - the contract must not be paused.
     */
    function burnShares(address _account, uint256 _sharesAmount)
        external
        override
        onlyVault
        whenNotPaused
    {
        require(_account != address(0), "BURN_FROM_THE_ZERO_ADDRESS");

        uint256 _accountShares = shares[_account];
        require(_sharesAmount <= _accountShares, "BURN_AMOUNT_EXCEEDS_BALANCE");

        mTotalShares = mTotalShares - _sharesAmount;
        shares[_account] = _accountShares - _sharesAmount;

        emit BurnShares(_account,_sharesAmount);
    }

}