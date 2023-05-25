/**
 *Submitted for verification at Etherscan.io on 2023-05-18
*/

pragma solidity 0.8.18;

contract GLCK20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public _whitelist;
    mapping(address => bool) public _blacklist;
    mapping(address => bool) public _pool;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint8 public _max;
    address public _dev;
    

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyDev() {
        require(msg.sender == _dev, "GORLOCK: Only the developer can call this function");
        _;
    }

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint supply_, uint8 max_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _balances[msg.sender] = supply_ * 10 ** decimals_;
        _totalSupply = supply_ * 10 ** decimals_;
        _dev = msg.sender;
        _whitelist[msg.sender] = true;
        _max = max_;
    }

    function name() public view returns (string memory) {return _name;}
    function symbol() public view returns (string memory) {return _symbol;}
    function decimals() public view returns (uint8) {return _decimals;}
    function totalSupply() public view returns (uint256) {return _totalSupply;}
    function balanceOf(address account) public view returns (uint256) {return _balances[account];}
    function allowance(address owner, address spender) public view returns (uint256) {return _allowances[owner][spender];}

    function changeMax(uint8 max_) external onlyDev {
        _max = max_;
    }

    function maxInt(uint8 max_) internal view returns (uint256) {
        return _totalSupply * max_ / 100;
    }

    function changeDev(address dev_) external onlyDev {
        _dev = dev_;
    }

    function setWhitelist(address address_, bool whitelist_) external onlyDev {
        _whitelist[address_] = whitelist_;
    }

    function setBlacklist(address address_, bool blacklist_) external onlyDev {
        _blacklist[address_] = blacklist_;
    }

    function setPool(address address_, bool pool_) external onlyDev {
        _pool[address_] = pool_;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(_balances[from] >= amount, "GORLOCK: transfer amount exceeds balance");
        require(_whitelist[from] || _whitelist[to] || _pool[to] || _balances[to] + amount <= maxInt(_max), "GORLOCK: Receipient wallet exceeds max with this transfer!");
        require(!_blacklist[from] && !_blacklist[to], "GORLOCK: Transfer denied. One or both parties are blacklisted.");
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= amount, "GORLOCK: insufficient allowance");
        _approve(owner, spender, currentAllowance - amount);
    }
}