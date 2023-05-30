// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract TaxToken is IERC20, Ownable {

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping (address => bool) public Blacklist;

    address public _taxAddress;



    
    address private _creator;
    uint256 private _taxFee = 5;
    uint256 private constant _feeDivider = 100;

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_, address taxAddress_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _creator = msg.sender;
        _totalSupply = totalSupply_;
        _taxAddress = taxAddress_;
        _balances[msg.sender] = totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
     function tax() public view  returns (uint256) {
        return _taxFee;
    }
    function taxAddress() public view  returns (address) {
        return _taxAddress;
    }
    function isBlacklisted(address user) public view returns (bool) {
        return Blacklist[user];
    }


    function setTaxAddress(address taxAddress_) external onlyOwner()  {
        _taxAddress = taxAddress_;
    }

    function setBlacklist(address[] memory users, bool value) external onlyOwner()  {
        
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            require(user != _creator, "Can't blacklist creator");
            if (value) {
                Blacklist[user] = true;
            } else {
                delete Blacklist[user];
            }
        }    
    }  
    function setTax(uint256 tax_) external onlyOwner()  {
        
        _taxFee = tax_;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(!Blacklist[msg.sender] && !Blacklist[recipient],  "Address is blacklisted");
        if(msg.sender == _creator || recipient == _creator) {
            _balances[msg.sender] = _balances[msg.sender] - amount;
            _balances[recipient] = _balances[recipient] + (amount);
            emit Transfer(msg.sender, recipient, amount);
            return true;
        }
        uint256 taxAmount = (amount * _taxFee) / (_feeDivider);
        uint256 transferAmount = amount - taxAmount;

        _balances[msg.sender] = _balances[msg.sender] - amount;
        _balances[recipient] = _balances[recipient] +(transferAmount);
        _balances[_taxAddress] = _balances[_taxAddress] + (taxAmount);

        emit Transfer(msg.sender, recipient, transferAmount);
        emit Transfer(msg.sender, _taxAddress, taxAmount);

        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        require(_creator != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(!Blacklist[msg.sender] && !Blacklist[recipient] && !Blacklist[sender], "Address is blacklisted");
        if(sender == _creator  || recipient == _creator) {
            _balances[sender] = _balances[sender] - amount;
            _balances[recipient] = _balances[recipient] + (amount);
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;

            emit Transfer(sender, recipient, amount);
            return true;
        }
        uint256 taxAmount = amount * (_taxFee) / (_feeDivider);
        uint256 transferAmount = amount - (taxAmount);

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + (transferAmount);
        _balances[_taxAddress] = _balances[_taxAddress] + (taxAmount);
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;

        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, _taxAddress, taxAmount);

        return true;
    }
}