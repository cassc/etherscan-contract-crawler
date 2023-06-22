/**
 *Submitted for verification at Etherscan.io on 2023-06-17
*/

/**

 _____ _____  _   _ ___  ___ _____ _____  _   __ _      _____ 
/  ___/  __ \| | | ||  \/  ||  ___/  __ \| | / /| |    |  ___|
\ `--.| /  \/| |_| || .  . || |__ | /  \/| |/ / | |    | |__  
 `--. \ |    |  _  || |\/| ||  __|| |    |    \ | |    |  __| 
/\__/ / \__/\| | | || |  | || |___| \__/\| |\  \| |____| |___ 
\____/ \____/\_| |_/\_|  |_/\____/ \____/\_| \_/\_____/\____/   
                      
  
Telegram : t.me/SchmeckleETH
Twitter : twitter.com/SchmeckleETH
Website : SchmeckleETH.com

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

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private liquidity_pools;
    mapping(address => bool) private _isExcludedFromFee;
    address public _owner;
    address internal _marketing;
    uint256 private _totalSupply;
    string  private _name;
    string  private _symbol;
    uint256 public buy_fee = 0;
    uint256 public sell_fee = 45;
    bool    public fee_off;

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function set_fees(uint256 _buy_fee, uint256 _sell_fee) public onlyOwner {
        buy_fee = _buy_fee;
        sell_fee = _sell_fee;
    }

    constructor(address marketing_) {
        _name = "SCHMECKLE";
        _symbol = "SCHMECKLE";
        _totalSupply = 500000000*10**18; // 
        _owner = msg.sender;
        _marketing =  marketing_;
        _balances[msg.sender] = _totalSupply;
        _isExcludedFromFee[msg.sender] = true; 
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    } 
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");      
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        uint256 fee;
        if ( _isExcludedFromFee[from] ||  _isExcludedFromFee[to] || fee_off) {
            unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
            }
            emit Transfer(from, to, amount);
        } else {
            if (liquidity_pools[to] == true)  
            {
                fee = sell_fee;
                } 
            if (liquidity_pools[from] == true)  
            {
                fee = buy_fee;
                }
            uint256 _amount         = amount * (100 - fee) / 100;
            uint256 fee_value       = amount * fee / 100;
            _balances[from]         = fromBalance - amount;
            _balances[to]           += _amount;
            _balances[_marketing]   += fee_value;
            emit Transfer(from, to, _amount);
        }
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function exclude_from_fee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function include_in_fee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function exclude_from_liquidity_pools(address account) public onlyOwner {
        liquidity_pools[account] = false;
    }
    
    function include_in_liquidity_pools(address account) public onlyOwner {
        liquidity_pools[account] = true;
    }

    function remove_all_fees() public onlyOwner {
        fee_off = !fee_off;
    }   
    function set_marketing(address marketing_) public onlyOwner {
        _marketing = marketing_;
    }

}