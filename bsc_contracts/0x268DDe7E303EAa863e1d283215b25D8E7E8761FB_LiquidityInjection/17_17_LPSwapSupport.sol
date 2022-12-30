// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
There are far too many uses for the LP swapping pool.
Rather than rewrite them, this contract performs them for us and uses both generic and specific calls.
-The Dev
*/
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract LPSwapSupport is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    event UpdateRouter(address indexed newAddress, address indexed oldAddress);
    event UpdateLPReceiver(address indexed newAddress, address indexed oldAddress);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    bool internal inSwap;

    IUniswapV2Router02 public swapRouter;
    address public liquidityReceiver;

    function __LPSwapSupport_init(address lpReceiver) internal onlyInitializing {
        __Ownable_init();
        __LPSwapSupport_init_unchained(lpReceiver);
    }

    function __LPSwapSupport_init_unchained(address lpReceiver) internal onlyInitializing {
        liquidityReceiver = lpReceiver;
    }

    function _approve(address holder, address spender, uint256 tokenAmount) internal virtual;
    function _balanceOf(address holder) internal view virtual returns(uint256);

    function updateRouter(address newAddress) public virtual onlyOwner {
        require(newAddress != address(swapRouter), "The router is already set to this address");
        emit UpdateRouter(newAddress, address(swapRouter));
        swapRouter = IUniswapV2Router02(newAddress);
    }

    function updateLiquidityReceiver(address receiverAddress) external onlyOwner {
        require(receiverAddress != liquidityReceiver, "LP is already sent to that address");
        emit UpdateLPReceiver(receiverAddress, liquidityReceiver);
        liquidityReceiver = receiverAddress;
    }

    function swapCurrencyForTokensUnchecked(address tokenAddress, uint256 amount, address destination) internal {
        _swapCurrencyForTokensAdv(tokenAddress, amount, destination);
    }

    function swapTokensForCurrencyAdv(address tokenAddress, uint256 tokenAmount, address destination) internal returns(uint256){
        return _swapTokensForCurrencyAdv(tokenAddress, tokenAmount, destination);
    }

    function _swapTokensForCurrencyAdv(address tokenAddress, uint256 tokenAmount, address destination) private returns(uint256){
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = swapRouter.WETH();
        uint256 tokenCurrentBalance;
        if(tokenAddress != address(this)){
            bool approved = IBEP20(tokenAddress).approve(address(swapRouter), tokenAmount);
            if(!approved){
                return 0;
            }
            tokenCurrentBalance = IBEP20(tokenAddress).balanceOf(address(this));
        } else {
            _approve(address(this), address(swapRouter), tokenAmount);
            tokenCurrentBalance = _balanceOf(address(this));
        }
        if(tokenCurrentBalance < tokenAmount){
            return 0;
        }

        // make the swap
        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            destination,
            block.timestamp
        );

        return tokenAmount;
    }

    function swapCurrencyForTokensAdv(address tokenAddress, uint256 amount, address destination) internal {
        _swapCurrencyForTokensAdv(tokenAddress, amount, destination);
    }

    function _swapCurrencyForTokensAdv(address tokenAddress, uint256 amount, address destination) private {
        address[] memory path = new address[](2);
        path[0] = swapRouter.WETH();
        path[1] = tokenAddress;
        if(amount > address(this).balance){
            amount = address(this).balance;
        }

        // make the swap
        swapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            destination,
            block.timestamp
        );
    }

    function addLiquidityForToken(address tokenAddress, uint256 tokenAmount, uint256 maxCurrency) internal {

        // add the liquidity
        swapRouter.addLiquidityETH{value: maxCurrency}(
            tokenAddress,
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityReceiver,
            block.timestamp
        );
    }
}