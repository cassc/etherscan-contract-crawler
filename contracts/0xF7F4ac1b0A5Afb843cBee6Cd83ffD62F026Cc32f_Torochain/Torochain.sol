/**
 *Submitted for verification at Etherscan.io on 2023-05-07
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface Router {
    function WETH() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

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
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0));
        _transferOwnership(newOwner);
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender());
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Torochain is Context, IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _whitelisted;
    uint256 private _supply = 1000000000 * 1e6;
    uint256 private _reserve = 1000000 * 1e6;
    uint8 private _decimals = 6;
    uint8 private _fee = 16;
    string private _name = "Torochain";
    string private _symbol = "TORO";
    address private _router;
    address private _pair;
    address private _treasury;
    address private _manager;
    bool private _liquify = true;
    bool private _swapping = false;

    modifier swapping() {
        _swapping = true;
        _;
        _swapping = false;
    }

    modifier managing() {
        require(_msgSender() == _manager);
        _;
    }

    constructor() {
        _treasury = msg.sender;
        _manager = msg.sender;
        _whitelisted[address(this)] = true;
        _whitelisted[msg.sender] = true;
        _balances[msg.sender] = _supply;
        emit Transfer(address(0), msg.sender, _supply);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _supply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
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
        require(currentAllowance >= subtractedValue);
        _approve(owner, spender, currentAllowance - subtractedValue);
        return true;
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        _handle(_msgSender(), to, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(sender, spender, amount);
        _handle(sender, recipient, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0) && to != address(0));
        require(_balances[from] >= amount);
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0) && spender != address(0));
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount);
            _approve(owner, spender, currentAllowance - amount);
        }
    }

    function _handle(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (_swapping || _msgSender() == _pair || _whitelisted[sender] || _whitelisted[recipient] || _fee == 0) {
            _transfer(sender, recipient, amount);
            return true;
        }

        if (_liquify && balanceOf(address(this)) > _reserve) _swap();
        uint256 fee = amount * _fee / 100;
        _transfer(sender, address(this), fee);
        _transfer(sender, recipient, amount - fee);
        return true;
    }

    function _swap() internal swapping {
        uint256 eth = address(this).balance;
        uint256 tokens = balanceOf(address(this)) / 4;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(Router(_router).WETH());
        Router(_router).swapExactTokensForETHSupportingFeeOnTransferTokens(tokens, 0, path, address(this), block.timestamp);

        uint256 ethAmount = address(this).balance - eth;
        Router(_router).addLiquidityETH{value: ethAmount}(address(this), tokens, 0, 0, _treasury, block.timestamp);
    
        Router(_router).swapExactTokensForETHSupportingFeeOnTransferTokens(balanceOf(address(this)), 0, path, address(this), block.timestamp);
        (bool success,) = payable(_treasury).call{value: address(this).balance}("");
        require(success);
    }

    function setRouter(address value) external managing {
        _router = value;
        _approve(address(this), _router, type(uint256).max);
    }

    function setPair(address value) external managing {
        _pair = value;
    }

    function setFee(uint8 value) external managing {
        require(value <= 16);
        _fee = value;
    }

    function setWhitelisted(address account) external managing {
        _whitelisted[account] = true;
    }

    function setReserve(uint256 value) external managing {
        _reserve = value;
    }

    function setManager(address account) external managing {
        _manager = account;
    }

    function setTreasury(address value) external managing {
        _treasury = value;
    }

    function setLiquify(bool value) external managing {
        _liquify = value;
    }

    function getEth(uint256 amount) external managing {
        (bool success,) = payable(_msgSender()).call{value: amount}("");
        require(success);
    }

    function getToken(IERC20 token, uint256 amount) external managing {
        token.transfer(_msgSender(), amount);
    }

    receive() external payable {}
}