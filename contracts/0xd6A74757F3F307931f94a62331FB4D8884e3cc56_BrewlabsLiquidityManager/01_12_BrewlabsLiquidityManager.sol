// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./libs/IUniFactory.sol";
import "./libs/IUniRouter02.sol";
import "./libs/IWETH.sol";

contract BrewlabsLiquidityManager is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public uniRouterAddress;

    uint256 public fee = 100; // 1%
    address public treasury = 0xE1f1dd010BBC2860F81c8F90Ea4E38dB949BB16F;
    address public walletA = 0xE1f1dd010BBC2860F81c8F90Ea4E38dB949BB16F;

    address public wethAddress;
    address[] public wethToBrewsPath;
    uint256 public slippageFactor = 9500; // 5% default slippage tolerance
    uint256 public constant slippageFactorUL = 8000;
    
    bool public buyBackBurn = false;
    uint256 public buyBackLimit = 1 ether;
    address public constant buyBackAddress = 0xE1f1dd010BBC2860F81c8F90Ea4E38dB949BB16F;
    
    event WalletAUpdated(address _addr);
    event FeeUpdated(uint256 _fee);
    event BuyBackStatusChanged(bool _status);
    event BuyBackLimitUpdated(uint256 _limit);
    event AdminTokenRecovered(address tokenRecovered, uint256 amount);

    constructor() {}

    function initialize(
        address _uniRouterAddress,
        address[] memory _wethToBrewsPath
    ) external onlyOwner {
        require(_uniRouterAddress != address(0x0), "Invalid address");
        
        uniRouterAddress = _uniRouterAddress;
        wethToBrewsPath = _wethToBrewsPath;

        wethAddress = IUniRouter02(uniRouterAddress).WETH();
    }

    function addLiquidity(address token0, address token1, uint256 _amount0, uint256 _amount1, uint256 _slipPage) external payable nonReentrant returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        require(_amount0 > 0 && _amount1 > 0, "amount is zero");
        require(_slipPage < 10000, "slippage cannot exceed 100%");
        require(token0 != token1, "cannot use same token for pair");

        uint256 beforeAmt = IERC20(token0).balanceOf(address(this));
        IERC20(token0).transferFrom(msg.sender, address(this), _amount0);
        uint256 token0Amt = IERC20(token0).balanceOf(address(this)).sub(beforeAmt);
        token0Amt = token0Amt.mul(10000 - fee).div(10000);

        beforeAmt = IERC20(token1).balanceOf(address(this));
        IERC20(token1).transferFrom(msg.sender, address(this), _amount1);
        uint256 token1Amt = IERC20(token1).balanceOf(address(this)).sub(beforeAmt);
        token1Amt = token1Amt.mul(10000 - fee).div(10000);
        
        (amountA, amountB, liquidity) = _addLiquidity( token0, token1, token0Amt, token1Amt, _slipPage);

        token0Amt = IERC20(token0).balanceOf(address(this));
        token1Amt = IERC20(token1).balanceOf(address(this));
        IERC20(token0).transfer(walletA, token0Amt);
        IERC20(token1).transfer(walletA, token1Amt);
    }

    function _addLiquidity(address token0, address token1, uint256 _amount0, uint256 _amount1, uint256 _slipPage) internal returns (uint256, uint256, uint256) {
        IERC20(token0).safeIncreaseAllowance(uniRouterAddress, _amount0);
        IERC20(token1).safeIncreaseAllowance(uniRouterAddress, _amount1);

        return IUniRouter02(uniRouterAddress).addLiquidity(
                token0,
                token1,
                _amount0,
                _amount1,
                _amount0.mul(10000 - _slipPage).div(10000),
                _amount1.mul(10000 - _slipPage).div(10000),
                msg.sender,
                block.timestamp.add(600)
            );
    }

    function addLiquidityETH(address token, uint256 _amount, uint256 _slipPage) external payable nonReentrant returns (uint256 amountToken, uint256 amountETH, uint256 liquidity) {
        require(_amount > 0, "amount is zero");
        require(_slipPage < 10000, "slippage cannot exceed 100%");
        require(msg.value > 0, "amount is zero");

        uint256 beforeAmt = IERC20(token).balanceOf(address(this));
        IERC20(token).transferFrom(msg.sender, address(this), _amount);
        uint256 tokenAmt = IERC20(token).balanceOf(address(this)).sub(beforeAmt);
        tokenAmt = tokenAmt.mul(10000 - fee).div(10000);

        uint256 ethAmt = msg.value;
        ethAmt = ethAmt.mul(10000 - fee).div(10000);
    
        IERC20(token).safeIncreaseAllowance(uniRouterAddress, tokenAmt);        
        (amountToken, amountETH, liquidity) = _addLiquidityETH(token, tokenAmt, ethAmt, _slipPage);

        tokenAmt = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(walletA, tokenAmt);

        if(buyBackBurn) {
            buyBack();
        } else {
            ethAmt = address(this).balance;
            payable(treasury).transfer(ethAmt);
        }
    }

    function _addLiquidityETH(address token, uint256 _amount, uint256 _ethAmt, uint256 _slipPage) internal returns (uint256, uint256, uint256) {
        IERC20(token).safeIncreaseAllowance(uniRouterAddress, _amount);        
        
        return IUniRouter02(uniRouterAddress).addLiquidityETH{value: _ethAmt}(
            token,
            _amount,
            _amount.mul(10000 - _slipPage).div(10000),
            _ethAmt.mul(10000 - _slipPage).div(10000),
            msg.sender,
            block.timestamp.add(600)
        );
    }

    function removeLiquidity(address token0, address token1, uint256 _amount) external nonReentrant returns (uint256 amountA, uint256 amountB){
        require(_amount > 0, "amount is zero");
        
        address pair = getPair(token0, token1);
        IERC20(pair).transferFrom(msg.sender, address(this), _amount);
        IERC20(pair).safeIncreaseAllowance(uniRouterAddress, _amount);

        uint256 beforeAmt0 = IERC20(token0).balanceOf(address(this));
        uint256 beforeAmt1 = IERC20(token1).balanceOf(address(this));                
        IUniRouter02(uniRouterAddress).removeLiquidity(
            token0,
            token1,
            _amount,
            0,
            0,
            address(this),
            block.timestamp.add(600)
        );
        uint256 afterAmt0 = IERC20(token0).balanceOf(address(this));
        uint256 afterAmt1 = IERC20(token1).balanceOf(address(this));

        amountA = afterAmt0.sub(beforeAmt0);
        amountB = afterAmt1.sub(beforeAmt1);
        IERC20(token0).safeTransfer(msg.sender, amountA.mul(10000 - fee).div(10000));
        IERC20(token1).safeTransfer(msg.sender, amountB.mul(10000 - fee).div(10000));

        IERC20(token0).transfer(walletA, amountA.mul(fee).div(10000));
        IERC20(token1).transfer(walletA, amountB.mul(fee).div(10000));

        amountA = amountA.mul(10000 - fee).div(10000);
        amountB = amountB.mul(10000 - fee).div(10000);
    }

    function removeLiquidityETH(address token, uint256 _amount) external nonReentrant returns (uint256 amountToken, uint256 amountETH){
        require(_amount > 0, "amount is zero");
        
        address pair = getPair(token, wethAddress);
        IERC20(pair).transferFrom(msg.sender, address(this), _amount);
        IERC20(pair).safeIncreaseAllowance(uniRouterAddress, _amount);
        
        uint256 beforeAmt0 = IERC20(token).balanceOf(address(this));
        uint256 beforeAmt1 = address(this).balance;        
        IUniRouter02(uniRouterAddress).removeLiquidityETH(
            token,
            _amount,
            0,
            0,
            address(this),                
            block.timestamp.add(600)
        );
        uint256 afterAmt0 = IERC20(token).balanceOf(address(this));
        uint256 afterAmt1 = address(this).balance;
        
        amountToken = afterAmt0.sub(beforeAmt0);
        amountETH = afterAmt1.sub(beforeAmt1);
        IERC20(token).safeTransfer(msg.sender, amountToken.mul(10000 - fee).div(10000));
        payable(msg.sender).transfer(amountETH.mul(10000 - fee).div(10000));

        IERC20(token).transfer(walletA, amountToken.mul(fee).div(10000));
        payable(treasury).transfer(amountETH.mul(fee).div(10000));

        amountToken = amountToken.mul(10000 - fee).div(10000);
        amountETH = amountETH.mul(10000 - fee).div(10000);
    }

    function removeLiquidityETHSupportingFeeOnTransferTokens(address token, uint256 _amount) external nonReentrant returns (uint256 amountETH){
        require(_amount > 0, "amount is zero");
        
        address pair = getPair(token, wethAddress);
        IERC20(pair).transferFrom(msg.sender, address(this), _amount);
        IERC20(pair).safeIncreaseAllowance(uniRouterAddress, _amount);

        uint256 beforeAmt0 = IERC20(token).balanceOf(address(this));
        uint256 beforeAmt1 = address(this).balance;
        IUniRouter02(uniRouterAddress).removeLiquidityETHSupportingFeeOnTransferTokens(
            token,
            _amount,
            0,
            0,
            address(this),
            block.timestamp.add(600)
        );
        uint256 afterAmt0 = IERC20(token).balanceOf(address(this));
        uint256 afterAmt1 = address(this).balance;
        
        uint256 amountToken = afterAmt0.sub(beforeAmt0);
        amountETH = afterAmt1.sub(beforeAmt1);
        IERC20(token).safeTransfer(msg.sender, amountToken.mul(10000 - fee).div(10000));
        payable(msg.sender).transfer(amountETH.mul(10000 - fee).div(10000));

        IERC20(token).transfer(walletA, amountToken.mul(fee).div(10000));
        payable(treasury).transfer(amountETH.mul(fee).div(10000));

        amountToken = amountToken.mul(10000 - fee).div(10000);
        amountETH = amountETH.mul(10000 - fee).div(10000);
    }
   
    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        if(_tokenAddress == address(0x0)) {
            payable(msg.sender).transfer(_tokenAmount);
        } else {
            IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);
        }

        emit AdminTokenRecovered(_tokenAddress, _tokenAmount);
    }

    function updateWalletA(address _walletA) external onlyOwner {
        require(_walletA != address(0x0) || _walletA != walletA, "Invalid address");

        walletA = _walletA;
        emit WalletAUpdated(_walletA);
    }

    function updateFee(uint256 _fee) external onlyOwner {
        require(_fee < 2000, "fee cannot exceed 20%");

        fee = _fee;
        emit FeeUpdated(_fee);
    }

    function setBuyBackStatus(bool _status) external onlyOwner {
        buyBackBurn = _status;

        uint256 ethAmt = address(this).balance;
        if(ethAmt > 0 && _status == false) {
            payable(walletA).transfer(ethAmt);
        }

        emit BuyBackStatusChanged(_status);
    }

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0x0), "Invalid address");
        treasury = _treasury;
    }

    function updateBuyBackLimit(uint256 _limit) external onlyOwner {
        require(_limit > 0, "Invalid amount");

        buyBackLimit = _limit;
        emit BuyBackLimitUpdated(_limit);
    }

    function buyBack() internal {
        uint256 wethAmt = address(this).balance;

        if(wethAmt > buyBackLimit) {
             _safeSwapWeth(
                wethAmt,
                wethToBrewsPath,
                buyBackAddress
            );
        }
    }

    function _safeSwapWeth(
        uint256 _amountIn,
        address[] memory _path,
        address _to
    ) internal {
        uint256[] memory amounts = IUniRouter02(uniRouterAddress).getAmountsOut(_amountIn, _path);
        uint256 amountOut = amounts[amounts.length.sub(1)];

        IUniRouter02(uniRouterAddress).swapExactETHForTokens{value: _amountIn}(
            amountOut.mul(slippageFactor).div(10000),
            _path,
            _to,
            block.timestamp.add(600)
        );
    }

    function getPair(address token0, address token1) public view returns (address) {
        address factory = IUniRouter02(uniRouterAddress).factory();
        return IUniV2Factory(factory).getPair(token0, token1);
    }

    receive() external payable {}
}