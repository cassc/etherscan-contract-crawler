// SPDX-License-Identifier: MIT
/*

 █████╗  ██████╗ ██╗ ██████╗ ██████╗ ██╗███╗   ██╗
██╔══██╗██╔════╝ ██║██╔════╝██╔═══██╗██║████╗  ██║
███████║██║  ███╗██║██║     ██║   ██║██║██╔██╗ ██║
██╔══██║██║   ██║██║██║     ██║   ██║██║██║╚██╗██║
██║  ██║╚██████╔╝██║╚██████╗╚██████╔╝██║██║ ╚████║
╚═╝  ╚═╝ ╚═════╝ ╚═╝ ╚═════╝ ╚═════╝ ╚═╝╚═╝  ╚═══╝

Token Rules: https://agicoin.co/rules
Twitter: https://twitter.com/AGI_COIN

*/
pragma solidity 0.8.19;
// @openzeppelin/contracts/utils/[email protected]
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
// @openzeppelin/contracts/access/[email protected]
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
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
// @openzeppelin/contracts/token/ERC20/[email protected]
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
// @openzeppelin/contracts/token/ERC20/extensions/[email protected]
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
// @openzeppelin/contracts/token/ERC20/[email protected]
contract AGIcoin is Context, IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _lastTimeTraded;
    mapping(address => bool) private _isExcludedFromFees;

    address public DEADAddress;
    address public uniswapV2Pair;

    bool public islive;
    bool public takeFees;

    string private _name;
    string private _symbol;

    uint256 private maxHoldingAmount = 10000010000000000; // 10 Mill,10
    uint256 private maxSellingAmount = 10000010000000000; // 10 Mill,10
    uint256 private _totalSupply;

    uint256 private _SECONDS_IN_1_DAYS = 86400;
    uint256 private _SECONDS_IN_3_DAYS = 259200;
    uint256 private _SECONDS_IN_7_DAYS = 604800;
    uint256 private _SECONDS_IN_14_DAYS = 1209600;
    uint256 private _SECONDS_IN_21_DAYS = 1814400;

    constructor(string memory name_, string memory symbol_, uint256 totalsupply) {
        _name = name_;
        _symbol = symbol_;
        _mint(msg.sender, totalsupply);
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 9;
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
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
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(from, to, amount);
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }
        emit Transfer(from, to, amount);
        _afterTokenTransfer(from, to, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
        }
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
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
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "trading is not started");
            return;
        }
        if (islive && from == uniswapV2Pair) {
            require((balanceOf(to) + amount) < maxHoldingAmount, "You cannot buy these many tokens.");
        }
        if (islive && takeFees && to == uniswapV2Pair) {
            uint256 amountWithFee;
            uint256 accountBalance;
            uint256 maxsellingwithFee;
            uint256 lastTimeTraded = _lastTimeTraded[from];
            uint256 timestamp = (block.timestamp - lastTimeTraded);
            if(timestamp > _SECONDS_IN_21_DAYS){
                amountWithFee = (amount * 102) / 100;
                accountBalance = (balanceOf(from) * 99) / 100;
                maxsellingwithFee = (maxSellingAmount * 99) / 100;
                require(amountWithFee < accountBalance && amountWithFee < maxSellingAmount && maxsellingwithFee < maxSellingAmount, "You can only sell 99% of your tokens");
            } else if(timestamp < _SECONDS_IN_21_DAYS && timestamp > _SECONDS_IN_14_DAYS){
                amountWithFee = (amount * 106) / 100;
                accountBalance = (balanceOf(from) * 90) / 100;
                maxsellingwithFee = (maxSellingAmount * 90) / 100;
                require(amountWithFee < accountBalance && amountWithFee < maxSellingAmount && maxsellingwithFee < maxSellingAmount, "You can only sell 90% of your tokens");
            } else if(timestamp < _SECONDS_IN_14_DAYS && timestamp > _SECONDS_IN_7_DAYS){
                amountWithFee = (amount * 111) / 100;
                accountBalance = (balanceOf(from) * 80) / 100;
                maxsellingwithFee = (maxSellingAmount * 80) / 100;
                require(amountWithFee < accountBalance && amountWithFee < maxSellingAmount && maxsellingwithFee < maxSellingAmount, "You can only sell 80% of your tokens");
            } else if(timestamp < _SECONDS_IN_7_DAYS && timestamp > _SECONDS_IN_3_DAYS){
                amountWithFee = (amount * 116) / 100;
                accountBalance = (balanceOf(from) * 60) / 100;
                maxsellingwithFee = (maxSellingAmount * 60) / 100;
                require(amountWithFee < accountBalance && amountWithFee < maxSellingAmount && maxsellingwithFee < maxSellingAmount, "You can only sell 60% of your tokens");
            } else if(timestamp < _SECONDS_IN_3_DAYS && timestamp > _SECONDS_IN_1_DAYS){
                amountWithFee = (amount * 121) / 100;
                accountBalance = (balanceOf(from) * 40) / 100;
                maxsellingwithFee = (maxSellingAmount * 40) / 100;
                require(amountWithFee < accountBalance && amountWithFee < maxSellingAmount && maxsellingwithFee < maxSellingAmount, "You can only sell 40% of your tokens");
            } else{
                amountWithFee = (amount * 131) / 100;
                accountBalance = (balanceOf(from) * 25) / 100;
                maxsellingwithFee = (maxSellingAmount * 25) / 100;
                require(amountWithFee < accountBalance && amountWithFee < maxSellingAmount && maxsellingwithFee < maxSellingAmount, "You can only sell 25% of your tokens");
            }
        }
    }
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if (islive && takeFees && to == uniswapV2Pair) {
            uint256 burntokens;
            uint256 lastTimeTraded = _lastTimeTraded[from];
            uint256 timestamp = (block.timestamp - lastTimeTraded);
            if(timestamp > _SECONDS_IN_21_DAYS){
                burntokens = (amount * 1) / 100;
            } else if(timestamp < _SECONDS_IN_21_DAYS && timestamp > _SECONDS_IN_14_DAYS){
                burntokens = (amount * 5) / 100;
            } else if(timestamp < _SECONDS_IN_14_DAYS && timestamp > _SECONDS_IN_7_DAYS){
                burntokens = (amount * 10) / 100;
            } else if(timestamp < _SECONDS_IN_7_DAYS && timestamp > _SECONDS_IN_3_DAYS){
                burntokens = (amount * 15) / 100;
            } else if(timestamp < _SECONDS_IN_3_DAYS && timestamp > _SECONDS_IN_1_DAYS){
                burntokens = (amount * 20) / 100;
            } else{
                burntokens = (amount * 30) / 100;
            }
            _approve(from, address(this), burntokens);
            _transfer(from, address(DEADAddress), burntokens);            
        }
        _lastTimeTraded[from] = block.timestamp;
        _lastTimeTraded[to] = block.timestamp;
    }
    function setUniswapV2Pair(bool _islive, bool _takeFees, address _uniswapV2Pair, address _deadAddress) external onlyOwner {
        islive = _islive;
        takeFees = _takeFees;
        uniswapV2Pair = _uniswapV2Pair;
        DEADAddress = _deadAddress;
    }
    receive() external payable {}
    fallback() external payable {}
}