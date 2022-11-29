// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";

import "../../libs/v2libraries/UniswapV2Library.sol";
import "../../libs/v2libraries/UniswapV2LiquidityMathLibrary.sol";
import "../../libs/v2libraries/interfaces/IUniswapV2Router02.sol";
import "../../libs/interfaces/IWEH.sol";
import "../../libs/interfaces/INPOSTtoken.sol";

abstract contract Erc20Treasury {

////////////////////////////////////////// initialize

    function __init_Erc20Treasury(
        uint256 _feeInPromille,
        address _NPOSTtoken,
        address _uniswapV2Router
    ) internal {
        _editFee(_feeInPromille);
        NPOSTtoken = _NPOSTtoken;
        uniswapV2Router = _uniswapV2Router;
        WETH = IUniswapV2Router02(_uniswapV2Router).WETH();
        factory = IUniswapV2Router02(_uniswapV2Router).factory();
    }

    function __init_Unlocked() internal {
        unlocked = 1;
    }

////////////////////////////////////////// fields definition

    uint256 internal constant PROMILLE = 1000;

    uint8 private unlocked;

    uint256 public feeInPromille;
    address public NPOSTtoken;

    address public uniswapV2Router;
    address public WETH;
    address public factory;

    /** see https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps */
    uint256[44] private __gap;

////////////////////////////////////////// modifiers

    modifier lock() {
        require(unlocked == 1, "LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

////////////////////////////////////////// methods for fee

    function _editFee(
        uint256 _feeInPromille
    )
        internal
    {
        require(_feeInPromille < PROMILLE, '_editFee: _feeInPromille cant be more then 1000');
        feeInPromille = _feeInPromille;
    }

    function calculateFeeInEth(
        uint256 _amount
    )
        public
        view
        returns(uint256)
    {
        return _amount * feeInPromille / PROMILLE;
    }

////////////////////////////////////////// methods for work with moneys

    function _takeEthAndBurnFee(
        uint256 _feeInETH
    )
        internal
        returns (uint256 feeInToken)
    {
        IWETH(WETH).deposit{value: _feeInETH}();

        feeInToken = __swapEthToToken(_feeInETH);

        INPOSTtoken(NPOSTtoken).burn(feeInToken);

        return feeInToken;
    }

    function __swapEthToToken(
        uint256 amountEth
    )
        private
        lock
        returns(uint256)
    {
        uint256 balanceBefore = IERC20Upgradeable(NPOSTtoken).balanceOf(address(this));

        address pair = UniswapV2Library.pairFor(factory, WETH, NPOSTtoken);
        assert(IWETH(WETH).transfer(pair, amountEth));

        (address token0, ) = UniswapV2Library.sortTokens(WETH, NPOSTtoken);

        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pair).getReserves();
        (uint256 reserveInput, uint256 reserveOutput) = WETH == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        uint256 amountOutput = UniswapV2Library.getAmountOut(amountEth, reserveInput, reserveOutput);

        (uint amount0Out, uint amount1Out) = WETH == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));

        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), new bytes(0));

        uint256 balanceAfter = IERC20Upgradeable(NPOSTtoken).balanceOf(address(this));

        return balanceAfter - balanceBefore;
    }

    function _sendEth(
        uint256 _amount,
        address account
    )
        internal
    {
        (bool success, ) = payable(account).call{value: _amount}( new bytes(0) );
        require( success, "_sendEth: ETH transfer failed" );
    }

////////////////////////////////////////// receive

    receive() external payable {}
}