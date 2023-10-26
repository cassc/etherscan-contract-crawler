// SPDX-License-Identifier: VPL
pragma solidity ^0.8.20;

import "solady/src/auth/Ownable.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "solidity-lib/libraries/TransferHelper.sol";
import "v2-periphery/interfaces/IUniswapV2Router02.sol";
import "v2-periphery/interfaces/IWETH.sol";
import "./UniswapV2Library.sol";

// Majority of code was taken from the following link
// https://github.com/Roger-Wu/uniswap-v2-liquidity-adder-contract/blob/master/contracts/UniswapV2AddLiquidityHelperV1_1.sol
// Quite a few changes were necessary for Solidity >0.8.0 but most of the logic is still @Roger-Wu's

contract UniswapV2LiquidityHelper is Ownable {
    address public immutable _uniswapV2FactoryAddress;
    address public immutable _uniswapV2Router02Address;
    address public immutable _wethAddress;

    constructor(
        address uniswapV2FactoryAddress,
        address uniswapV2Router02Address,
        address wethAddress
    ) payable {
        _uniswapV2FactoryAddress = uniswapV2FactoryAddress;
        _uniswapV2Router02Address = uniswapV2Router02Address;
        _wethAddress = wethAddress;
        _initializeOwner(msg.sender);
    }

    // fallback() external payable {}
    receive() external payable {}

    // Add as more tokenA and tokenB as possible to a Uniswap pair.
    // The ratio between tokenA and tokenB can be any.
    // Approve enough amount of tokenA and tokenB to this contract before calling this function.
    // Uniswap pair tokenA-tokenB must exist.
    function swapAndAddLiquidityTokenAndToken(
        address tokenAddressA,
        address tokenAddressB,
        uint112 amountA,
        uint112 amountB,
        uint112 minLiquidityOut,
        address to
    ) external returns(uint liquidity) {
        require(amountA > 0 || amountB > 0, "amounts can not be both 0");

        // transfer user's tokens to this contract
        if (amountA > 0) {
            TransferHelper.safeTransferFrom(tokenAddressA, msg.sender, address(this), uint(amountA));
        }
        if (amountB > 0) {
            TransferHelper.safeTransferFrom(tokenAddressB, msg.sender, address(this), uint(amountB));
        }

        return _swapAndAddLiquidity(
            tokenAddressA,
            tokenAddressB,
            uint(amountA),
            uint(amountB),
            uint(minLiquidityOut),
            to
        );
    }

    // Add as more ether and tokenB as possible to a Uniswap pair.
    // The ratio between ether and tokenB can be any.
    // Approve enough amount of tokenB to this contract before calling this function.
    // Uniswap pair WETH-tokenB must exist.
    /*function swapAndAddLiquidityEthAndToken(
        address tokenAddressB,
        uint112 amountB,
        uint112 minLiquidityOut,
        address to
    ) external payable returns(uint liquidity) {
        uint amountA = msg.value;
        address tokenAddressA = _wethAddress;

        require(amountA > 0 || amountB > 0, "amounts can not be both 0");

        // convert ETH to WETH
        IWETH(_wethAddress).deposit{value: amountA}();
        // transfer user's tokenB to this contract
        if (amountB > 0) {
            TransferHelper.safeTransferFrom(tokenAddressB, msg.sender, address(this), uint(amountB));
        }

        return _swapAndAddLiquidity(
            tokenAddressA,
            tokenAddressB,
            amountA,
            uint(amountB),
            uint(minLiquidityOut),
            to
        );
    }*/

    // add as more tokens as possible to a Uniswap pair
    function _swapAndAddLiquidity(
        address tokenAddressA,
        address tokenAddressB,
        uint amountA,
        uint amountB,
        uint minLiquidityOut,
        address to
    ) internal returns(uint liquidity) {
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(_uniswapV2FactoryAddress, tokenAddressA, tokenAddressB);

        // Swap tokenA and tokenB s.t. amountA / reserveA >= amountB / reserveB
        // (or amountA * reserveB >= reserveA * amountB)
        // which means we will swap part of tokenA to tokenB before adding liquidity.
        if (amountA * reserveB < reserveA * amountB) {
            (tokenAddressA, tokenAddressB) = (tokenAddressB, tokenAddressA);
            (reserveA, reserveB) = (reserveB, reserveA);
            (amountA, amountB) = (amountB, amountA);
        }
        uint amountAToAdd = amountA;
        uint amountBToAdd = amountB;
        if (IERC20(tokenAddressA).allowance(address(this), _uniswapV2Router02Address) < amountA) {
            TransferHelper.safeApprove(tokenAddressA, _uniswapV2Router02Address, 2**256 - 1);
        }

        uint amountAToSwap = calcAmountAToSwap(reserveA, reserveB, amountA, amountB);
        require(amountAToSwap <= amountA, "bugs in calcAmountAToSwap cause amountAToSwap > amountA");
        if (amountAToSwap > 0) {
            address[] memory path = new address[](2);
            path[0] = tokenAddressA;
            path[1] = tokenAddressB;

            uint[] memory swapOutAmounts = IUniswapV2Router02(_uniswapV2Router02Address).swapExactTokensForTokens(
                amountAToSwap, // uint amountIn,
                1, // uint amountOutMin,
                path, // address[] calldata path,
                address(this), // address to,
                2**256-1 // uint deadline
            );

            amountAToAdd -= amountAToSwap;
            amountBToAdd += swapOutAmounts[swapOutAmounts.length - 1];
        }

        // _approveTokenToRouterIfNecessary(tokenAddressB, amountBToAdd);
        if (IERC20(tokenAddressB).allowance(address(this), _uniswapV2Router02Address) < amountBToAdd) {
            TransferHelper.safeApprove(tokenAddressB, _uniswapV2Router02Address, 2**256 - 1);
        }
        (, , liquidity) = IUniswapV2Router02(_uniswapV2Router02Address).addLiquidity(
            tokenAddressA, // address tokenA,
            tokenAddressB, // address tokenB,
            amountAToAdd, // uint amountADesired,
            amountBToAdd, // uint amountBDesired,
            1, // uint amountAMin,
            1, // uint amountBMin,
            to, // address to,
            2**256-1 // uint deadline
        );

        require(liquidity >= minLiquidityOut, "minted liquidity not enough");

        // Due to the inaccuracy of integer division,
        // there may be a small amount of tokens left in this contract.
        // Usually it doesn't worth it to spend more gas to transfer them out.
        // These tokens will be considered as a donation to the owner.
        // All ether and tokens directly sent to this contract will be considered as a donation to the contract owner.
    }

    function calcAmountAToSwap(
        uint reserveA,
        uint reserveB,
        uint amountA,
        uint amountB
    ) public pure returns(
        uint amountAToSwap
    ) {
        // separating requirements somehow saves gas.
        require(reserveA > 0, "reserveA can't be empty");
        require(reserveB > 0, "reserveB can't be empty");
        require(reserveA < 2**112, "reserveA must be < 2**112");
        require(reserveB < 2**112, "reserveB must be < 2**112");
        require(amountA < 2**112, "amountA must be < 2**112");
        require(amountB < 2**112, "amountB must be < 2**112");
        require(amountA * reserveB >= reserveA * amountB, "require amountA / amountB >= reserveA / reserveB");

        uint l = 0; // minAmountAToSwap
        uint r = amountA; // maxAmountAToSwap
        // avoid binary search going too deep. saving gas
        uint tolerance = amountA / 10000;
        if (tolerance == 0) { tolerance = 1; }
        uint newReserveA;
        uint newReserveB;
        uint newAmountA;
        uint newAmountB;

        // cache rA_times_1000 and rA_times_rB_times_1000 to save gas
        // Since reserveA, reserveB are both < 2**112,
        // rA_times_rB_times_1000 won't overflow.
        uint rA_times_1000 = reserveA * 1000;
        uint rA_times_rB_times_1000 = rA_times_1000 * reserveB;

        // goal:
        //   after swap l tokenA,
        //     newAmountA / newAmountB >= newReserveA / newReserveB
        //   after swap r tokenA,
        //     newAmountA / newAmountB < newReserveA / newReserveB
        //   r <= l + tolerance
        while (l + tolerance < r) {
            amountAToSwap = (l + r) / 2;

            newReserveA = reserveA + amountAToSwap;
            // (1000 * reserveA + 997 * amountAToSwap) * newReserveB = 1000 * reserveA * reserveB
            newReserveB = rA_times_rB_times_1000 / (rA_times_1000 + 997 * amountAToSwap);
            newAmountA = amountA - amountAToSwap; // amountAToSwap <= amountA
            newAmountB = amountB + (reserveB - newReserveB); // newReserveB <= reserveB
            if (newAmountA * newReserveB >= newReserveA * newAmountB) {
                l = amountAToSwap;
            } else {
                r = amountAToSwap;
            }
        }
        return l;
    }

    function emergencyWithdrawEther() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
        require(success, "withdraw failure");
    }

    function emergencyWithdrawErc20(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        TransferHelper.safeTransfer(tokenAddress, msg.sender, token.balanceOf(address(this)));
    }
}