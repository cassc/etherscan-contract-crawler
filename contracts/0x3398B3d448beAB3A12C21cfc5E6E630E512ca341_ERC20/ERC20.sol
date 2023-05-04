/**
 *Submitted for verification at Etherscan.io on 2023-05-03
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.0 <0.9.0;
// Chud Twitter: https://twitter.com/Chudjakcoineth
// Chud Telegram: https://t.me/OfficialChudCoin
// Chud Website: https://www.mrchud.com/
abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is Context, IERC20 {
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) public _balances;
    mapping(address => bool) liquidityPair;
    mapping(address => bool) liquidityProvider;

    uint256 _totalSupply;
    uint256 public maxWallet;
    uint256 public maxTransaction;
    bool limitInPlace;
    address public ownerWallet;

    string private _name;
    string private _symbol;

    modifier onlyOwner() {
        require(_msgSender() == ownerWallet, "You are not the owner");
        _;
    }

    constructor(string memory name_, string memory symbol_, uint256 supply) {
        _name = name_;
        _symbol = symbol_;
        _mint(_msgSender(), supply * (10**18));

        ownerWallet = _msgSender();
    }

    receive() external payable {}

    function name() public view override returns (string memory) {
        return _name;
    }
 
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }
     
    function renounceOwnership() external onlyOwner {
        ownerWallet = address(0);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address, use renounceOwnership Function");

        if(balanceOf(ownerWallet) > 0) _transfer(ownerWallet, newOwner, balanceOf(ownerWallet));

        ownerWallet = newOwner;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");


        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal view {
        if(limitInPlace){
            if(liquidityPair[from]){
                require(amount <= maxTransaction && balanceOf(to) + amount <= maxWallet, "Amount is over Max Transaction");
            } else if(liquidityPair[to] && !liquidityProvider[from]) {
                require(amount <= maxTransaction, "Amount is over Max Transaction");
            }
        }
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");
        _beforeTokenTransfer(from, to, amount);
        uint256 fromBalance = _balances[from];
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }
        emit Transfer(from, to, amount);
    }

    function setLimits(bool inPlace, uint256 _maxTransaction, uint256 _maxWallet) external onlyOwner {
        require(_maxTransaction >= 10 && _maxWallet > 10, "Max Transaction and Max Wallet must be over .1%");
        maxTransaction = (_totalSupply * _maxTransaction) / 10000;
        maxWallet = (_totalSupply * _maxWallet) / 10000;
        limitInPlace = inPlace;
    }

    function setLiquidityProvider(address provider, bool isProvider) external onlyOwner {
        liquidityProvider[provider] = isProvider;
    }

    function setPair(address pairs, bool isPair) external onlyOwner {
        liquidityPair[pairs] = isPair;
    }

    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }
}