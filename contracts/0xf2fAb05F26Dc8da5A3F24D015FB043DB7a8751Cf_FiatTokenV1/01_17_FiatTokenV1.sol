/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2018-2020 CENTRE SECZ
 * Copyright (c) 2022 JPYC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.8.11;

import "./Ownable.sol";
import "./Pausable.sol";
import "./Blocklistable.sol";
import "../util/EIP712.sol";
import "./Rescuable.sol";
import "./EIP3009.sol";
import "./EIP2612.sol";
import "../upgradeability/UUPSUpgradeable.sol";

/**
 * @dev ERC20 Token backed by fiat reserves. Forked from
 * https://github.com/centrehq/centre-tokens/blob/37039f00534d3e5148269adf98bd2d42ea9fcfd7/contracts/v1/FiatTokenV1.sol,
 * https://github.com/centrehq/centre-tokens/blob/37039f00534d3e5148269adf98bd2d42ea9fcfd7/contracts/v1.1/FiatTokenV1_1.sol,
 * https://github.com/centrehq/centre-tokens/blob/37039f00534d3e5148269adf98bd2d42ea9fcfd7/contracts/v2/FiatTokenV2.sol,
 * https://github.com/centrehq/centre-tokens/blob/37039f00534d3e5148269adf98bd2d42ea9fcfd7/contracts/v2/FiatTokenV2_1.sol
 * Modifications:
 * 1. Change solidity version to 0.8.11
 * 2. Use cashe for gas optimization
 * 3. Let initialize function initialize a rescuer
 * 4. Change materMinter -> minterAdmin
 * 5. Use initializedVersion to manage the version
 * 6. Check if the approved amount is max amount for gas optimization
 */

/**
 * @title FiatToken
 * @dev ERC20 Token backed by fiat reserves
 */
