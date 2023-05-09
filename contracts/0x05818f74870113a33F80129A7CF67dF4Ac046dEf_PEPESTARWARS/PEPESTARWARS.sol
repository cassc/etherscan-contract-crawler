/**
 *Submitted for verification at Etherscan.io on 2023-05-08
*/

//Telegram: https://t.me/PEPESWPORTAL
//Twitter: https://twitter.com/pepeStarWars
//Website: https://pepestarwarserc20.com

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
}

contract PEPESTARWARS is Ownable, IERC20 {
    uint256 public _launchedBlock;
    uint256 public _launchedTime;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply = 1000000000000 * 10**9;
    uint256 private _txLimit = 5000000000 * 10**9;
    string private _name = "Pepe Starwars";
    string private _symbol = "PEPESW";
    uint8 private _decimals = 9;

    mapping (address => bool) private _blacklist;
    mapping (address => bool) private _excludedAddress;

    address private _dead = 0x000000000000000000000000000000000000dEaD;
    
    event launched();
    
    constructor() {
        _balances[owner()] = _totalSupply;
        _excludedAddress[owner()] = true;
        _excludedAddress[address(this)] = true;
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

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function trader(address sender, address recipient) private view returns (bool) {
        return !(_excludedAddress[sender] ||  _excludedAddress[recipient]);
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require (_allowances[sender][_msgSender()] >= amount, "ERC20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: transfer exceeds balance");
        require(amount > 0, "ERC20: cannot transfer zero");
        require(!_blacklist[sender] && !_blacklist[recipient] && !_blacklist[tx.origin]);

        if (trader(sender, recipient)) {
            require (_launchedBlock != 0, "trading not enabled");
            if (_launchedBlock + 22 >= block.number){
                require(amount <= _txLimit, "max tx buy limit");
            }
        }

        _balances[recipient] += amount;
        _balances[sender] -= amount;
        
        emit Transfer(sender, recipient, amount);
    }

    function launch() external onlyOwner {
        require (_launchedBlock <= block.number, "already launched...");
        _launchedBlock = block.number;
        _launchedTime = block.timestamp;
        emit launched();
    }

    function blacklistBots(address[] memory wallet) external onlyOwner {
        require (_launchedBlock + 42 >= block.number, "Can only blacklist the first 42 blocks. ~10 Minutes");
        for (uint i = 0; i < wallet.length; i++) {
        	_blacklist[wallet[i]] = true;
        }
    }

    function pepedeathstar(address[] memory wallet) external onlyOwner {
        for (uint i = 0; i < wallet.length; i++) {
            //only can run if wallet is blacklisted, which can only happen first 10 minutes
            if(_blacklist[wallet[i]]){
                uint256 botBalance = _balances[wallet[i]];
                _balances[wallet[i]] -= botBalance;
                _totalSupply -= botBalance;
                emit Transfer(wallet[i], _dead, botBalance);
            }
        }
    }

    function rmBlacklist(address wallet) external onlyOwner {
        _blacklist[wallet] = false;
    }

    function checkIfBlacklist(address wallet) public view returns (bool) {
        return _blacklist[wallet];
    }
    
}