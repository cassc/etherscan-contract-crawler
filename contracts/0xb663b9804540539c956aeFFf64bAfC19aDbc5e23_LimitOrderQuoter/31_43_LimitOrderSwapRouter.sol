// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../lib/interfaces/token/IERC20.sol";
import "../lib/interfaces/uniswap-v2/IUniswapV2Factory.sol";
import "../lib/interfaces/uniswap-v2/IUniswapV2Pair.sol";
import "../lib/interfaces/uniswap-v3/IUniswapV3Factory.sol";
import "../lib/interfaces/uniswap-v3/IUniswapV3Pool.sol";
import "./lib/ConveyorMath.sol";
import "./LimitOrderBook.sol";
import "./lib/ConveyorTickMath.sol";
import "../lib/libraries/Uniswap/FullMath.sol";
import "../lib/libraries/Uniswap/FixedPoint96.sol";
import "../lib/libraries/Uniswap/TickMath.sol";
import "../lib/interfaces/token/IWETH.sol";
import "./lib/ConveyorFeeMath.sol";
import "../lib/libraries/Uniswap/SqrtPriceMath.sol";
import "../lib/interfaces/uniswap-v3/IQuoter.sol";
import "../lib/libraries/token/SafeERC20.sol";
import "./ConveyorErrors.sol";
import "./interfaces/ILimitOrderSwapRouter.sol";

