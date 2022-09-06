// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IUniswap {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function WETH() external pure returns (address);

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IPancakeFactory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract VoltSwap is Ownable {
    address private constant UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant UNISWAP_FACTORY =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant VOLT = 0x7db5af2B9624e1b3B4Bb69D6DeBd9aD1016A58Ac;

    address internal deadAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public fee = 50;

    event GetApproval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event Transfer(address sender, address recipient, uint256 amount);
    event Burned(
        address tokenIn,
        address sender,
        address recipient,
        uint256 amount
    );
    event Swap(
        uint256 totalAmount,
        uint256 amountOutMin,
        address[] path,
        address to,
        uint256 deadline
    );

    function swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOutMin,
        uint256 _amountIn,
        uint256 _slippage,
        address _to
    ) public {
        IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);

        uint256 feeAmount = (_amountIn * fee) / 10000;
        uint256 slippageAmount = (_amountIn * _slippage) / 1000;

        feeAmount += slippageAmount;
        uint256 _totalAmount = (_amountIn - feeAmount);

        IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn);
        emit GetApproval(msg.sender, UNISWAP_V2_ROUTER, _amountIn);

        address[] memory path;

        if (_tokenIn == WETH || _tokenOut == WETH) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH;
            path[2] = _tokenOut;
        }

        IUniswap(UNISWAP_V2_ROUTER)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _totalAmount,
                _amountOutMin,
                path,
                _to,
                block.timestamp + 150
            );

        address[] memory _voltPath;

        if (_tokenIn == WETH) {
            _voltPath = new address[](2);
            _voltPath[0] = _tokenIn;
            _voltPath[1] = VOLT;
        } else {
            _voltPath = new address[](3);
            _voltPath[0] = _tokenIn;
            _voltPath[1] = WETH;
            _voltPath[2] = VOLT;
        }

        uint256 feeHalfAmount = feeAmount / 2;

        IUniswap(UNISWAP_V2_ROUTER)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                feeHalfAmount,
                0,
                _voltPath,
                address(this),
                block.timestamp
            );

        emit Swap(feeHalfAmount, 0, _voltPath, address(this), block.timestamp);

        address[] memory _tokenOutpath;

        if (_tokenIn == WETH) {
            _tokenOutpath = new address[](2);
            _tokenOutpath[0] = _tokenIn;
            _tokenOutpath[1] = _tokenOut;
        } else {
            _tokenOutpath = new address[](3);
            _tokenOutpath[0] = _tokenIn;
            _tokenOutpath[1] = WETH;
            _tokenOutpath[2] = _tokenOut;
        }

        IUniswap(UNISWAP_V2_ROUTER)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                feeHalfAmount,
                0,
                _tokenOutpath,
                address(this),
                block.timestamp
            );

        emit Swap(
            feeHalfAmount,
            0,
            _tokenOutpath,
            address(this),
            block.timestamp
        );

        IERC20(VOLT).approve(address(this), feeHalfAmount);
        emit GetApproval(VOLT, address(this), feeHalfAmount);

        IERC20(VOLT).transferFrom(address(this), deadAddress, feeHalfAmount);
        emit Burned(VOLT, address(this), deadAddress, feeHalfAmount);

        IERC20(_tokenOut).approve(address(this), feeHalfAmount);
        emit GetApproval(_tokenOut, address(this), feeHalfAmount);

        IERC20(_tokenOut).transferFrom(address(this), deadAddress, feeHalfAmount);
        emit Burned(_tokenOut, address(this), deadAddress, feeHalfAmount);
    }

    function getPair(address _tokenIn, address _tokenOut)
        external
        view
        returns (address)
    {
        return IPancakeFactory(UNISWAP_FACTORY).getPair(_tokenIn, _tokenOut);
    }

    function getAmountOutMin(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) external view returns (uint256) {
        address[] memory path;
        if (_tokenIn == WETH || _tokenOut == WETH) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH;
            path[2] = _tokenOut;
        }

        uint256[] memory amountOutMins = IUniswap(UNISWAP_V2_ROUTER)
            .getAmountsOut(_amountIn, path);
        return amountOutMins[path.length - 1];
    }
}