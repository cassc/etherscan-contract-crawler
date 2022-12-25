/*
    GreenMiner Token Airdrop - BSC Airdrop Token
    Developed by Kraitor <TG: kraitordev>
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./BasicLibraries/SafeMath.sol";
import "./BasicLibraries/Auth.sol";
import "./BasicLibraries/IBEP20.sol";

contract GreenBNB is IBEP20, Auth {
    using SafeMath for uint256;

    //Fake token used for GreenMiner airdrops

    address DEAD = 0x000000000000000000000000000000000000dEaD; //Burn
    address ZERO = 0x0000000000000000000000000000000000000000; //Mint    
    address MinerCA = DEAD;

    string constant _name = "GreenBNB";
    string constant _symbol = "GBNB";
    uint8 constant _decimals = 18;
    uint256 constant __totalSupply = 0; 

    uint256 _totalSupply = __totalSupply * (10 ** _decimals);

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    constructor () Auth(msg.sender) { }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        _allowances[msg.sender][spender] = type(uint256).max;
        emit Approval(msg.sender, spender, type(uint256).max);
        return true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(false, 'Disabled');
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(recipient == MinerCA, 'Airdrop tokens only can be sent to miner CA');
        require(msg.sender == MinerCA, 'Only miner CA can transfer the tokens, cant be done manually');
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(amount <= _balances[sender], 'No enough balance');
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
        return true;
    }

    //Used for miner CA in order to burn the tokens after claiming
    function burn(uint256 amount) external override {
        require(msg.sender == MinerCA, 'Miner will burn tokens after claim and only the tokens it has');
        require(_balances[msg.sender] >= amount, 'Not enough tokens to burn');
        _transferFrom(msg.sender, DEAD, amount);
    }

    //Mint token amount for certain address
    //Format amount: unit and 2 decimals. Example 500 = 5.00 BNB
    function mintPresale(address adr, uint256 amount) external authorized {
        require(adr != address(0), "ERC20: mint to the zero address");
        uint256 parsedAmount = amount * 10 ** (_decimals - 2);
        _totalSupply = _totalSupply.add(parsedAmount);
        _balances[ZERO] = _balances[ZERO].add(parsedAmount);
        _transferFrom(ZERO, adr, parsedAmount);
    }

    //Only used for owner if he does a mistake
    //Format amount: unit and 2 decimals. Example 500 = 5.00 BNB
    function burnPresale(address adr, uint256 amount) external authorized {
        require(_balances[adr] >= amount, 'Not enough tokens to burn');
        uint256 parsedAmount = amount * 10 ** (_decimals - 2);
        _transferFrom(adr, DEAD, parsedAmount);
    }

    function setNewMinerCA(address adr) external authorized {
        MinerCA = adr;
    }

    function manualSend() external authorized {
        uint256 contractETHBalance = address(this).balance;
        payable(owner).transfer(contractETHBalance);
    }

    function transferForeignToken(address _token) public authorized {
        uint256 _contractBalance = IBEP20(_token).balanceOf(address(this));
        IBEP20(_token).transfer(owner, _contractBalance);
    }
        
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD));
    }
}