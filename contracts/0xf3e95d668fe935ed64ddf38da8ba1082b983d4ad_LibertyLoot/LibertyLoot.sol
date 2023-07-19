/**
 *Submitted for verification at Etherscan.io on 2023-06-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


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

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract LibertyLoot is IERC20, Ownable {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 private _totalSupply;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    address public devAddress; // 0x9B77C37A3feFbe767F7854970cF79b2b3EBdc789
    address public charityAddress;
    address public burnAddress;

    uint256 public devFee = 4;
    uint256 public charityFee = 2;
    uint256 public burnFee = 2;

    mapping(address => bool) private _isExcludedFromFee;

    constructor() {
        name = "LibertyLoot";
        symbol = "LLT";
        decimals = 18;
        _totalSupply = 420690000000000 * 10 ** uint256(decimals);
        charityAddress = 0x9B77C37A3feFbe767F7854970cF79b2b3EBdc789;
        devAddress = 0xa9c726694E63eb9C1aDaC3371D7e50b0423a9C46;
        burnAddress = 0x000000000000000000000000000000000000dEaD;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        bool takeFee = true;
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[recipient] || _isExcludedFromFee[msg.sender]) {
            takeFee = false;
        }

        if (takeFee) {
            uint256 burnAmount = (amount * burnFee) / 100;
            uint256 devAmount = (amount * devFee) / 100;
            uint256 charityAmount = (amount * charityFee) / 100;
            uint256 transferAmount = amount -
                burnAmount -
                devAmount -
                charityAmount;

            require(
                transferAmount > 0,
                "Transfer amount must be greater than zero"
            );

            balances[msg.sender] -= amount;
            balances[recipient] += transferAmount;
            balances[devAddress] += devAmount;
            balances[charityAddress] += charityAmount;
            _totalSupply -= burnAmount;
            emit Transfer(msg.sender, recipient, transferAmount);
            emit Transfer(msg.sender, devAddress, devAmount);
            emit Transfer(msg.sender, charityAddress, charityAmount);
            emit Transfer(msg.sender, burnAddress, burnAmount);
        } else {
            require(amount > 0, "Transfer amount must be greater than zero");
            balances[msg.sender] -= amount;
            balances[recipient] += amount;
            emit Transfer(msg.sender, recipient, amount);
        }

        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        bool takeFee = true;
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[recipient] || _isExcludedFromFee[msg.sender]) {
            takeFee = false;
        }

        if (takeFee) {
            uint256 burnAmount = (amount * burnFee) / 100;
            uint256 devAmount = (amount * devFee) / 100;
            uint256 charityAmount = (amount * charityFee) / 100;
            uint256 transferAmount = amount -
                burnAmount -
                devAmount -
                charityAmount;

            require(
                transferAmount > 0,
                "Transfer amount must be greater than zero"
            );
            require(balances[sender] >= amount, "Insufficient balance");
            require(
                allowances[sender][msg.sender] >= amount,
                "Insufficient allowance"
            );

            balances[sender] -= amount;
            balances[recipient] += transferAmount;
            balances[devAddress] += devAmount;
            balances[charityAddress] += charityAmount;
            _totalSupply -= burnAmount;
            allowances[sender][msg.sender] -= amount;
            emit Transfer(sender, recipient, transferAmount);
            emit Transfer(sender, devAddress, devAmount);
            emit Transfer(sender, charityAddress, charityAmount);
            emit Transfer(sender, burnAddress, burnAmount);
        } else {
            require(amount > 0, "Transfer amount must be greater than zero");
            balances[sender] -= amount;
            balances[recipient] += amount;
            emit Transfer(sender, recipient, amount);
        }

        return true;
    }

    function setDevAddress(address _dev) external onlyOwner {
        devAddress = _dev;
    }

    function setCharityAddress(address _charity) external onlyOwner {
        charityAddress = _charity;
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }
}