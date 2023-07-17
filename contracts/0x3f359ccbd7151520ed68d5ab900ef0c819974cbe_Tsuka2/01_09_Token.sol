// SPDX-License-Identifier: MIT
// Tsuka 2.0 - https://twitter.com/TSUKA2erc - https://t.me/tsuka2erc
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Tsuka2 is IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public excludedFromFees;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    bool private _inSwap;
    uint256 public constant TAX_FEE = 3;
    uint256 public immutable maxHoldingAmount;
    uint256 public immutable taxSwapMinThreshold;
    uint256 public immutable taxSwapMaxThreshold;

    address private constant _TAX_ADDRESS =
        0xe53a672751EC2ac8C1A932F25fa238e1E0c34339;
    address private constant _FACTORY_ADDRESS =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private constant _ROUTER_ADDRESS =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address private immutable _POOL_ADDRESS;
    IUniswapV2Factory private immutable _FACTORY;
    IUniswapV2Router02 private immutable _ROUTER;

    constructor() {
        _name = "Tsuka 2.0";
        _symbol = "TSUKA2.0";
        _FACTORY = IUniswapV2Factory(_FACTORY_ADDRESS);
        _ROUTER = IUniswapV2Router02(_ROUTER_ADDRESS);
        _POOL_ADDRESS = _FACTORY.createPair(address(this), _ROUTER.WETH());

        excludedFromFees[_msgSender()] = true;
        excludedFromFees[address(this)] = true;
        excludedFromFees[_TAX_ADDRESS] = true;

        uint256 tokenSupply = 1_000_000_000 * 10 ** decimals();
        maxHoldingAmount = (tokenSupply / 50);
        taxSwapMinThreshold = (tokenSupply / 1000);
        taxSwapMaxThreshold = taxSwapMinThreshold * 2;
        _mint(_msgSender(), tokenSupply);
        renounceOwnership();
    }

    modifier swapLock() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 taxAmount;

        if (_inSwap) return _swapTransfer(from, to, amount);
        if (
            (from == _POOL_ADDRESS || to == _POOL_ADDRESS) &&
            !excludedFromFees[to] &&
            !excludedFromFees[from] &&
            !excludedFromFees[tx.origin]
        ) {
            taxAmount = (amount * TAX_FEE) / 100;
            if (from == _POOL_ADDRESS)
                require(
                    balanceOf(to) + amount - taxAmount <= maxHoldingAmount,
                    "Transaction not within limits."
                );
        }
        if (to == _POOL_ADDRESS) _swapTaxes();

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount - taxAmount;
            _balances[address(this)] += taxAmount;
        }

        emit Transfer(from, to, amount - taxAmount);
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

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _swapTransfer(address from, address to, uint256 amount) internal {
        unchecked {
            _balances[from] -= amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    function _swapTaxes() internal swapLock {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance < taxSwapMinThreshold) return;

        uint256 swapAmount = contractBalance > taxSwapMaxThreshold
            ? taxSwapMaxThreshold
            : contractBalance;

        _approve(address(this), _ROUTER_ADDRESS, swapAmount);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _ROUTER.WETH();

        _ROUTER.swapExactTokensForETH(
            swapAmount,
            0,
            path,
            _TAX_ADDRESS,
            block.timestamp
        );
    }
}