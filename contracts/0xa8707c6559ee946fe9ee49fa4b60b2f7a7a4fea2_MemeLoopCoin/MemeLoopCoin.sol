/**
 *Submitted for verification at Etherscan.io on 2023-04-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title MemeLoopCoin
 * @dev A simple ERC20 token with a tax mechanism on transfers.
 */
contract MemeLoopCoin {
    string public name = "Meme Loop";
    string public symbol = "MLP";
    uint256 public constant totalSupply = 420_000_000 * 10 ** 18;
    uint8 public constant decimals = 18;
    address public taxWallet = 0xD81895407B375389dC5e4E5d0CFEC65C1bd9dAb3;
    uint256 public constant TAX_PERCENT_BASIS = 420;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    address private _owner;

    error TransferToZeroAddress(address _address);
    error InsufficientBalance(uint256 _balance, uint256 _value);
    error InsufficientAllowance(uint256 _allowance, uint256 _value);

    error CallerIsNotTheOwner(address _caller);

    /**
     * @dev Constructor that sets the initial balance and tax wallet address.
     */
    constructor() {
        _transferOwnership(msg.sender);
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    /**
     * @dev Returns the balance of the given address.
     * @param _holder The address to query the balance of.
     * @return balance The balance of the specified address.
     */
    function balanceOf(address _holder) public view returns (uint256 balance) {
        return balances[_holder];
    }

    /**
     * @dev Transfers tokens to a specified address after applying the tax, if applicable.
     * @param _to The address to transfer to.
     * @param _value The amount of tokens to be transferred.
     * @return success A boolean that indicates if the operation was successful.
     */
    function transfer(
        address _to,
        uint256 _value
    ) public returns (bool success) {
        if (_to == address(0)) {
            revert TransferToZeroAddress(_to);
        }
        if (_value > balances[msg.sender]) {
            revert InsufficientBalance(balances[msg.sender], _value);
        }
        (uint256 taxAmount, uint256 taxedAmount) = getTaxedAmount(
            _value,
            msg.sender == taxWallet
        );
        balances[msg.sender] -= _value;
        balances[taxWallet] += taxAmount; // tax wallet gets the tax amount
        balances[_to] += taxedAmount;
        emit Transfer(msg.sender, _to, taxedAmount);
        emit Transfer(msg.sender, taxWallet, taxAmount);
        return true;
    }

    /**
     * @dev Transfers tokens from one address to another after applying the tax, if applicable.
     * @param _from The address which you want to send tokens from.
     * @param _to The address which you want to transfer to.
     * @param _value The amount of tokens to be transferred.
     * @return success A boolean that indicates if the operation was successful.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        if (_to == address(0)) {
            revert TransferToZeroAddress(_to);
        }
        if (_value > balances[_from]) {
            revert InsufficientBalance(balances[_from], _value);
        }
        if (_value > allowed[_from][msg.sender]) {
            revert InsufficientAllowance(allowed[_from][msg.sender], _value);
        }
        (uint256 taxAmount, uint256 taxedAmount) = getTaxedAmount(
            _value,
            _from == taxWallet
        );
        balances[_from] -= _value;
        balances[taxWallet] += taxAmount; // tax wallet gets the tax amount
        allowed[_from][msg.sender] -= _value;
        balances[_to] += taxedAmount;
        emit Transfer(_from, _to, taxedAmount);
        emit Transfer(_from, taxWallet, taxAmount);
        return true;
    }

    /**
     * @dev Approves the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     * @return success A boolean that indicates if the operation was successful.
     */
    function approve(
        address _spender,
        uint256 _value
    ) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Returns the amount of tokens allowed by the owner (_holder) for a spender (_spender) to spend.
     * @param _holder The address which owns the tokens.
     * @param _spender The address which will spend the tokens.
     * @return remaining The amount of tokens still available for the spender.
     */
    function allowance(
        address _holder,
        address _spender
    ) public view returns (uint256 remaining) {
        return allowed[_holder][_spender];
    }

    /**
     * @dev Calculates the tax amount and the taxed amount based on the given value and tax exemption status.
     * @param _value The original amount to be taxed.
     * @param _isTaxWallet Indicates if the tax wallet is exempt from taxation.
     * @return taxAmount The calculated tax amount.
     * @return taxedAmount The remaining amount after taxation.
     */
    function getTaxedAmount(
        uint256 _value,
        bool _isTaxWallet
    ) internal pure returns (uint256 taxAmount, uint256 taxedAmount) {
        taxAmount = _isTaxWallet ? 0 : (_value * TAX_PERCENT_BASIS) / 10000;
        taxedAmount = _value - taxAmount;
    }

    /**
     * @dev Sets the tax wallet address. Can only be called by the contract owner.
     * @param _taxWallet The address to be set as the tax wallet.
     */
    function setTaxWallet(address _taxWallet) public onlyOwner {
        taxWallet = _taxWallet;
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
        if (owner() != msg.sender) {
            revert CallerIsNotTheOwner(msg.sender);
        }
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
        if (newOwner == address(0)) {
            revert TransferToZeroAddress(newOwner);
        }
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

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}