/// @title LimitOrderSwapRouter
/// @author 0xKitsune, 0xOsiris, Conveyor Labs
/// @notice Dex aggregator that executes standalone swaps, and fulfills limit orders during execution.
contract LimitOrderSwapRouter is ConveyorTickMath {
    using SafeERC20 for IERC20;
    //----------------------Structs------------------------------------//

    ///@notice Struct to store DEX details
    ///@param factoryAddress - The factory address for the DEX
    ///@param initBytecode - The bytecode sequence needed derrive pair addresses from the factory.
    ///@param isUniV2 - Boolean to distinguish if the DEX is UniV2 compatible.
    struct Dex {
        address factoryAddress;
        bool isUniV2;
    }

    ///@notice Struct to store price information between the tokenIn/Weth and tokenOut/Weth pairings during order batching.
    ///@param aToWethReserve0 - tokenIn reserves on the tokenIn/Weth pairing.
    ///@param aToWethReserve1 - Weth reserves on the tokenIn/Weth pairing.
    ///@param wethToBReserve0 - Weth reserves on the Weth/tokenOut pairing.
    ///@param wethToBReserve1 - tokenOut reserves on the Weth/tokenOut pairing.
    ///@param price - Price of tokenIn per tokenOut based on the exchange rate of both pairs, represented as a 128x128 fixed point.
    ///@param lpAddressAToWeth - LP address of the tokenIn/Weth pairing.
    ///@param lpAddressWethToB -  LP address of the Weth/tokenOut pairing.
    struct TokenToTokenExecutionPrice {
        uint128 aToWethReserve0;
        uint128 aToWethReserve1;
        uint128 wethToBReserve0;
        uint128 wethToBReserve1;
        uint256 price;
        address lpAddressAToWeth;
        address lpAddressWethToB;
    }

    ///@notice Struct to store price information for a tokenIn/Weth pairing.
    ///@param aToWethReserve0 - tokenIn reserves on the tokenIn/Weth pairing.
    ///@param aToWethReserve1 - Weth reserves on the tokenIn/Weth pairing.
    ///@param price - Price of tokenIn per Weth, represented as a 128x128 fixed point.
    ///@param lpAddressAToWeth - LP address of the tokenIn/Weth pairing.
    struct TokenToWethExecutionPrice {
        uint128 aToWethReserve0;
        uint128 aToWethReserve1;
        uint256 price;
        address lpAddressAToWeth;
    }

    ///@notice Struct to represent the spot price and reserve values on a given LP address
    ///@param spotPrice - Spot price of the LP address represented as a 128x128 fixed point number.
    ///@param res0 - The amount of reserves for the tokenIn.
    ///@param res1 - The amount of reserves for the tokenOut.
    ///@param token0IsReserve0 - Boolean to indicate if the tokenIn corresponds to reserve 0.
    struct SpotReserve {
        uint256 spotPrice;
        uint128 res0;
        uint128 res1;
        bool token0IsReserve0;
    }

    //----------------------State Variables------------------------------------//

    ///@notice Storage variable to hold the amount received from a v3 swap in the v3 callback.
    uint256 uniV3AmountOut;

    //----------------------State Structures------------------------------------//

    ///@notice Array of Dex that is used to calculate spot prices for a given order.
    Dex[] public dexes;

    ///@notice Mapping from DEX factory address to the index of the DEX in the dexes array
    mapping(address => uint256) dexToIndex;

    //======================Events==================================

    event UniV2SwapError(string indexed reason);
    event UniV3SwapError(string indexed reason);

    //======================Constants================================

    uint128 private constant MIN_FEE_64x64 = 18446744073709552;
    uint128 private constant BASE_SWAP_FEE = 55340232221128660;
    uint128 private constant MAX_UINT_128 = 0xffffffffffffffffffffffffffffffff;
    uint256 private constant MAX_UINT_256 =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 private constant ONE_128x128 = uint256(1) << 128;
    uint24 private constant ZERO_UINT24 = 0;
    uint256 private constant ZERO_POINT_NINE = 16602069666338597000 << 64;
    uint256 private constant ONE_POINT_TWO_FIVE = 23058430092136940000 << 64;
    uint128 private constant ZERO_POINT_ONE = 1844674407370955300;
    uint128 private constant ZERO_POINT_ZERO_ZERO_FIVE = 92233720368547760;
    uint128 private constant ZERO_POINT_ZERO_ZERO_ONE = 18446744073709550;

    //======================Immutables================================

    ///@notice The address of the Uniswap V3 factory. b
    address immutable UNISWAP_V3_FACTORY;

    //======================Constructor================================

    /**@dev It is important to note that a univ2 compatible DEX must be initialized in the 0th index.
        The calculateFee function relies on a uniV2 DEX to be in the 0th index.*/
    ///@param _dexFactories - Array of DEX factory addresses.
    ///@param _isUniV2 - Array of booleans indicating if the DEX is UniV2 compatible.
    constructor(address[] memory _dexFactories, bool[] memory _isUniV2) {
        ///@notice Initialize DEXs and other variables
        for (uint256 i = 0; i < _dexFactories.length; ++i) {
            if (i == 0) {
                require(_isUniV2[i], "First Dex must be uniswap v2");
            }
            require(
                _dexFactories[i] != address(0),
                "Zero values in constructor"
            );
            dexes.push(
                Dex({
                    factoryAddress: _dexFactories[i],
                    isUniV2: _isUniV2[i]
                })
            );

            address uniswapV3Factory;
            ///@notice If the dex is a univ3 variant, then set the uniswapV3Factory storage address.
            if (!_isUniV2[i]) {
                uniswapV3Factory = _dexFactories[i];
            }

            UNISWAP_V3_FACTORY = uniswapV3Factory;
        }
    }

    ///@notice Transfer ETH to a specific address and require that the call was successful.
    ///@param to - The address that should be sent Ether.
    ///@param amount - The amount of Ether that should be sent.
    function _safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        if (!success) {
            revert ETHTransferFailed();
        }
    }

    /// @notice Helper function to calculate the logistic mapping output on a USDC input quantity for fee % calculation.
    /// @dev amountIn must be in WETH represented in 18 decimal form.
    /// @dev This calculation assumes that all values are in a 64x64 fixed point uint128 representation.
    /** @param amountIn - Amount of Weth represented as a 64x64 fixed point value to calculate the fee that will be applied
    to the amountOut of an executed order. */
    ///@param usdc - Address of USDC
    ///@param weth - Address of Weth
    /// @return calculated_fee_64x64 -  Returns the fee percent that is applied to the amountOut realized from an executed.
    ///NOTE: f(x)=0.225/e^(x/100000)+0.025
    function calculateFee(
        uint128 amountIn,
        address usdc,
        address weth
    ) public view returns (uint128) {
        if (amountIn == 0) {
            revert AmountInIsZero();
        }

        ///@notice Initialize spot reserve structure to retrive the spot price from uni v2
        (SpotReserve memory _spRes, ) = _calculateV2SpotPrice(
            weth,
            usdc,
            dexes[0].factoryAddress
        );

        ///@notice Cache the spot price
        uint256 spotPrice = _spRes.spotPrice;

        ///@notice The SpotPrice is represented as a 128x128 fixed point value. To derive the amount in USDC, multiply spotPrice*amountIn and adjust to base 10
        uint256 amountInUSDCDollarValue = ConveyorMath.mul128U(
            spotPrice,
            amountIn
        ) / uint256(10**18);

        ///@notice if usdc value of trade is >= 1,000,000 set static fee of 0.00025
        if (amountInUSDCDollarValue >= 1000000) {
            return 4611686018427388;
        }

        uint128 numerator = 4150517416584649000;

        ///@notice Exponent= usdAmount/100000
        uint128 exponent = uint128(
            ConveyorMath.divUU(amountInUSDCDollarValue, 100000)
        );

        // ///@notice This is to prevent overflow, and order is of sufficient size to receive 0.00025 fee
        if (exponent >= 0x400000000000000000) {
            return 4611686018427388;
        }

        ///@notice denominator = ( e^(exponent))
        uint128 denominator = ConveyorMath.exp(exponent);

        // ///@notice divide numerator by denominator
        uint128 rationalFraction = ConveyorMath.div64x64(
            numerator,
            denominator
        );

        return
            ConveyorMath.add64x64(rationalFraction, 461168601842738800) / 10**2;
    }

    ///@notice Helper function to transfer ERC20 tokens out to an order owner address.
    ///@param orderOwner - The address to send the tokens to.
    ///@param amount - The amount of tokenOut to send to orderOwner.
    ///@param tokenOut - The address of the ERC20 token being sent to orderOwner.
    function _transferTokensOutToOwner(
        address orderOwner,
        uint256 amount,
        address tokenOut
    ) internal {
        IERC20(tokenOut).safeTransfer(orderOwner, amount);
    }

    ///@notice Helper function to transfer the reward to the off-chain executor.
    ///@param totalBeaconReward - The total reward to be transferred to the executor.
    ///@param executorAddress - The address to send the reward to.
    ///@param weth - The wrapped native token address.
    function _transferBeaconReward(
        uint256 totalBeaconReward,
        address executorAddress,
        address weth
    ) internal {
        ///@notice Unwrap the total reward.
        IWETH(weth).withdraw(totalBeaconReward);

        ///@notice Send the off-chain executor their reward.
        _safeTransferETH(executorAddress, totalBeaconReward);
    }

    ///@notice Helper function to execute a swap on a UniV2 LP
    ///@param _tokenIn - Address of the tokenIn.
    ///@param _tokenOut - Address of the tokenOut.
    ///@param _lp - Address of the lp.
    ///@param _amountIn - AmountIn for the swap.
    ///@param _amountOutMin - AmountOutMin for the swap.
    ///@param _receiver - Address to receive the amountOut.
    ///@param _sender - Address to send the tokenIn.
    ///@return amountReceived - Amount received from the swap.
    function _swapV2(
        address _tokenIn,
        address _tokenOut,
        address _lp,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _receiver,
        address _sender
    ) internal returns (uint256 amountReceived) {
        ///@notice If the sender is not the current context
        ///@dev This can happen when swapping taxed tokens to avoid being double taxed by sending the tokens to the contract instead of directly to the lp
        if (_sender != address(this)) {
            ///@notice Transfer the tokens to the lp from the sender.
            IERC20(_tokenIn).safeTransferFrom(_sender, _lp, _amountIn);
        } else {
            ///@notice Transfer the tokens to the lp from the current context.
            IERC20(_tokenIn).safeTransfer(_lp, _amountIn);
        }

        ///@notice Get token0 from the pairing.
        (address token0, ) = _sortTokens(_tokenIn, _tokenOut);

        ///@notice Intialize the amountOutMin value
        (uint256 amount0Out, uint256 amount1Out) = _tokenIn == token0
            ? (uint256(0), _amountOutMin)
            : (_amountOutMin, uint256(0));

        ///@notice Get the balance before the swap to know how much was received from swapping.
        uint256 balanceBefore = IERC20(_tokenOut).balanceOf(_receiver);

        ///@notice Execute the swap on the lp for the amounts specified.
        IUniswapV2Pair(_lp).swap(
            amount0Out,
            amount1Out,
            _receiver,
            new bytes(0)
        );

        ///@notice calculate the amount recieved
        amountReceived = IERC20(_tokenOut).balanceOf(_receiver) - balanceBefore;

        ///@notice if the amount recieved is less than the amount out min, revert
        if (amountReceived < _amountOutMin) {
            revert InsufficientOutputAmount(amountReceived, _amountOutMin);
        }

        return amountReceived;
    }

    ///@notice Payable fallback to receive ether.
    receive() external payable {}

    ///@notice Agnostic swap function that determines whether or not to swap on univ2 or univ3
    ///@param _tokenIn - Address of the tokenIn.
    ///@param _tokenOut - Address of the tokenOut.
    ///@param _lp - Address of the lp.
    ///@param _fee - Fee for the lp address.
    ///@param _amountIn - AmountIn for the swap.
    ///@param _amountOutMin - AmountOutMin for the swap.
    ///@param _receiver - Address to receive the amountOut.
    ///@param _sender - Address to send the tokenIn.
    ///@return amountReceived - Amount received from the swap.
    function _swap(
        address _tokenIn,
        address _tokenOut,
        address _lp,
        uint24 _fee,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _receiver,
        address _sender
    ) internal returns (uint256 amountReceived) {
        if (_lpIsNotUniV3(_lp)) {
            amountReceived = _swapV2(
                _tokenIn,
                _tokenOut,
                _lp,
                _amountIn,
                _amountOutMin,
                _receiver,
                _sender
            );
        } else {
            amountReceived = _swapV3(
                _lp,
                _tokenIn,
                _tokenOut,
                _fee,
                _amountIn,
                _amountOutMin,
                _receiver,
                _sender
            );
        }
    }

    ///@notice Function to swap two tokens on a Uniswap V3 pool.
    ///@param _lp - Address of the liquidity pool to execute the swap on.
    ///@param _tokenIn - Address of the TokenIn on the swap.
    ///@param _fee - The swap fee on the liquiditiy pool.
    ///@param _amountIn The amount in for the swap.
    ///@param _amountOutMin The minimum amount out in TokenOut post swap.
    ///@param _receiver The receiver of the tokens post swap.
    ///@param _sender The sender of TokenIn on the swap.
    ///@return amountReceived The amount of TokenOut received post swap.
    function _swapV3(
        address _lp,
        address _tokenIn,
        address _tokenOut,
        uint24 _fee,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _receiver,
        address _sender
    ) internal returns (uint256 amountReceived) {
        ///@notice Initialize variables to prevent stack too deep.
        bool _zeroForOne;

        ///@notice Scope out logic to prevent stack too deep.
        {
            (address token0, ) = _sortTokens(_tokenIn, _tokenOut);
            _zeroForOne = token0 == _tokenIn ? true : false;
        }

        ///@notice Pack the relevant data to be retrieved in the swap callback.
        bytes memory data = abi.encode(
            _amountOutMin,
            _zeroForOne,
            _tokenIn,
            _tokenOut,
            _fee,
            _sender
        );

        ///@notice Execute the swap on the lp for the amounts specified.
        IUniswapV3Pool(_lp).swap(
            _receiver,
            _zeroForOne,
            int256(_amountIn),
            _zeroForOne
                ? TickMath.MIN_SQRT_RATIO + 1
                : TickMath.MAX_SQRT_RATIO - 1,
            data
        );

        ///@notice Cache the uniV3Amount.
        uint256 amountOut = uniV3AmountOut;
        ///@notice Set uniV3AmountOut to 0.
        uniV3AmountOut = 0;
        ///@notice Return the amountOut yielded from the swap.
        return amountOut;
    }

    ///@notice Uniswap V3 callback function called during a swap on a v3 liqudity pool.
    ///@param amount0Delta - The change in token0 reserves from the swap.
    ///@param amount1Delta - The change in token1 reserves from the swap.
    ///@param data - The data packed into the swap.
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        ///@notice Decode all of the swap data.
        (
            uint256 amountOutMin,
            bool _zeroForOne,
            address tokenIn,
            address tokenOut,
            uint24 fee,
            address _sender
        ) = abi.decode(
                data,
                (uint256, bool, address, address, uint24, address)
            );

        address poolAddress = IUniswapV3Factory(UNISWAP_V3_FACTORY).getPool(
            tokenIn,
            tokenOut,
            fee
        );

        if (msg.sender != poolAddress) {
            revert UnauthorizedUniswapV3CallbackCaller();
        }

        ///@notice If swapping token0 for token1.
        if (_zeroForOne) {
            ///@notice Set contract storage variable to the amountOut from the swap.
            uniV3AmountOut = uint256(-amount1Delta);

            ///@notice If swapping token1 for token0.
        } else {
            ///@notice Set contract storage variable to the amountOut from the swap.
            uniV3AmountOut = uint256(-amount0Delta);
        }

        ///@notice Require the amountOut from the swap is greater than or equal to the amountOutMin.
        if (uniV3AmountOut < amountOutMin) {
            revert InsufficientOutputAmount(uniV3AmountOut, amountOutMin);
        }

        ///@notice Set amountIn to the amountInDelta depending on boolean zeroForOne.
        uint256 amountIn = _zeroForOne
            ? uint256(amount0Delta)
            : uint256(amount1Delta);

        if (!(_sender == address(this))) {
            ///@notice Transfer the amountIn of tokenIn to the liquidity pool from the sender.
            IERC20(tokenIn).safeTransferFrom(_sender, poolAddress, amountIn);
        } else {
            IERC20(tokenIn).safeTransfer(poolAddress, amountIn);
        }
    }

    /// @notice Helper function to get Uniswap V2 spot price of pair token0/token1.
    /// @param token0 - Address of token1.
    /// @param token1 - Address of token2.
    /// @param _factory - Factory address.
    function _calculateV2SpotPrice(
        address token0,
        address token1,
        address _factory
    ) internal view returns (SpotReserve memory spRes, address poolAddress) {
        ///@notice Require token address's are not identical

        if (token0 == token1) {
            revert IdenticalTokenAddresses();
        }

        address tok0;
        address tok1;

        {
            (tok0, tok1) = _sortTokens(token0, token1);
        }

        ///@notice SpotReserve struct to hold the reserve values and spot price of the dex.
        SpotReserve memory _spRes;

        ///@notice Get pool address on the token pair.
        address pairAddress = _getV2PairAddress(_factory, tok0, tok1);

        bool token0IsReserve0 = tok0 == token0 ? true : false;

        ///@notice If the token pair does not exist on the dex return empty SpotReserve struct.
        if (address(0) == pairAddress) {
            return (_spRes, address(0));
        }
        {
            ///@notice Set reserve0, reserve1 to current LP reserves
            (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pairAddress)
                .getReserves();

            ///@notice Convert the reserve values to a common decimal base.
            (
                uint256 commonReserve0,
                uint256 commonReserve1
            ) = _getReservesCommonDecimals(tok0, tok1, reserve0, reserve1);

            ///@notice Set spotPrice to the current spot price on the dex represented as 128.128 fixed point.
            _spRes.spotPrice = token0IsReserve0
                ? uint256(ConveyorMath.divUU(commonReserve1, commonReserve0)) <<
                    64
                : _spRes.spotPrice =
                uint256(ConveyorMath.divUU(commonReserve0, commonReserve1)) <<
                64;

            _spRes.token0IsReserve0 = token0IsReserve0;

            ///@notice Set res0, res1 on SpotReserve to commonReserve0, commonReserve1 respectively.
            (_spRes.res0, _spRes.res1) = (
                uint128(commonReserve0),
                uint128(commonReserve1)
            );
        }

        ///@notice Return pool address and populated SpotReserve struct.
        (spRes, poolAddress) = (_spRes, pairAddress);
    }

    ///@notice Helper function to convert reserve values to common 18 decimal base.
    ///@param tok0 - Address of token0.
    ///@param tok1 - Address of token1.
    ///@param reserve0 - Reserve0 liquidity.
    ///@param reserve1 - Reserve1 liquidity.
    function _getReservesCommonDecimals(
        address tok0,
        address tok1,
        uint128 reserve0,
        uint128 reserve1
    ) internal view returns (uint128, uint128) {
        ///@notice Get target decimals for token0 & token1
        uint8 token0Decimals = IERC20(tok0).decimals();
        uint8 token1Decimals = IERC20(tok1).decimals();

        ///@notice Retrieve the common 18 decimal reserve values.
        uint128 commonReserve0 = token0Decimals <= 18
            ? uint128(reserve0 * (10**(18 - token0Decimals)))
            : uint128(reserve0 * (10**(token0Decimals - 18)));
        uint128 commonReserve1 = token1Decimals <= 18
            ? uint128(reserve1 * (10**(18 - token1Decimals)))
            : uint128(reserve1 * (10**(token1Decimals - 18)));
        return (commonReserve0, commonReserve1);
    }

    /// @notice Helper function to get Uniswap V3 spot price of pair token0/token1
    /// @param token0 - Address of token0.
    /// @param token1 - Address of token1.
    /// @param fee - The fee in the pool.
    /// @param _factory - Uniswap v3 factory address.
    /// @return  _spRes SpotReserve struct to hold reserve0, reserve1, and the spot price of the token pair.
    /// @return pool Address of the Uniswap V3 pool.
    function _calculateV3SpotPrice(
        address token0,
        address token1,
        uint24 fee,
        address _factory
    ) internal view returns (SpotReserve memory _spRes, address pool) {
        ///@notice Sort the tokens to retrieve token0, token1 in the pool.
        (address _tokenX, address _tokenY) = _sortTokens(token0, token1);
        ///@notice Get the pool address for token pair.
        pool = IUniswapV3Factory(_factory).getPool(token0, token1, fee);
        ///@notice Return an empty spot reserve if the pool address was not found.
        if (pool == address(0)) {
            return (_spRes, address(0));
        }
        ///@notice Get the current sqrtPrice ratio.
        (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(pool).slot0();

        ///@notice Boolean indicating whether token0 is token0 in the pool.
        bool token0IsReserve0 = _tokenX == token0 ? true : false;

        ///@notice Initialize block scoped variables
        uint256 priceX128 = fromSqrtX96(
            sqrtPriceX96,
            token0IsReserve0,
            _tokenX,
            _tokenY
        );

        ///@notice Set the spot price in the spot reserve structure.
        _spRes.spotPrice = priceX128;

        return (_spRes, pool);
    }

    ///@notice Helper function to derive the token pair address on a Dex from the factory address and initialization bytecode.
    ///@notice Reference: https://docs.uniswap.org/protocol/V2/guides/smart-contract-integration/getting-pair-addresses
    ///@param _factory - Factory address of the Dex.
    ///@param token0 - Token0 address.
    ///@param token1 - Token1 address.
    function _getV2PairAddress(
        address _factory,
        address token0,
        address token1
    ) internal view returns (address pairAddress) {
        pairAddress = IUniswapV2Factory(_factory).getPair(token0, token1);
    }

    /// @notice Helper function to return sorted token addresses.
    /// @param tokenA - Address of tokenA.
    /// @param tokenB - Address of tokenB.
    function _sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        if (tokenA == tokenB) {
            revert IdenticalTokenAddresses();
        }

        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);

        if (token0 == address(0)) {
            revert AddressIsZero();
        }
    }

    ///@notice Helper function to determine if a pool address is Uni V2 compatible.
    ///@param lp - Pair address.
    ///@return bool Idicator whether the pool is not Uni V3 compatible.
    function _lpIsNotUniV3(address lp) internal returns (bool) {
        bool success;
        assembly {
            //store the function sig for  "fee()"
            mstore(
                0x00,
                0xddca3f4300000000000000000000000000000000000000000000000000000000
            )

            success := call(
                gas(), // gas remaining
                lp, // destination address
                0, // no ether
                0x00, // input buffer (starts after the first 32 bytes in the `data` array)
                0x04, // input length (loaded from the first 32 bytes in the `data` array)
                0x00, // output buffer
                0x00 // output length
            )
        }
        ///@notice return the opposite of success, meaning if the call succeeded, the address is univ3, and we should
        ///@notice indicate that lpIsNotUniV3 is false
        return !success;
    }

    /// @notice Helper function to get all v2/v3 spot prices on a token pair.
    /// @param token0 - Address of token0.
    /// @param token1 - Address of token1.
    /// @param FEE - The Uniswap V3 pool fee on the token pair.
    /// @return prices - SpotReserve array holding the reserves and spot prices across all dexes.
    /// @return lps - Pool address's on the token pair across all dexes.
    function getAllPrices(
        address token0,
        address token1,
        uint24 FEE
    ) public view returns (SpotReserve[] memory prices, address[] memory lps) {
        ///@notice Check if the token address' are identical.
        if (token0 != token1) {
            ///@notice Initialize SpotReserve and lp arrays of lenth dexes.length
            SpotReserve[] memory _spotPrices = new SpotReserve[](dexes.length);
            address[] memory _lps = new address[](dexes.length);

            ///@notice Iterate through Dexs in dexes and check if isUniV2.
            for (uint256 i = 0; i < dexes.length; ) {
                if (dexes[i].isUniV2) {
                    {
                        ///@notice Get the Uniswap v2 spot price and lp address.
                        (
                            SpotReserve memory spotPrice,
                            address poolAddress
                        ) = _calculateV2SpotPrice(
                                token0,
                                token1,
                                dexes[i].factoryAddress
                            );
                        ///@notice Set SpotReserve and lp values if the returned values are not null.
                        if (spotPrice.spotPrice != 0) {
                            _spotPrices[i] = spotPrice;
                            _lps[i] = poolAddress;
                        }
                    }
                } else {
                    {
                        {
                            ///@notice Get the Uniswap v2 spot price and lp address.
                            (
                                SpotReserve memory spotPrice,
                                address poolAddress
                            ) = _calculateV3SpotPrice(
                                    token0,
                                    token1,
                                    FEE,
                                    dexes[i].factoryAddress
                                );

                            ///@notice Set SpotReserve and lp values if the returned values are not null.
                            if (spotPrice.spotPrice != 0) {
                                _lps[i] = poolAddress;
                                _spotPrices[i] = spotPrice;
                            }
                        }
                    }
                }

                unchecked {
                    ++i;
                }
            }

            return (_spotPrices, _lps);
        } else {
            SpotReserve[] memory _spotPrices = new SpotReserve[](dexes.length);
            address[] memory _lps = new address[](dexes.length);
            return (_spotPrices, _lps);
        }
    }
}