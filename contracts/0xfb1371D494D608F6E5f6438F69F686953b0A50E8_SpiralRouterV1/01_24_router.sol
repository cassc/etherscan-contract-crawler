// SPDX-License-Identifier: MIT
    pragma solidity 0.8.16;

    import { IStaking } from "./interfaces/IStaking.sol";
    import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
    import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
    import { IERC20Metadata } from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
    import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
    import { IManagedPool } from "@balancer-labs/v2-interfaces/contracts/pool-utils/IManagedPool.sol";
    import { IVault, IAsset } from "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
    import { IProtocolFeesCollector } from "@balancer-labs/v2-interfaces/contracts/vault/IProtocolFeesCollector.sol";

    interface IBalancerVault {
        function getPool(bytes32 poolId) external view returns (address, bytes memory);
        function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

        function swap(
            IVault.SingleSwap memory singleSwap,
            IVault.FundManagement memory funds,
            uint256 limit,
            uint256 deadline
        ) external payable returns (uint256);

    }

    interface IBalancerPool {
        function getNormalizedWeights() external view returns (uint256[] memory);
    }

    interface ICurveZap {
        function get_dy(address,uint256,uint256,uint256) external view returns(uint256);
        function exchange(address,uint256,uint256,uint256,uint256) external payable returns(uint256);
    }

    interface ICurvePool {
        function coins(uint256) external view returns(address);
    }

    contract SpiralRouterV1 is Ownable {
        using SafeERC20 for IERC20;

        IERC20 private constant usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        IERC20 private constant coil = IERC20(0x823E1B82cE1Dc147Bbdb25a203f046aFab1CE918);
        IERC20 private constant spiral = IERC20(0x85b6ACaBa696B9E4247175274F8263F99b4B9180);
        IStaking private constant staking = IStaking(0x6701E792b7CD344BaE763F27099eEb314A4b4943);
        ICurveZap private constant curveZap = ICurveZap(0x5De4EF4879F4fe3bBADF2227D2aC5d0E2D76C895);
        address private constant curvePool = 0xAF4264916B467e2c9C8aCF07Acc22b9EDdDaDF33;

        IBalancerVault private constant balVault = IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
        IProtocolFeesCollector private constant balFees = IProtocolFeesCollector(0xce88686553686DA562CE7Cea497CE749DA109f9F);
        IBalancerPool private constant balancerPool = IBalancerPool(0x42FBD9F666AaCC0026ca1B88C94259519e03dd67);
        bytes32 private constant balancerPoolId = 0x42fbd9f666aacc0026ca1b88c94259519e03dd67000200000000000000000507;

        constructor() {
            IERC20(coil).safeIncreaseAllowance(address(staking), type(uint256).max);
            IERC20(spiral).safeIncreaseAllowance(address(staking), type(uint256).max);
            IERC20(coil).safeIncreaseAllowance(address(balVault), type(uint256).max);
            IERC20(usdc).safeIncreaseAllowance(address(balVault), type(uint256).max);
            IERC20(coil).safeIncreaseAllowance(address(curvePool), type(uint256).max);
            IERC20(usdc).safeIncreaseAllowance(address(curvePool), type(uint256).max);
            IERC20(coil).safeIncreaseAllowance(address(curveZap), type(uint256).max);
            IERC20(usdc).safeIncreaseAllowance(address(curveZap), type(uint256).max);
        }

        /***************************
                    VIEW
        *****************************/

        function curveCalculateAmountOut(
            address tokenIn,
            address tokenOut,
            uint256 tokenInAmount
        ) public view returns (uint256) {
            if (tokenInAmount == 0) {
                return 0;
            }
            uint256 i;
            uint256 j;
            if (address(tokenIn) == address(coil)) {
                i = 0;
                j = 2;
            } else {
                i = 2;
                j = 0;
            }
            return curveZap.get_dy(curvePool, i, j, tokenInAmount);
        }

        function balancerCalculateAmountOut(
            address tokenIn,
            address tokenOut,
            uint256 tokenInAmount
        ) public view returns (uint256) {

            if (tokenInAmount == 0) {
                return 0;
            }
            (address[] memory poolTokens, uint256[] memory rawBalances, ) = balVault.getPoolTokens(balancerPoolId);

            uint256 tokenInBalance = tokenIn == poolTokens[0] ? rawBalances[0] : rawBalances[1];
            uint256 tokenOutBalance = tokenOut == poolTokens[0] ? rawBalances[0] : rawBalances[1];


            uint256 fee = balFees.getSwapFeePercentage();
            uint256 tokenInBalanceAdjusted = tokenInBalance + tokenInAmount;
            uint256 spotPrice = (tokenOutBalance * (1e20-fee) / (tokenInBalanceAdjusted));

            uint256 tokenOutAmount = tokenInAmount * spotPrice / 1e20;
            return tokenOutAmount;
        }

        function getBestRouteData(address tokenIn, address tokenOut, uint256 amountIn) public view returns (uint256 curveAmount, uint256 balancerAmount, uint256 maxOutput) {
            address _tokenIn = tokenIn;
            uint256 _amountIn = amountIn;
            address _tokenOut = tokenOut;
            if (tokenIn == address(spiral)) {
                amountIn = amountIn * staking.index() / 10**18;
                _tokenIn = address(coil);
            }
            if (tokenOut == address(spiral)){
                _tokenOut = address(coil);
            }
            uint256 maxAmountIn = amountIn;
            uint256 maxAmountOut = curveCalculateAmountOut(_tokenIn, _tokenOut, amountIn);
            for (uint i = 1; i < 100; i++) {
                curveAmount = curveCalculateAmountOut(_tokenIn, _tokenOut, amountIn * (100-i) / 100);
                balancerAmount = balancerCalculateAmountOut(_tokenIn, _tokenOut, amountIn * i / 100);
                if (curveAmount + balancerAmount > maxAmountOut) {
                    maxAmountIn = amountIn * (100-i) / 100;
                    maxAmountOut = curveAmount + balancerAmount;
                }
            }
            
            if (tokenIn == address(spiral)) {
                maxAmountIn = maxAmountIn * 10**18 / staking.index();
            }

            if (maxAmountIn < _amountIn * 10 / 100){
                maxAmountOut = balancerCalculateAmountOut(_tokenIn, _tokenOut, amountIn);
                if (tokenOut == address(spiral)) {
                    maxAmountOut = maxAmountOut * 10**18 / staking.index();
                }
                return (0, _amountIn, maxAmountOut);
            }

            if (maxAmountIn > _amountIn * 90 / 100){
                maxAmountOut = curveCalculateAmountOut(_tokenIn, _tokenOut, amountIn);
                if (tokenOut == address(spiral)) {
                    maxAmountOut = maxAmountOut * 10**18 / staking.index();
                }
                return (_amountIn, 0, maxAmountOut);
            }
           
            if (tokenOut == address(spiral)){
                maxAmountOut = maxAmountOut * 10**18 / staking.index();
            }

            return(maxAmountIn, _amountIn - maxAmountIn, maxAmountOut);
        }

        /***************************
                    SWAP
        *****************************/

        function swap(
            address tokenIn,
            address tokenOut,
            uint256[2] calldata amounts,
            uint256 minAmountOut
        ) external {
            uint256 amountIn = amounts[0]+amounts[1];
            uint256 amount0 = amounts[0];
            uint256 amount1 = amounts[1];
            IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
            if (tokenIn == address(spiral)){
                staking.unstake(amountIn);
                tokenIn = address(coil);
                amountIn = coil.balanceOf(address(this));
                amount0 = amount0 * staking.index() / 10**18;
                amount1 = amount1 * staking.index() / 10**18; 
            }
            address tokenOut_ = tokenOut;
            if (tokenOut == address(spiral)) {
                tokenOut_ = address(coil);
            }
            uint256 balanceBefore = IERC20(tokenOut_).balanceOf(address(this));
            if (amount0 > 0){
                curveSwap(IERC20(tokenIn), IERC20(tokenOut_), amount0, 0);
            }
            if (amount1 > 0) {
                balancerSwap(tokenIn, tokenOut_, IERC20(tokenIn).balanceOf(address(this)), 0);
            }
            uint256 actualOut = IERC20(tokenOut_).balanceOf(address(this)) - balanceBefore;

            if(tokenOut == address(spiral)) {
                staking.stake(actualOut);
                require(spiral.balanceOf(address(this)) >= minAmountOut, 'slippage');
                spiral.safeTransfer(msg.sender, spiral.balanceOf(address(this)));
            } else {
                require(actualOut >= minAmountOut, 'slippage');
                IERC20(tokenOut).transfer(msg.sender, actualOut);
            }
        }

        function curveSwap(
            IERC20 tokenIn,
            IERC20 tokenOut,
            uint256 amountIn,
            uint256 minAmountOut
        ) internal {
            ICurvePool pool = ICurvePool(curvePool);
            uint256 i;
            uint256 j;
            if (address(tokenIn) == address(coil)) {
                i = 0;
                j = 2;
            } else {
                i = 2;
                j = 0;
            }
            curveZap.exchange(address(pool), i, j, amountIn, minAmountOut);
        }

        function balancerSwap(
            address tokenIn,
            address tokenOut,
            uint256 amountIn,
            uint256 minAmountOut
        ) internal {
            balVault.swap(
                IVault.SingleSwap(
                    balancerPoolId,
                    IVault.SwapKind.GIVEN_IN,
                    IAsset(tokenIn),
                    IAsset(tokenOut),
                    amountIn,
                    new bytes(0)
                ),
                IVault.FundManagement(
                    address(this),
                    false,
                    payable(address(this)),
                    false
                ),
                minAmountOut,
                block.timestamp
            );
        }
    }