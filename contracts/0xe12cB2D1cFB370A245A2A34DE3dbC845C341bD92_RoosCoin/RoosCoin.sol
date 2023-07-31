/**
 *Submitted for verification at Etherscan.io on 2023-07-30
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}



pragma solidity ^0.8.0;


contract RoosCoin {
    using SafeMath for uint256;

    string private constant _name = "Roos Coin";
    string private constant _symbol = "Roos";
    uint8 private constant _decimals = 18;
    uint256 private _totalSupply = 10_000_000_000_000 * 10**_decimals;

    uint256 private _burnRate = 50; // 0.5% burn rate (0.5 * 100)
    uint256 private _liquidityFeeRate = 1; // 1% liquidity fee rate
    uint256 private _redistributionRate = 100; // 1% redistribution fee rate (1 * 100)
    uint256 private _buybackFeeRate = 5; // 0.5% buyback fee rate (0.5 * 10)

    address private _owner;
    address private _buybackWallet = 0x03f402c57EB6839CA70856756032080CAf1Ab58D;
    address private _liquidityPool;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address[] private _tokenHolders;

    mapping(address => bool) private _excludedFromFees; // Addresses excluded from paying fees
    mapping(address => bool) private _excludedFromRewards; // Addresses excluded from receiving rewards

    bool private _feesEnabled = true;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the contract owner can call this function.");
        _;
    }

    constructor() {
        _owner = msg.sender;
        _balances[msg.sender] = _totalSupply;
        _tokenHolders.push(msg.sender);
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function setLiquidityPool(address liquidityPool) external onlyOwner {
        require(liquidityPool != address(0), "Invalid liquidity pool address");
        _liquidityPool = liquidityPool;
    }

    function renounceOwnership() external onlyOwner {
        _owner = address(0);
        emit OwnershipTransferred(msg.sender, address(0));
    }

    function setFeesEnabled(bool enabled) external onlyOwner {
        _feesEnabled = enabled;
    }

    // Function to add addresses to the excluded list for paying fees (only callable by the contract owner)
    function excludeFromFees(address account) external onlyOwner {
        require(account != address(0), "Invalid address");
        _excludedFromFees[account] = true;
    }

    // Function to remove addresses from the excluded list for paying fees (only callable by the contract owner)
    function includeInFees(address account) external onlyOwner {
        require(account != address(0), "Invalid address");
        _excludedFromFees[account] = false;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _excludedFromFees[account];
    }

    // Function to add addresses to the excluded list for receiving rewards (only callable by the contract owner)
    function excludeFromRewards(address account) external onlyOwner {
        require(account != address(0), "Invalid address");
        _excludedFromRewards[account] = true;
    }

    // Function to remove addresses from the excluded list for receiving rewards (only callable by the contract owner)
    function includeInRewards(address account) external onlyOwner {
        require(account != address(0), "Invalid address");
        _excludedFromRewards[account] = false;
    }

    function isExcludedFromRewards(address account) public view returns (bool) {
        return _excludedFromRewards[account];
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount must be greater than zero");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        uint256 burnAmount = amount.mul(_burnRate).div(10000); // divide by 10000 to convert from 0.5% (50 / 10000)
        uint256 liquidityFee = amount.mul(_liquidityFeeRate).div(100);
        uint256 redistributionFee = amount.mul(_redistributionRate).div(10000); // divide by 10000 to convert from 1% (100 / 10000)
        uint256 buybackFee = amount.mul(_buybackFeeRate).div(1000); // divide by 1000 to convert from 0.5% (5 / 1000)

        uint256 transferAmount = amount.sub(burnAmount).sub(liquidityFee).sub(redistributionFee).sub(buybackFee);

        _balances[sender] = senderBalance.sub(amount);
        _balances[recipient] = _balances[recipient].add(transferAmount);

        // Apply fees if enabled and the sender is not excluded from fees
        if (_feesEnabled && !_excludedFromFees[sender]) {
            _balances[address(this)] = _balances[address(this)].add(liquidityFee).add(redistributionFee);

            // Transfer buyback fee to the buyback wallet
            _balances[_buybackWallet] = _balances[_buybackWallet].add(buybackFee);

            // Update token holders if recipient is a new address
            if (_balances[recipient] == 0) {
                _tokenHolders.push(recipient);
            }

            emit Transfer(sender, recipient, transferAmount);
            emit Transfer(sender, address(0), burnAmount);
            emit Transfer(sender, _buybackWallet, buybackFee);

            // Transfer liquidity fee to the liquidity pool
            if (_liquidityPool != address(0) && liquidityFee > 0) {
                _balances[_liquidityPool] = _balances[_liquidityPool].add(liquidityFee);
                emit Transfer(sender, _liquidityPool, liquidityFee);
            }

            // Distribute redistribution fee to token holders
            if (redistributionFee > 0) {
                _distributeRedistributionFee(redistributionFee);
            }
        } else {
            // Fees are disabled or the sender is excluded, transfer the full amount without applying fees
            _balances[recipient] = _balances[recipient].add(amount);
            _balances[sender] = _balances[sender].sub(amount);
            emit Transfer(sender, recipient, amount);
        }
    }

    function _distributeRedistributionFee(uint256 amount) internal {
        uint256 numTokenHolders = _tokenHolders.length;
        if (numTokenHolders > 0) {
            uint256 feePerHolder = amount.div(numTokenHolders);
            for (uint256 i = 0; i < numTokenHolders; i++) {
                address holder = _tokenHolders[i];
                if (!_excludedFromRewards[holder]) {
                    _balances[holder] = _balances[holder].add(feePerHolder);
                    emit Transfer(address(this), holder, feePerHolder);
                }
            }
        }
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}