// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "../interfaces/IAntfarmRouter.sol";
import "../interfaces/IAntfarmPair.sol";
import "../interfaces/IAntfarmFactory.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IWETH.sol";
import "../libraries/TransferHelper.sol";
import "./AntfarmOracle.sol";
import "../utils/AntfarmRouterErrors.sol";

/// @title Antfarm Router for AntFarmPair
/// @notice High-level contract that serves as the entrypoint for swapping
contract AntfarmRouter is IAntfarmRouter {
    address public immutable factory;
    address public immutable WETH;
    address public immutable antfarmToken;

    modifier ensure(uint256 deadline) {
        if (deadline < block.timestamp) revert Expired();
        _;
    }

    constructor(
        address _factory,
        address _WETH,
        address _antfarmToken
    ) {
        require(_factory != address(0), "NULL_FACTORY_ADDRESS");
        require(_WETH != address(0), "NULL_WETH_ADDRESS");
        require(_antfarmToken != address(0), "NULL_ATF_ADDRESS");
        factory = _factory;
        WETH = _WETH;
        antfarmToken = _antfarmToken;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    /// @notice Swaps an exact amount of input tokens for as many output tokens as possible
    /// @param params The parameters necessary for the swap, encoded as `swapExactTokensForTokensParams` in calldata
    // @param amountIn The amount of input tokens to send
    // @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert
    // @param maxFee Maximum fees to be paid
    // @param path An array of token addresses
    // @param fees Associated fee for each two token addresses within the path
    // @param to Recipient of the output tokens
    // @param deadline Unix timestamp after which the transaction will revert
    /// @return amounts The input token amount and all subsequent output token amounts
    function swapExactTokensForTokens(
        swapExactTokensForTokensParams calldata params
    )
        external
        virtual
        ensure(params.deadline)
        returns (uint256[] memory amounts)
    {
        uint256 amountIn = params.path[0] == antfarmToken
            ? (params.amountIn * (1000 + params.fees[0])) / 1000
            : params.amountIn;
        amounts = getAmountsOut(amountIn, params.path, params.fees);
        if (amounts[amounts.length - 1] < params.amountOutMin) {
            revert InsufficientOutputAmount();
        }
        TransferHelper.safeTransferFrom(
            params.path[0],
            msg.sender,
            pairFor(params.path[0], params.path[1], params.fees[0]),
            amounts[0]
        );
        if (
            _swap(amounts, params.path, params.fees, params.to) > params.maxFee
        ) {
            revert InsufficientMaxFee();
        }
    }

    /// @notice Receive an exact amount of output tokens for as few input tokens as possible
    /// @param params The parameters necessary for the swap, encoded as `swapTokensForExactTokensParams` in calldata
    // @param amountOut The amount of output tokens to receive
    // @param amountInMax The maximum amount of input tokens that can be required before the transaction reverts
    // @param maxFee Maximum fees to be paid
    // @param path An array of token addresses
    // @param fees Associated fee for each two token addresses within the path
    // @param to Recipient of the output tokens
    // @param deadline Unix timestamp after which the transaction will revert
    /// @return amounts The input token amount and all subsequent output token amounts
    function swapTokensForExactTokens(
        swapTokensForExactTokensParams calldata params
    )
        external
        virtual
        ensure(params.deadline)
        returns (uint256[] memory amounts)
    {
        uint256 amountInMax = params.path[0] == antfarmToken
            ? (params.amountInMax * (1000 + params.fees[0])) / 1000
            : params.amountInMax;
        amounts = getAmountsIn(params.amountOut, params.path, params.fees);
        if (amounts[0] > amountInMax) revert ExcessiveInputAmount();
        TransferHelper.safeTransferFrom(
            params.path[0],
            msg.sender,
            pairFor(params.path[0], params.path[1], params.fees[0]),
            amounts[0]
        );
        if (
            _swap(amounts, params.path, params.fees, params.to) > params.maxFee
        ) {
            revert InsufficientMaxFee();
        }
    }

    /// @notice Swaps an exact amount of ETH for as many output tokens as possible
    /// @param params The parameters necessary for the swap, encoded as `swapExactETHForTokensParams` in calldata
    // @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert
    // @param maxFee Maximum fees to be paid
    // @param path An array of token addresses
    // @param fees Associated fee for each two token addresses within the path
    // @param to Recipient of the output tokens
    // @param deadline Unix timestamp after which the transaction will revert
    /// @return amounts The input token amount and all subsequent output token amounts
    function swapExactETHForTokens(swapExactETHForTokensParams calldata params)
        external
        payable
        virtual
        ensure(params.deadline)
        returns (uint256[] memory amounts)
    {
        if (params.path[0] != WETH) revert InvalidPath();
        amounts = getAmountsOut(msg.value, params.path, params.fees);
        if (amounts[amounts.length - 1] < params.amountOutMin) {
            revert InsufficientOutputAmount();
        }
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(
            IWETH(WETH).transfer(
                pairFor(params.path[0], params.path[1], params.fees[0]),
                amounts[0]
            )
        );
        if (
            _swap(amounts, params.path, params.fees, params.to) > params.maxFee
        ) {
            revert InsufficientMaxFee();
        }
    }

    /// @notice Receive an exact amount of ETH for as few input tokens as possible
    /// @param params The parameters necessary for the swap, encoded as `swapTokensForExactETHParams` in calldata
    // @param amountOut The amount of ETH to receive
    // @param amountInMax The maximum amount of input tokens that can be required before the transaction reverts
    // @param maxFee Maximum fees to be paid
    // @param path An array of token addresses
    // @param fees Associated fee for each two token addresses within the path
    // @param to Recipient of the output tokens
    // @param deadline Unix timestamp after which the transaction will revert
    /// @return amounts The input token amount and all subsequent output token amounts
    function swapTokensForExactETH(swapTokensForExactETHParams calldata params)
        external
        virtual
        ensure(params.deadline)
        returns (uint256[] memory amounts)
    {
        if (params.path[params.path.length - 1] != WETH) revert InvalidPath();
        uint256 amountInMax = params.path[0] == antfarmToken
            ? (params.amountInMax * (1000 + params.fees[0])) / 1000
            : params.amountInMax;
        amounts = getAmountsIn(params.amountOut, params.path, params.fees);
        if (amounts[0] > amountInMax) revert ExcessiveInputAmount();
        TransferHelper.safeTransferFrom(
            params.path[0],
            msg.sender,
            pairFor(params.path[0], params.path[1], params.fees[0]),
            amounts[0]
        );
        if (
            _swap(amounts, params.path, params.fees, address(this)) >
            params.maxFee
        ) {
            revert InsufficientMaxFee();
        }
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(params.to, amounts[amounts.length - 1]);
    }

    /// @notice Swaps an exact amount of tokens for as much ETH as possible
    /// @param params The parameters necessary for the swap, encoded as `swapExactTokensForETHParams` in calldata
    // @param amountIn The amount of input tokens to send
    // @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert
    // @param maxFee Maximum fees to be paid
    // @param path An array of token addresses
    // @param fees Associated fee for each two token addresses within the path
    // @param to Recipient of the output tokens
    // @param deadline Unix timestamp after which the transaction will revert
    /// @return amounts The input token amount and all subsequent output token amounts
    function swapExactTokensForETH(swapExactTokensForETHParams calldata params)
        external
        virtual
        ensure(params.deadline)
        returns (uint256[] memory amounts)
    {
        uint256 amountIn = params.path[0] == antfarmToken
            ? (params.amountIn * (1000 + params.fees[0])) / 1000
            : params.amountIn;
        if (params.path[params.path.length - 1] != WETH) revert InvalidPath();
        amounts = getAmountsOut(amountIn, params.path, params.fees);
        if (amounts[amounts.length - 1] < params.amountOutMin) {
            revert InsufficientOutputAmount();
        }
        TransferHelper.safeTransferFrom(
            params.path[0],
            msg.sender,
            pairFor(params.path[0], params.path[1], params.fees[0]),
            amounts[0]
        );
        if (
            _swap(amounts, params.path, params.fees, address(this)) >
            params.maxFee
        ) {
            revert InsufficientMaxFee();
        }
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(params.to, amounts[amounts.length - 1]);
    }

    /// @notice Receive an exact amount of tokens for as little ETH as possible
    /// @param params The parameters necessary for the swap, encoded as `swapETHForExactTokensParams` in calldata
    // @param amountOut The amount of tokens to receive
    // @param maxFee Maximum fees to be paid
    // @param path An array of token addresses
    // @param fees Associated fee for each two token addresses within the path
    // @param to Recipient of the output tokens
    // @param deadline Unix timestamp after which the transaction will revert
    /// @return amounts The input token amount and all subsequent output token amounts
    function swapETHForExactTokens(swapETHForExactTokensParams calldata params)
        external
        payable
        virtual
        ensure(params.deadline)
        returns (uint256[] memory amounts)
    {
        if (params.path[0] != WETH) revert InvalidPath();
        amounts = getAmountsIn(params.amountOut, params.path, params.fees);
        if (amounts[0] > msg.value) revert ExcessiveInputAmount();
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(
            IWETH(WETH).transfer(
                pairFor(params.path[0], params.path[1], params.fees[0]),
                amounts[0]
            )
        );
        if (
            _swap(amounts, params.path, params.fees, params.to) > params.maxFee
        ) {
            revert InsufficientMaxFee();
        }
        // refund dust ETH if any
        if (msg.value > amounts[0])
            TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    /// @notice Identical to swapExactTokensForTokens, but succeeds for tokens that take a fee on transfer
    /// @param params The parameters necessary for the swap, encoded as `swapExactTokensForTokensParams` in calldata
    // @param amountIn The amount of input tokens to send
    // @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert
    // @param path An array of token addresses
    // @param fees Associated fee for each two token addresses within the path
    // @param to Recipient of the output tokens
    // @param deadline Unix timestamp after which the transaction will revert
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        swapExactTokensForTokensParams calldata params
    ) external virtual ensure(params.deadline) {
        TransferHelper.safeTransferFrom(
            params.path[0],
            msg.sender,
            pairFor(params.path[0], params.path[1], params.fees[0]),
            params.amountIn
        );
        uint256 balanceBefore = IERC20(params.path[params.path.length - 1])
            .balanceOf(params.to);
        swapParams memory sParams = swapParams(
            params.path,
            params.fees,
            params.to
        );
        if (_swapSupportingFeeOnTransferTokens(sParams) > params.maxFee) {
            revert InsufficientMaxFee();
        }
        if (
            IERC20(params.path[params.path.length - 1]).balanceOf(params.to) -
                balanceBefore <
            params.amountOutMin
        ) {
            revert InsufficientOutputAmount();
        }
    }

    /// @notice Identical to swapExactETHForTokens, but succeeds for tokens that take a fee on transfer
    /// @param params The parameters necessary for the swap, encoded as `swapExactETHForTokensParams` in calldata
    // @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert
    // @param path An array of token addresses
    // @param fees Associated fee for each two token addresses within the path
    // @param to Recipient of the output tokens
    // @param deadline Unix timestamp after which the transaction will revert
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        swapExactETHForTokensParams calldata params
    ) external payable virtual ensure(params.deadline) {
        if (params.path[0] != WETH) revert InvalidPath();
        uint256 amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        assert(
            IWETH(WETH).transfer(
                pairFor(params.path[0], params.path[1], params.fees[0]),
                amountIn
            )
        );
        uint256 balanceBefore = IERC20(params.path[params.path.length - 1])
            .balanceOf(params.to);
        swapParams memory sParams = swapParams(
            params.path,
            params.fees,
            params.to
        );
        if (_swapSupportingFeeOnTransferTokens(sParams) > params.maxFee) {
            revert InsufficientMaxFee();
        }
        if (
            IERC20(params.path[params.path.length - 1]).balanceOf(params.to) -
                balanceBefore <
            params.amountOutMin
        ) {
            revert InsufficientOutputAmount();
        }
    }

    /// @notice Identical to swapExactTokensForETH, but succeeds for tokens that take a fee on transfer
    /// @param params The parameters necessary for the swap, encoded as `swapExactTokensForETHParams` in calldata
    // @param amountIn The amount of input tokens to send
    // @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert
    // @param path An array of token addresses
    // @param fees Associated fee for each two token addresses within the path
    // @param to Recipient of the output tokens
    // @param deadline Unix timestamp after which the transaction will revert
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        swapExactTokensForETHParams calldata params
    ) external virtual ensure(params.deadline) {
        if (params.path[params.path.length - 1] != WETH) revert InvalidPath();
        TransferHelper.safeTransferFrom(
            params.path[0],
            msg.sender,
            pairFor(params.path[0], params.path[1], params.fees[0]),
            params.amountIn
        );
        swapParams memory sParams = swapParams(
            params.path,
            params.fees,
            address(this)
        );
        if (_swapSupportingFeeOnTransferTokens(sParams) > params.maxFee) {
            revert InsufficientMaxFee();
        }
        uint256 amountOut = IERC20(WETH).balanceOf(address(this));
        if (amountOut < params.amountOutMin) revert InsufficientOutputAmount();
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(params.to, amountOut);
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address tokenA,
        address tokenB,
        uint16 fee
    ) public view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IAntfarmPair(
            pairFor(tokenA, tokenB, fee)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // SWAP
    // requires the initial amount to have already been sent to the first pair
    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        uint16[] memory fees,
        address _to
    ) internal virtual returns (uint256 totalFee) {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            uint16 fee = fees[i];
            IAntfarmPair antfarmPair = IAntfarmPair(
                pairFor(input, output, fee)
            );

            (address token0, ) = sortTokens(input, output);
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amounts[i + 1])
                : (amounts[i + 1], uint256(0));

            {
                uint256 amountIn = amounts[i];

                if (input == antfarmToken) {
                    totalFee = totalFee + ((amountIn * fee) / (1000 + fee));
                } else if (output == antfarmToken) {
                    totalFee =
                        totalFee +
                        ((amounts[i + 1] * fee) / (1000 - fee));
                } else {
                    uint256 feeToPay = antfarmPair.getFees(
                        amount0Out,
                        input == token0 ? amountIn : uint256(0),
                        amount1Out,
                        input == token0 ? uint256(0) : amountIn
                    );

                    TransferHelper.safeTransferFrom(
                        antfarmToken,
                        msg.sender,
                        address(antfarmPair),
                        feeToPay
                    );

                    totalFee = totalFee + feeToPay;
                }
            }

            address to = i < path.length - 2
                ? pairFor(output, path[i + 2], fees[i + 1])
                : _to;
            antfarmPair.swap(amount0Out, amount1Out, to);
        }
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    function _swapSupportingFeeOnTransferTokens(swapParams memory sParams)
        internal
        virtual
        returns (uint256 totalFee)
    {
        for (uint256 i; i < sParams.path.length - 1; i++) {
            (address input, address output) = (
                sParams.path[i],
                sParams.path[i + 1]
            );
            uint16 fee = sParams.fees[i];
            IAntfarmPair antfarmPair = IAntfarmPair(
                pairFor(input, output, fee)
            );

            (address token0, ) = sortTokens(input, output);

            uint256 amountIn;
            uint256 amountOut;
            {
                (uint256 reserve0, uint256 reserve1, ) = antfarmPair
                    .getReserves();
                (uint256 reserveIn, uint256 reserveOut) = input == token0
                    ? (reserve0, reserve1)
                    : (reserve1, reserve0);

                amountIn =
                    IERC20(input).balanceOf(address(antfarmPair)) -
                    reserveIn;

                if (input == antfarmToken) {
                    amountOut = getAmountOut(
                        (amountIn * 1000) / (1000 + fee),
                        reserveIn,
                        reserveOut
                    );
                } else if (output == antfarmToken) {
                    amountOut =
                        (getAmountOut(amountIn, reserveIn, reserveOut) *
                            (1000 - fee)) /
                        1000;
                } else {
                    amountOut = getAmountOut(amountIn, reserveIn, reserveOut);
                }
            }

            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));

            if (input == antfarmToken) {
                totalFee = totalFee + ((amountIn * fee) / (1000 + fee));
            } else if (output == antfarmToken) {
                totalFee = totalFee + ((amountIn * fee) / 1000);
            } else {
                uint256 feeToPay = antfarmPair.getFees(
                    amount0Out,
                    input == token0 ? amountIn : uint256(0),
                    amount1Out,
                    input == token0 ? uint256(0) : amountIn
                );

                TransferHelper.safeTransferFrom(
                    antfarmToken,
                    msg.sender,
                    address(antfarmPair),
                    feeToPay
                );

                totalFee = totalFee + feeToPay;
            }

            address to = i < sParams.path.length - 2
                ? pairFor(output, sParams.path[i + 2], sParams.fees[i + 1])
                : sParams.to;
            antfarmPair.swap(amount0Out, amount1Out, to);
        }
    }

    // **** LIBRARY FUNCTIONS ADDED INTO THE CONTRACT ****
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        view
        returns (address token0, address token1)
    {
        if (tokenA == tokenB) revert IdenticalAddresses();
        if (tokenA == antfarmToken || tokenB == antfarmToken) {
            (token0, token1) = tokenA == antfarmToken
                ? (antfarmToken, tokenB)
                : (antfarmToken, tokenA);
            if (token1 == address(0)) revert ZeroAddress();
        } else {
            (token0, token1) = tokenA < tokenB
                ? (tokenA, tokenB)
                : (tokenB, tokenA);
            if (token0 == address(0)) revert ZeroAddress();
        }
    }

    /// @notice Calculates the CREATE2 address for a pair without making any external calls
    /// @param tokenA Token0 from the AntfarmPair
    /// @param tokenB Token1 from the AntfarmPair
    /// @param fee Associated fee to the AntfarmPair
    /// @return pair The CREATE2 address for the desired AntFarmPair
    function pairFor(
        address tokenA,
        address tokenB,
        uint16 fee
    ) internal view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(
                                abi.encodePacked(
                                    token0,
                                    token1,
                                    fee,
                                    antfarmToken
                                )
                            ),
                            token0 == antfarmToken
                                ? hex"b174de46ec9038ead3d74ed04c79d4885d8e642175833c4da037d5e052492e5b" // AtfPair init code hash
                                : hex"2f47d72b208014a5ba4f32371ac96dd421a39152dcaf104e8232b6c9f1a92280" // Pair init code hash
                        )
                    )
                )
            )
        );
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        uint256 amountIn,
        address[] memory path,
        uint16[] memory fees
    ) internal view returns (uint256[] memory) {
        if (path.length < 2) revert InvalidPath();
        uint256[] memory amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                path[i],
                path[i + 1],
                fees[i]
            );
            if (path[i] == antfarmToken) {
                amounts[i + 1] = getAmountOut(
                    (amounts[i] * 1000) / (1000 + fees[i]),
                    reserveIn,
                    reserveOut
                );
            } else if (path[i + 1] == antfarmToken) {
                amounts[i + 1] =
                    (getAmountOut(amounts[i], reserveIn, reserveOut) *
                        (1000 - fees[i])) /
                    1000;
            } else {
                amounts[i + 1] = getAmountOut(
                    amounts[i],
                    reserveIn,
                    reserveOut
                );
            }
        }
        return amounts;
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        uint256 amountOut,
        address[] memory path,
        uint16[] memory fees
    ) internal view returns (uint256[] memory) {
        if (path.length < 2) revert InvalidPath();
        uint256[] memory amounts = new uint256[](path.length);
        amounts[path.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                path[i - 1],
                path[i],
                fees[i - 1]
            );
            if (path[i - 1] == antfarmToken) {
                amounts[i - 1] =
                    (getAmountIn(amounts[i], reserveIn, reserveOut) *
                        (1000 + fees[i - 1])) /
                    1000;
            } else if (path[i] == antfarmToken) {
                amounts[i - 1] = getAmountIn(
                    (amounts[i] * 1000) / (1000 - fees[i - 1]),
                    reserveIn,
                    reserveOut
                );
            } else {
                amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
            }
        }
        return amounts;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256) {
        if (amountIn == 0) revert InsufficientInputAmount();
        if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();
        uint256 numerator = amountIn * reserveOut;
        uint256 denominator = reserveIn + amountIn;
        return numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256) {
        if (amountOut == 0) revert InsufficientOutputAmount();
        if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();
        uint256 numerator = reserveIn * amountOut;
        uint256 denominator = reserveOut - amountOut;
        return (numerator / denominator) + 1;
    }
}