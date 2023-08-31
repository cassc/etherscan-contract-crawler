// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../dependencies/openzeppelin/upgradeability/ContextUpgradeable.sol";
import "../../dependencies/openzeppelin/upgradeability/PausableUpgradeable.sol";
import "../../dependencies/openzeppelin/contracts//Context.sol";
import "../../dependencies/openzeppelin/contracts//IERC20.sol";
import "../../dependencies/openzeppelin/contracts//SafeMath.sol";
import "../../dependencies/openzeppelin/contracts//Address.sol";
import "../../dependencies/openzeppelin/contracts//Pausable.sol";
import {ICApe} from "../../interfaces/ICApe.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 */
abstract contract CApe is ContextUpgradeable, ICApe, PausableUpgradeable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private shares;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalShare;

    /**
     * @dev Returns the name of the token.
     */
    function name() public pure returns (string memory) {
        return "ParaSpace Compound APE";
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public pure returns (string memory) {
        return "cAPE";
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     */
    function decimals() public pure returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _getTotalPooledApeBalance();
    }

    /**
     * @return the entire amount of APE controlled by the protocol.
     *
     * @dev The sum of all APE balances in the protocol, equals to the total supply of PsAPE.
     */
    function getTotalPooledApeBalance() public view returns (uint256) {
        return _getTotalPooledApeBalance();
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
        return getPooledApeByShares(_sharesOf(account));
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
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
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
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
        if (sender != _msgSender()) {
            _approve(
                sender,
                _msgSender(),
                _allowances[sender][_msgSender()].sub(
                    amount,
                    "TRANSFER_AMOUNT_EXCEEDS_ALLOWANCE"
                )
            );
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
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
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "DECREASED_ALLOWANCE_BELOW_ZERO"
            )
        );
        return true;
    }

    /**
     * @return the total amount of shares in existence.
     *
     * @dev The sum of all accounts' shares can be an arbitrary number, therefore
     * it is necessary to store it in order to calculate each account's relative share.
     */
    function getTotalShares() public view returns (uint256) {
        return _getTotalShares();
    }

    /**
     * @return the amount of shares owned by `_account`.
     */
    function sharesOf(address _account) public view returns (uint256) {
        return _sharesOf(_account);
    }

    /**
     * @return the amount of shares that corresponds to `amount` protocol-controlled Ape.
     */
    function getShareByPooledApe(uint256 amount) public view returns (uint256) {
        uint256 totalPooledApe = _getTotalPooledApeBalance();
        if (totalPooledApe == 0) {
            return 0;
        } else {
            return (amount * _getTotalShares()) / totalPooledApe;
        }
    }

    /**
     * @return the amount of ApeCoin that corresponds to `_sharesAmount` token shares.
     */
    function getPooledApeByShares(uint256 sharesAmount)
        public
        view
        returns (uint256)
    {
        uint256 totalShares = _getTotalShares();
        if (totalShares == 0) {
            return 0;
        } else {
            return
                sharesAmount.mul(_getTotalPooledApeBalance()).div(totalShares);
        }
    }

    /**
     * @return the total amount (in wei) of APE controlled by the protocol.
     * @dev This is used for calculating tokens from shares and vice versa.
     * @dev This function is required to be implemented in a derived contract.
     */
    function _getTotalPooledApeBalance()
        internal
        view
        virtual
        returns (uint256);

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
        require(sender != address(0), "transfer from the zero address");
        require(recipient != address(0), "transfer to the zero address");

        uint256 _sharesToTransfer = getShareByPooledApe(amount);
        _transferShares(sender, recipient, _sharesToTransfer);
        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
    ) internal virtual whenNotPaused {
        require(owner != address(0), "approve from the zero address");
        require(spender != address(0), "approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @return the total amount of shares in existence.
     */
    function _getTotalShares() internal view returns (uint256) {
        return _totalShare;
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
        shares[_sender] = shares[_sender].sub(
            _sharesAmount,
            "transfer amount exceeds balance"
        );
        shares[_recipient] = shares[_recipient].add(_sharesAmount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 sharesAmount)
        internal
        virtual
        whenNotPaused
    {
        require(account != address(0), "mint to the zero address");

        _totalShare = _totalShare.add(sharesAmount);
        shares[account] = shares[account].add(sharesAmount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 sharesAmount)
        internal
        virtual
        whenNotPaused
    {
        require(account != address(0), "burn from the zero address");

        shares[account] = shares[account].sub(
            sharesAmount,
            "burn amount exceeds balance"
        );
        _totalShare = _totalShare.sub(sharesAmount);
    }
}