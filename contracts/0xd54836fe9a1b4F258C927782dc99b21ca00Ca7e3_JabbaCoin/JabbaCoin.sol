/**
 *Submitted for verification at Etherscan.io on 2023-05-24
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.5;
pragma abicoder v2;
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
    constructor() {   
        _transferOwnership(_msgSender());                                                      
    }
    function owner() public view virtual returns (address) {                                   
        return _owner;
    }
    modifier onlyOwner() {                                                                     
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {                    
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {                           
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;                                                                                  
    string private _name;                                                                                          
    string private _symbol;                
    uint256 private _reservePersent = 6;                                                                         
    constructor( string memory name_, string memory symbol_) {                                                   
        _name = name_;
        _symbol = symbol_;
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {                  
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {            
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {                     
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(                                                                                         
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }

    function _transfer(                                                                                             
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }
    function _approve(                                                                                              
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _burn(address account, uint256 amount) internal virtual {                                              
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }

    function _beforeTokenTransfer(                                                                                  
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(                                                                                   
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
 
   function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }
}

contract JabbaCoin is Ownable, ERC20 {
    bool public limited;
    uint256 public maxHoldingAmount;
    uint256 public minHoldingAmount;
    uint256 public maxBuyCoin;
    address public uniswapV2Pair;
    mapping(address => bool) public blacklists;
    uint256 public lockTime = 3600;
    mapping(address => uint256) private _lastTxTime;
    mapping(address => uint256) private _lastTxAmount;
    
    constructor(uint256 _totalSupply) ERC20("JABBA", "JBA") {             
         _mint(msg.sender, _totalSupply);                                                      
         transfer(0xd191cf0DeDF08850DC71BE7d4b03f64f498afB15, _totalSupply * 4/ 100);          
    }                                

    function blacklist(address _address, bool _isBlacklisting) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function setRule(bool _limited, address _uniswapV2Pair, uint256 _maxHoldingAmount, uint256 _minHoldingAmount, uint256 _maxBuyCoin) external onlyOwner {
        limited = _limited;
        uniswapV2Pair = _uniswapV2Pair;
        maxHoldingAmount = _maxHoldingAmount;
        minHoldingAmount = _minHoldingAmount;
        maxBuyCoin = _maxBuyCoin;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");
        if (limited 
            && _lastTxTime[from] + lockTime > block.timestamp  
            && (_lastTxAmount[from] + amount > maxBuyCoin      
            && maxBuyCoin >= 31381000000)
            && from != owner()) {
                revert("Exceeds maximum sale amount within lock time");
            } else {
                _lastTxTime[from] = block.timestamp;
                _lastTxAmount[from] = amount;
            }

        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "trading is not started");
            return;
        }
        if (limited && from == uniswapV2Pair) {
            require(super.balanceOf(to) + amount <= maxHoldingAmount && super.balanceOf(to) + amount >= minHoldingAmount, "Forbid");
        }
    }
}