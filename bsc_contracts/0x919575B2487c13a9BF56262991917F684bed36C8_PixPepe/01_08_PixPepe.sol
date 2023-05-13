// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

// File: contracts\interfaces\IPancakeRouter01.sol

pragma solidity >=0.6.2;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,

        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: contracts\interfaces\IPancakeRouter02.sol

pragma solidity >=0.6.2;

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IAutoBoost {
    function injectBoostPool(uint256 amount, bool from) external;
    function buyback() external;
}

pragma solidity ^0.8.17;
contract PixPepe is ERC20, ERC20Burnable, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    // To be fair, fees are fixed
    uint256 public _devFee = 300;
    uint256 public _burnFee = 300;
    uint256 public _buybackFee = 400;
    uint256 public _totalFee = 1000;
    uint256 public _feeDenominator = 10000;
    
    EnumerableSet.AddressSet private _pairs;

    IAutoBoost private _autoBoostWallet;
    address public constant _DEAD = 0x000000000000000000000000000000000000dEaD;

    bool public inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }  

    constructor() ERC20("PixPepe", "PPEPE") {
        uint256 _totalSupply = 420_000_000_000_000*1e18;
        _mint(_msgSender(), _totalSupply);
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        transfer_(owner, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        transfer_(from, to, amount);

        return true;
    }

    function transfer_(address from, address to, uint256 amount) internal returns (bool) {
        if (inSwap) {
            _transfer(from, to, amount);
            return true;
        }

        uint256 amountReceived = amount;
        if (isPair(from) || isPair(to)) {
            amountReceived = amount - takeFees(from, amount);
        }

        if (!isPair(from)) {
            inSwap = true;
            _autoBoostWallet.buyback();
            inSwap = false;
        }

        _transfer(from, to, amountReceived);

        return true;
    }

    function takeFees(address from, uint256 amount) internal swapping returns (uint256) {
        uint256 totalFees = (amount * _totalFee) / _feeDenominator;
        _transfer(from, address(this), totalFees);

        uint256 burnFees = (totalFees * _burnFee) / _feeDenominator;
        uint256 devAndBackFees = totalFees - burnFees;
        
        _transfer(address(this), _DEAD, burnFees);
        _autoBoostWallet.injectBoostPool(devAndBackFees, isPair(from));

        return totalFees;
    }

    function autoBoostInfo() external view returns (address) {
        return address(_autoBoostWallet);
    }

    // To be fair, it can only be set once
    function setAutoBoost(address account) external {
        require(address(_autoBoostWallet)==address(0), "Error: cant set again");

        _approve(address(this), account, type(uint256).max);
        _autoBoostWallet = IAutoBoost(account);
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return totalSupply() - balanceOf(_DEAD) - balanceOf(address(0));
    }

    function getBurnedAmount() public view returns (uint256) {
        return balanceOf(_DEAD) - balanceOf(address(0));
    }

    function isPair(address account) public view returns (bool) {
        return _pairs.contains(account);
    }

    function addPair(address pair) public onlyOwner returns (bool) {
        require(pair != address(0), "Error: pair is the zero address");
        return _pairs.add(pair);
    }

    function delPair(address pair) public onlyOwner returns (bool) {
        require(pair != address(0), "Error: pair is the zero address");
        return _pairs.remove(pair);
    }

    function getPairLength() public view returns (uint256) {
        return _pairs.length();
    }

    function getPair(uint256 index) public view returns (address) {
        require(index <= _pairs.length() - 1, "Error: index out of length");
        return _pairs.at(index);
    }

    fallback() external {}
}