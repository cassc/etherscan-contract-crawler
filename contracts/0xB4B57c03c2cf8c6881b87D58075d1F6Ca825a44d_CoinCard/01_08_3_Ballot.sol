// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

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

contract CoinCard is Ownable{

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    // DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F
    // WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    // Goerli Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D

    address public withdrawer;
    address public mainToken = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; //USDC
    IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public feeAddress = 0xD2554B974389503C573BB0cAc9f5083f285a5A0f;
    uint256 public feeDominate = 10000;
    uint256 public minGasFee = 0.01 ether;

    mapping(address => bool) public tokenAllowed;
    mapping(address => address[]) public swapPath;
    modifier onlyWithdrawer() {
        require(withdrawer == msg.sender, "caller is not the withdrawer");
        _;
    }

    event Deposit(address indexed user, address indexed token, uint256 amount, uint256 mainTokenAmount);
    event Withdraw(address indexed receiver, address indexed token, uint256 amount, uint256 mainTokenAmount);
    event FeePaid(address indexed depositTo, uint256 depositFeeAmount, address indexed withdrawTo, uint256 withdrawFeeAmount);

    constructor() {
        withdrawer = msg.sender;
    }

    function addTokens(address[] memory _tokens, bool _value, address[][] memory _paths) external onlyOwner() {
        for(uint256 i = 0; i < _tokens.length; i++) {
            tokenAllowed[_tokens[i]] = _value;
            swapPath[_tokens[i]] = _paths[i];
        }
    }

    function setToken(address _token, bool _value, address[] memory _path) external onlyOwner() {
        tokenAllowed[_token] = _value;
        swapPath[_token] = _path;
    }

    function setRouter(address _router) external onlyOwner{
        require(address(uniswapV2Router) != _router, "already set same address");
        uniswapV2Router = IUniswapV2Router02(_router);
    }

    function setMainToken(address _token) external onlyOwner{
        require(mainToken != _token, "already set same address");
        mainToken = _token;
    }

    function updateFee(address _feeAddr, uint256 _feeDominate, uint256 _minGasFee) external onlyOwner{
        feeAddress = _feeAddr;
        feeDominate = _feeDominate;
        minGasFee = _minGasFee;
    }

    function updateWithdrawer(address _withdrawer) external onlyOwner{
        require(withdrawer != _withdrawer, "already set same address");
        withdrawer = _withdrawer;
    }

    function depositETH(uint256 _dipositFee, uint256 _withdrawFee) external payable returns(uint256){

        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = mainToken;

        require(_withdrawFee >= minGasFee, 'not enough fee');
        payable(withdrawer).transfer(_withdrawFee);
        uint256 swapAmount = msg.value - _withdrawFee;
        // make the swap
        uint256[] memory amounts = uniswapV2Router.swapExactETHForTokens{value: swapAmount}(
            0,
            path,
            address(this),
            block.timestamp.add(300)
        );

        uint256 swappedAmount = amounts[amounts.length-1];
        require(swappedAmount > feeDominate, "too small amount");

        uint256 feeAmount = swappedAmount.mul(_dipositFee).div(feeDominate);
        IERC20(mainToken).transfer(feeAddress, feeAmount);
        emit FeePaid(feeAddress, feeAmount, withdrawer, _withdrawFee);

        uint256 userAmount = swappedAmount.sub(feeAmount);
        emit Deposit(msg.sender, address(0), msg.value, userAmount);
        return userAmount;
    }

    function deposit(address _token, uint256 _amount, uint256 _dipositFee, uint256 _withdrawAmount) external returns(uint256){
        require(tokenAllowed[_token], "not allowed token");

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        uint256 swappedAmount;
        if(_token == mainToken) {
            swappedAmount = _amount;
        }
        else {
            IERC20(_token).approve(address(uniswapV2Router), _amount);
            uint256 beforeBalance = IERC20(mainToken).balanceOf(address(this));
            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _amount,
                0,
                swapPath[_token],
                address(this),
                block.timestamp
            );
            uint256 afterBalance = IERC20(mainToken).balanceOf(address(this));
            swappedAmount = afterBalance.sub(beforeBalance);
        }

        require(swappedAmount > feeDominate, "too small amount");
        uint256 feeAmount = swappedAmount.mul(_dipositFee).div(feeDominate);
        IERC20(mainToken).transfer(feeAddress, feeAmount);

        require(_withdrawAmount < swappedAmount.sub(feeAmount), 'invalid deposited amount');
        address[] memory path = new address[](2);
        path[0] = mainToken;
        path[1] = uniswapV2Router.WETH();

        IERC20(mainToken).approve(address(uniswapV2Router), _withdrawAmount);
        
        uint256[] memory amounts = uniswapV2Router.swapExactTokensForETH(
            _withdrawAmount,
            0,
            path,
            withdrawer,
            block.timestamp.add(300)
        );
        emit FeePaid(feeAddress, feeAmount, withdrawer, amounts[1]);

        uint256 userAmount = swappedAmount.sub(feeAmount);
        emit Deposit(msg.sender, _token, _amount, userAmount);
        return userAmount;
    }

    function withdrawETH(uint256 _amount, address _receiver) external onlyWithdrawer returns(uint256){
        require(_amount <= IERC20(mainToken).balanceOf(address(this)), "insufficient balance");
        address[] memory path = new address[](2);
        path[0] = mainToken;
        path[1] = uniswapV2Router.WETH();

        IERC20(mainToken).approve(address(uniswapV2Router), _amount);
        // make the swap
        uint256[] memory amounts = uniswapV2Router.swapExactTokensForETH(
            _amount,
            0,
            path,
            _receiver,
            block.timestamp.add(300)
        );

        uint256 swappedAmount = amounts[amounts.length-1];
        emit Withdraw(_receiver, address(0), swappedAmount, _amount);
        return swappedAmount;
    }

    function withdraw(address _token, uint256 _amount, address _receiver) external onlyWithdrawer returns(uint256){
        require(tokenAllowed[_token], "not allowed token");
        require(_amount <= IERC20(mainToken).balanceOf(address(this)), "insufficient balance");
        
        uint256 swappedAmount;
        if(_token == mainToken) {
            swappedAmount = _amount;
        } else {
            address[] memory reversedPath = new address[](swapPath[_token].length);
            uint256 j = 0;
            for(uint256 i = swapPath[_token].length; i >= 1; i--){
                reversedPath[j] = swapPath[_token][i-1];
                j++;
            }
            uint256 beforeBalance = IERC20(_token).balanceOf(address(this));
            IERC20(mainToken).approve(address(uniswapV2Router), _amount);
            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _amount,
                0,
                reversedPath,
                address(this),
                block.timestamp
            );
            uint256 afterBalance = IERC20(_token).balanceOf(address(this));
            swappedAmount = afterBalance.sub(beforeBalance);
        }
        
        IERC20(_token).transfer(_receiver, swappedAmount);

        emit Withdraw(_receiver, _token, swappedAmount, _amount);
        return swappedAmount;
    }

    function estimateInAmount(address _token, uint256 _amount) public view returns (uint256) {
        address[] memory path = swapPath[_token];
        uint256[] memory amounts = uniswapV2Router.getAmountsIn(_amount, path);
        return amounts[0];
    }

    function estimateOutAmout(address _token, uint256 _amount) public view returns (uint256) {
        address[] memory reversedPath = new address[](swapPath[_token].length);
        uint256 j = 0;
        for(uint256 i = swapPath[_token].length; i >= 1; i--){
            reversedPath[j] = swapPath[_token][i-1];
            j++;
        }
        uint256[] memory amounts = uniswapV2Router.getAmountsOut(_amount, reversedPath);
        return amounts[reversedPath.length -1];
    }
}