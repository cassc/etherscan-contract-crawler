// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ZYYToken is ERC20, ERC20Burnable, Ownable {
    struct TokenConfig {
        bool isFall;
        address holder;
        address a1;
        uint256 bouns;
    }
    TokenConfig public tokenConfig;
    mapping(address => bool) public DEXs;
    mapping(address => bool) public VIPs;

    IPancakeSwapV2Router02 public uniswapV2Router;
    address public uniswapUsdtV2Pair;
    address public usdtAddress = 0x55d398326f99059fF775485246999027B3197955;

    constructor(
        address _a,
        address _holder,
        address _pool,
        address _storage
    ) ERC20("ZYYToken", "ZYY") {
        _mint(_storage, 9950000000000 * 10**decimals());
        _mint(_pool, 50000000000 * 10**decimals());
        tokenConfig.a1 = _a;
        tokenConfig.holder = _holder;
        tokenConfig.isFall = false;
        tokenConfig.bouns = 0;
        IPancakeSwapV2Router02 _uniswapV2Router = IPancakeSwapV2Router02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );
        uniswapUsdtV2Pair = IPancakeSwapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), usdtAddress);
        uniswapV2Router = _uniswapV2Router;

        DEXs[uniswapUsdtV2Pair] = true;
        VIPs[address(this)] = true;
        VIPs[_a] = true;
        VIPs[_pool] = true;
    }

    function addDex(address _pair) external onlyOwner {
        if (DEXs[_pair]) {
            DEXs[_pair] = false;
        } else {
            DEXs[_pair] = true;
        }
    }

    function addVip(address _add) external onlyOwner {
        if (VIPs[_add]) {
            VIPs[_add] = false;
        } else {
            VIPs[_add] = true;
        }
    }

    function setIsFall() external onlyOwner returns (bool) {
        tokenConfig.isFall = !tokenConfig.isFall;
        return tokenConfig.isFall;
    }

    function transferCost(address from, uint256 amount) internal {
        uint256 _fee = amount / 100;
        _transfer(from, tokenConfig.a1, _fee);
        _transfer(from, address(this), _fee * 2);
        tokenConfig.bouns += _fee * 2;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        if (!VIPs[from] && DEXs[to]) {
            uint256 fromBalance = balanceOf(from);
            uint256 _fee = 3;
            if (tokenConfig.isFall) {
                _fee += 12;
            }
            uint256 _cost = (amount * _fee) / 100;
            uint256 _require = _cost + amount + (1 ether / 10);
            require(fromBalance >= _require, "invalid balance");
            if (_fee > 3) {
                _burn(from, (amount * 12) / 100);
            }
            transferCost(from, amount);
        }
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        if (DEXs[owner] && !VIPs[to]) {
            uint256 _deposit = (IERC20(address(this)).balanceOf(address(this)));
            if (_deposit > 0) {
                uint256 _amount = tokenConfig.bouns / 5;
                _transfer(address(this), to, _amount);
                tokenConfig.bouns -= _amount;
            }
            transferCost(owner, amount);
            uint256 _fee = 97;
            if (tokenConfig.isFall) {
                _fee -= 12;
                _burn(owner, (amount * 12) / 100);
            }
            _transfer(owner, to, (amount * _fee) / 100);
            return true;
        }
        _transfer(owner, to, amount);
        return true;
    }

    function queryTokenPrice() public view returns (uint256) {
        uint256 _a = ((IERC20(address(this)).balanceOf(uniswapUsdtV2Pair)) *
            1e18);
        uint256 _b = (IERC20(usdtAddress).balanceOf(uniswapUsdtV2Pair));
        if (_a > 0 && _b > 0) {
            return _a / _b;
        }
        return 0;
    }

    function invest(uint256 uAmount) external {
        IERC20(usdtAddress).transferFrom(msg.sender, address(this), uAmount);
        uint256 _tPrice = queryTokenPrice();
        uint256 _liquidityU = ((uAmount * 25) / 100);
        uint256 _fee = ((uAmount * 5) / 100);
        uint256 _buy = ((uAmount * 70) / 100);
        uint256 amountOutMin = 0;
        if (tokenConfig.isFall) {
            amountOutMin = ((_buy * _tPrice * 84) / 100) / 1 ether;
        } else {
            amountOutMin = ((_buy * _tPrice * 96) / 100) / 1 ether;
        }
        IERC20(usdtAddress).approve(
            address(uniswapV2Router),
            _liquidityU + _buy
        );

        address[] memory _path = new address[](2);
        _path[0] = usdtAddress;
        _path[1] = address(this);
        uint256[] memory buy_amounts = uniswapV2Router.swapExactTokensForTokens(
            _buy,
            amountOutMin,
            _path,
            msg.sender,
            (block.timestamp + 5 minutes)
        );
        uint256 realGetAmount;
        if (tokenConfig.isFall) {
            realGetAmount = (buy_amounts[buy_amounts.length - 1] * 85) / 100;
        } else {
            realGetAmount = (buy_amounts[buy_amounts.length - 1] * 97) / 100;
        }
        transfer(address(this), realGetAmount);
        _tPrice = queryTokenPrice();
        uint256 _realLiqudityToken = (_liquidityU * _tPrice) / 1 ether;
        uint256 _burnLiqudity = realGetAmount - _realLiqudityToken;

        uint256 amountAMin = 0;
        uint256 amountBMin = 0;
        if (tokenConfig.isFall) {
            amountAMin = (_liquidityU * 84) / 100;
            amountBMin = (_realLiqudityToken * 84) / 100;
        } else {
            amountAMin = (_liquidityU * 96) / 100;
            amountBMin = (_realLiqudityToken * 96) / 100;
        }
        _approve(address(this), address(uniswapV2Router), _realLiqudityToken);

        uniswapV2Router.addLiquidity(
            usdtAddress,
            address(this),
            _liquidityU,
            _realLiqudityToken,
            amountAMin,
            amountBMin,
            address(0),
            (block.timestamp + 5 minutes)
        );
        _burn(address(this), _burnLiqudity);
        IERC20(usdtAddress).transfer(tokenConfig.holder, _fee);
    }
}

interface IPancakeSwapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IPancakeSwapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (address);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IPancakeSwapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IPancakeSwapV2Router02 is IPancakeSwapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}