contract FiatTokenV1 is
    Ownable,
    Pausable,
    Blocklistable,
    Rescuable,
    EIP3009,
    EIP2612,
    UUPSUpgradeable
{
    string public name;
    string public symbol;
    string public currency;
    uint256 internal totalSupply_;
    address public minterAdmin;
    uint8 public decimals;
    uint8 internal initializedVersion;

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(address => bool) internal minters;
    mapping(address => uint256) internal minterAllowed;

    event Mint(address indexed minter, address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 amount);
    event MinterConfigured(address indexed minter, uint256 minterAllowedAmount);
    event MinterRemoved(address indexed oldMinter);
    event MinterAdminChanged(address indexed newMinterAdmin);

    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        string memory tokenCurrency,
        uint8 tokenDecimals,
        address newMinterAdmin,
        address newPauser,
        address newBlocklister,
        address newRescuer,
        address newOwner
    ) public {
        require(
            initializedVersion == 0,
            "FiatToken: contract is already initialized"
        );
        require(
            newMinterAdmin != address(0),
            "FiatToken: new minterAdmin is the zero address"
        );
        require(
            newPauser != address(0),
            "FiatToken: new pauser is the zero address"
        );
        require(
            newBlocklister != address(0),
            "FiatToken: new blocklister is the zero address"
        );
        require(
            newRescuer != address(0),
            "FiatToken: new rescuer is the zero address"
        );
        require(
            newOwner != address(0),
            "FiatToken: new owner is the zero address"
        );

        name = tokenName;
        symbol = tokenSymbol;
        currency = tokenCurrency;
        decimals = tokenDecimals;
        minterAdmin = newMinterAdmin;
        pauser = newPauser;
        blocklister = newBlocklister;
        rescuer = newRescuer;
        _transferOwnership(newOwner);
        blocklisted[address(this)] = 1;
        DOMAIN_SEPARATOR = EIP712.makeDomainSeparator(tokenName, "1");
        CHAIN_ID = block.chainid;
        NAME = tokenName;
        VERSION = "1";
        initializedVersion = 1;
    }

    /**
     * @dev Throws if called by any account other than a minter
     */
    modifier onlyMinters() {
        require(minters[msg.sender], "FiatToken: caller is not a minter");
        _;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint. Must be less than or equal
     * to the minterAllowance of the caller.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount)
        external
        whenNotPaused
        onlyMinters
        notBlocklisted(msg.sender)
        notBlocklisted(_to)
        returns (bool)
    {
        require(_to != address(0), "FiatToken: mint to the zero address");
        require(_amount > 0, "FiatToken: mint amount not greater than 0");

        uint256 mintingAllowedAmount = minterAllowed[msg.sender];
        require(
            _amount <= mintingAllowedAmount,
            "FiatToken: mint amount exceeds minterAllowance"
        );

        totalSupply_ = totalSupply_ + _amount;
        balances[_to] = balances[_to] + _amount;
        minterAllowed[msg.sender] = mintingAllowedAmount - _amount;
        emit Mint(msg.sender, _to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    /**
     * @dev Throws if called by any account other than the minterAdmin
     */
    modifier onlyMinterAdmin() {
        require(
            msg.sender == minterAdmin,
            "FiatToken: caller is not the minterAdmin"
        );
        _;
    }

    /**
     * @dev Get minter allowance for an account
     * @param minter The address of the minter
     * @return Allowance of the minter can mint
     */
    function minterAllowance(address minter) external view returns (uint256) {
        return minterAllowed[minter];
    }

    /**
     * @dev Checks if account is a minter
     * @param account The address to check
     * @return True if account is a minter
     */
    function isMinter(address account) external view returns (bool) {
        return minters[account];
    }

    /**
     * @notice Amount of remaining tokens spender is allowed to transfer on
     * behalf of the token owner
     * @param owner     Token owner's address
     * @param spender   Spender's address
     * @return Allowance amount
     */
    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return allowed[owner][spender];
    }

    /**
     * @dev Get totalSupply of token
     * @return TotalSupply
     */
    function totalSupply() external view override returns (uint256) {
        return totalSupply_;
    }

    /**
     * @dev Get token balance of an account
     * @param account address The account
     * @return Balance amount of the account
     */
    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return balances[account];
    }

    /**
     * @notice Set spender's allowance over the caller's tokens to be a given
     * value.
     * @param spender   Spender's address
     * @param value     Allowance amount
     * @return True if successful
     */
    function approve(address spender, uint256 value)
        external
        override
        whenNotPaused
        notBlocklisted(msg.sender)
        notBlocklisted(spender)
        returns (bool)
    {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Internal function to set allowance
     * @param owner     Token owner's address
     * @param spender   Spender's address
     * @param value     Allowance amount
     */
    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal override {
        require(owner != address(0), "FiatToken: approve from the zero address");
        require(spender != address(0), "FiatToken: approve to the zero address");
        allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @notice Transfer tokens by spending allowance
     * @param from  Payer's address
     * @param to    Payee's address
     * @param value Transfer amount
     * @return True if successful
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    )
        external
        override
        whenNotPaused
        notBlocklisted(msg.sender)
        notBlocklisted(from)
        notBlocklisted(to)
        returns (bool)
    {
        uint256 _allowed = allowed[from][msg.sender];
        if (_allowed != type(uint256).max) {
            require(_allowed >= value, "FiatToken: transfer amount exceeds allowance");
            allowed[from][msg.sender] = _allowed - value;
        }
        _transfer(from, to, value);
        return true;
    }

    /**
     * @notice Transfer tokens from the caller
     * @param to    Payee's address
     * @param value Transfer amount
     * @return True if successful
     */
    function transfer(address to, uint256 value)
        external
        override
        whenNotPaused
        notBlocklisted(msg.sender)
        notBlocklisted(to)
        returns (bool)
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @notice Internal function to process transfers
     * @param from  Payer's address
     * @param to    Payee's address
     * @param value Transfer amount
     */
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal override {
        require(from != address(0), "FiatToken: transfer from the zero address");
        require(to != address(0), "FiatToken: transfer to the zero address");
        uint256 _balances = balances[from];
        require(
            value <= _balances,
            "FiatToken: transfer amount exceeds balance"
        );

        balances[from] = _balances - value;
        balances[to] = balances[to] + value;
        emit Transfer(from, to, value);
    }

    /**
     * @dev Function to add/update a new minter
     * @param minter The address of the minter
     * @param minterAllowedAmount The minting amount allowed for the minter
     * @return True if the operation was successful.
     */
    function configureMinter(address minter, uint256 minterAllowedAmount)
        external
        whenNotPaused
        onlyMinterAdmin
        returns (bool)
    {
        minters[minter] = true;
        minterAllowed[minter] = minterAllowedAmount;
        emit MinterConfigured(minter, minterAllowedAmount);
        return true;
    }

    /**
     * @dev Function to remove a minter
     * @param minter The address of the minter to remove
     * @return True if the operation was successful.
     */
    function removeMinter(address minter)
        external
        onlyMinterAdmin
        returns (bool)
    {
        minters[minter] = false;
        minterAllowed[minter] = 0;
        emit MinterRemoved(minter);
        return true;
    }

    /**
     * @dev allows a minter to burn some of its own tokens
     * Validates that caller is a minter and that sender is not blocklisted
     * amount is less than or equal to the minter's account balance
     * @param _amount uint256 the amount of tokens to be burned
     */
    function burn(uint256 _amount)
        external
        whenNotPaused
        onlyMinters
        notBlocklisted(msg.sender)
    {
        uint256 balance = balances[msg.sender];
        require(_amount > 0, "FiatToken: burn amount not greater than 0");
        require(balance >= _amount, "FiatToken: burn amount exceeds balance");

        totalSupply_ = totalSupply_ - _amount;
        balances[msg.sender] = balance - _amount;
        emit Burn(msg.sender, _amount);
        emit Transfer(msg.sender, address(0), _amount);
    }

    function updateMinterAdmin(address _newMinterAdmin) external onlyOwner {
        require(
            _newMinterAdmin != address(0),
            "FiatToken: new minterAdmin is the zero address"
        );
        minterAdmin = _newMinterAdmin;
        emit MinterAdminChanged(minterAdmin);
    }

    /**
     * @notice Increase the allowance by a given increment
     * @param spender   Spender's address
     * @param increment Amount of increase in allowance
     * @return True if successful
     */
    function increaseAllowance(address spender, uint256 increment)
        external
        whenNotPaused
        notBlocklisted(msg.sender)
        notBlocklisted(spender)
        returns (bool)
    {
        _increaseAllowance(msg.sender, spender, increment);
        return true;
    }

    /**
     * @notice Decrease the allowance by a given decrement
     * @param spender   Spender's address
     * @param decrement Amount of decrease in allowance
     * @return True if successful
     */
    function decreaseAllowance(address spender, uint256 decrement)
        external
        whenNotPaused
        notBlocklisted(msg.sender)
        notBlocklisted(spender)
        returns (bool)
    {
        _decreaseAllowance(msg.sender, spender, decrement);
        return true;
    }

    /**
     * @notice Internal function to increase the allowance by a given increment
     * @param owner     Token owner's address
     * @param spender   Spender's address
     * @param increment Amount of increase
     */
    function _increaseAllowance(
        address owner,
        address spender,
        uint256 increment
    ) internal override {
        _approve(owner, spender, allowed[owner][spender] + increment);
    }

    /**
     * @notice Internal function to decrease the allowance by a given decrement
     * @param owner     Token owner's address
     * @param spender   Spender's address
     * @param decrement Amount of decrease
     */
    function _decreaseAllowance(
        address owner,
        address spender,
        uint256 decrement
    ) internal override {
        uint256 _allowed = allowed[owner][spender];
        require(
            decrement <= _allowed,
            "FiatToken: decreased allowance below zero"
        );
        _approve(owner, spender, _allowed - decrement);
    }

    /**
     * @notice Execute a transfer with a signed authorization
     * @param from          Payer's address (Authorizer)
     * @param to            Payee's address
     * @param value         Amount to be transferred
     * @param validAfter    The time after which this is valid (unix time)
     * @param validBefore   The time before which this is valid (unix time)
     * @param nonce         Unique nonce
     * @param v             v of the signature
     * @param r             r of the signature
     * @param s             s of the signature
     */
    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external whenNotPaused notBlocklisted(from) notBlocklisted(to) {
        _transferWithAuthorization(
            from,
            to,
            value,
            validAfter,
            validBefore,
            nonce,
            v,
            r,
            s
        );
    }

    /**
     * @notice Receive a transfer with a signed authorization from the payer
     * @dev This has an additional check to ensure that the payee's address
     * matches the caller of this function to prevent front-running attacks.
     * @param from          Payer's address (Authorizer)
     * @param to            Payee's address
     * @param value         Amount to be transferred
     * @param validAfter    The time after which this is valid (unix time)
     * @param validBefore   The time before which this is valid (unix time)
     * @param nonce         Unique nonce
     * @param v             v of the signature
     * @param r             r of the signature
     * @param s             s of the signature
     */
    function receiveWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external whenNotPaused notBlocklisted(from) notBlocklisted(to) {
        _receiveWithAuthorization(
            from,
            to,
            value,
            validAfter,
            validBefore,
            nonce,
            v,
            r,
            s
        );
    }

    /**
     * @notice Attempt to cancel an authorization
     * @dev Works only if the authorization is not yet used.
     * @param authorizer    Authorizer's address
     * @param nonce         Nonce of the authorization
     * @param v             v of the signature
     * @param r             r of the signature
     * @param s             s of the signature
     */
    function cancelAuthorization(
        address authorizer,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external whenNotPaused {
        _cancelAuthorization(authorizer, nonce, v, r, s);
    }

    /**
     * @notice Update allowance with a signed permit
     * @param owner       Token owner's address (Authorizer)
     * @param spender     Spender's address
     * @param value       Amount of allowance
     * @param deadline    Expiration time, seconds since the epoch
     * @param v           v of the signature
     * @param r           r of the signature
     * @param s           s of the signature
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external whenNotPaused notBlocklisted(owner) notBlocklisted(spender) {
        _permit(owner, spender, value, deadline, v, r, s);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    uint256[50] private __gap;
}