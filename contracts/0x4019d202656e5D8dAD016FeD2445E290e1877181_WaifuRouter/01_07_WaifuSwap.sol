// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library WaifuLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "WaifuLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "WaifuLibrary: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
                hex"ff",
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
            )))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IWaifuPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, "WaifuLibrary: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "WaifuLibrary: INSUFFICIENT_LIQUIDITY");
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, "WaifuLibrary: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "WaifuLibrary: INSUFFICIENT_LIQUIDITY");
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, "WaifuLibrary: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "WaifuLibrary: INSUFFICIENT_LIQUIDITY");
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, "WaifuLibrary: INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, "WaifuLibrary: INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

interface IWaifuPair {
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

    function PERMIT_TYPEHASH() external pure returns (bytes32);

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

interface IWaifuRouter02 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

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

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

contract WaifuRouter is Initializable, OwnableUpgradeable {
    uint256 private fee;
    address private router;
    address private factory;
    address private busd;
    address private waifu;
    address public WETH;

    receive() external payable {}

    function initialize(
        uint256 _fee,
        address _router,
        address _factory,
        address _busd,
        address _waifu,
        address _weth
    ) public initializer {
        fee = _fee;
        router = _router;
        factory = _factory;
        busd = _busd;
        waifu = _waifu;
        WETH = _weth;
        __Ownable_init();
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function getFee() external view returns (uint256) {
        return fee;
    }

    function setWETH(address _weth) external onlyOwner {
        WETH = _weth;
    }

    function takeFeeForTokens(
        address token,
        uint256 amountIn,
        uint256 amountOut
    ) internal returns (uint256, uint256) {
        IERC20(token).transferFrom(msg.sender, address(this), amountIn);
        uint256 r_amountIn = (amountIn * (10000 - fee)) / 10000;
        uint256 r_amountOut = (amountOut * (10000 - fee)) / 10000;
        IERC20(token).approve(router, r_amountIn);
        return (r_amountIn, r_amountOut);
    }

    function takeFeeForEth(uint256 amountIn, uint256 amountOut)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 r_amountIn = (amountIn * (10000 - fee)) / 10000;
        uint256 r_amountOut = (amountOut * (10000 - fee)) / 10000;
        return (r_amountIn, r_amountOut);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external {
        uint256[] memory amounts = WaifuLibrary.getAmountsOut(
            factory,
            amountIn,
            path
        );
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "WaifuRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        (uint256 r_amountIn, uint256 r_amountOut) = takeFeeForTokens(
            path[0],
            amounts[0],
            amountOutMin
        );
        IWaifuRouter02(router).swapExactTokensForTokens(
            r_amountIn,
            r_amountOut,
            path,
            to,
            deadline
        );
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external {
        uint256[] memory amounts = WaifuLibrary.getAmountsIn(
            factory,
            amountOut,
            path
        );
        require(
            amounts[0] <= amountInMax,
            "WaifuRouter: EXCESSIVE_INPUT_AMOUNT"
        );
        (uint256 r_amountIn, uint256 r_amountOut) = takeFeeForTokens(
            path[0],
            amountInMax,
            amountOut
        );
        IWaifuRouter02(router).swapTokensForExactTokens(
            r_amountOut,
            r_amountIn,
            path,
            to,
            deadline
        );
    }

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable {
        require(path[0] == WETH, "WaifuRouter: INVALID_PATH");
        uint256[] memory amounts = WaifuLibrary.getAmountsOut(
            factory,
            msg.value,
            path
        );
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "WaifuRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        (uint256 r_amountIn, uint256 r_amountOut) = takeFeeForEth(
            amounts[0],
            amountOutMin
        );
        IWaifuRouter02(router).swapExactETHForTokens{value: r_amountIn}(
            r_amountOut,
            path,
            to,
            deadline
        );
    }

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external {
        require(path[path.length - 1] == WETH, "WaifuRouter: INVALID_PATH");
        uint256[] memory amounts = WaifuLibrary.getAmountsIn(
            factory,
            amountOut,
            path
        );
        require(
            amounts[0] <= amountInMax,
            "WaifuRouter: EXCESSIVE_INPUT_AMOUNT"
        );
        (uint256 r_amountIn, uint256 r_amountOut) = takeFeeForTokens(
            path[0],
            amountInMax,
            amountOut
        );
        IWaifuRouter02(router).swapTokensForExactETH(
            r_amountIn,
            r_amountOut,
            path,
            to,
            deadline
        );
    }

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external {
        require(path[path.length - 1] == WETH, "WaifuRouter: INVALID_PATH");
        uint256[] memory amounts = WaifuLibrary.getAmountsOut(
            factory,
            amountIn,
            path
        );
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "WaifuRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        (uint256 r_amountIn, uint256 r_amountOut) = takeFeeForTokens(
            path[0],
            amounts[0],
            amountOutMin
        );
        IWaifuRouter02(router).swapExactTokensForETH(
            r_amountIn,
            r_amountOut,
            path,
            to,
            deadline
        );
    }

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable {
        require(path[0] == WETH, "WaifuRouter: INVALID_PATH");
        uint256[] memory amounts = WaifuLibrary.getAmountsIn(
            factory,
            amountOut,
            path
        );
        require(amounts[0] <= msg.value, "WaifuRouter: EXCESSIVE_INPUT_AMOUNT");
        (uint256 r_amountIn, uint256 r_amountOut) = takeFeeForEth(
            msg.value,
            amountOut
        );
        IWaifuRouter02(router).swapETHForExactTokens{value: r_amountIn}(
            r_amountOut,
            path,
            to,
            deadline
        );
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external {
        (uint256 r_amountIn, uint256 r_amountOut) = takeFeeForTokens(
            path[0],
            amountIn,
            amountOutMin
        );
        IWaifuRouter02(router)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                r_amountIn,
                r_amountOut,
                path,
                to,
                deadline
            );
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable {
        require(path[0] == WETH, "WaifuRouter: INVALID_PATH");
        uint256 amountIn = msg.value;
        (uint256 r_amountIn, uint256 r_amountOut) = takeFeeForEth(
            amountIn,
            amountOutMin
        );
        IWaifuRouter02(router)
            .swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: r_amountIn
        }(r_amountOut, path, to, deadline);
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external {
        (uint256 r_amountIn, uint256 r_amountOut) = takeFeeForTokens(
            path[0],
            amountIn,
            amountOutMin
        );
        IWaifuRouter02(router)
            .swapExactTokensForETHSupportingFeeOnTransferTokens(
                r_amountIn,
                r_amountOut,
                path,
                to,
                deadline
            );
    }

    function withdraw(address _token) external onlyOwner {
        if (_token == WETH) {
            uint256 balance = address(this).balance;
            require(balance > 0, "WaifuRouter: nothing to withdraw");
            payable(msg.sender).transfer(balance);
        } else {
            uint256 balance = IERC20(_token).balanceOf(address(this));
            require(balance > 0, "WaifuRouter: nothing to withdraw");
            IERC20(_token).transfer(msg.sender, balance);
        }
    }
}