// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../external/GNSPS-solidity-bytes-utils/BytesLib.sol";
import "../external/@openzeppelin/token/ERC20/utils/SafeERC20.sol";

import "../external/uniswap/interfaces/ISwapRouter02.sol";
import "../interfaces/ISwapData.sol";

/// @notice Denotes swap action mode
enum SwapAction {
    NONE,
    UNI_V2_DIRECT,
    UNI_V2_WETH,
    UNI_V2,
    UNI_V3_DIRECT,
    UNI_V3_WETH,
    UNI_V3
}

/// @title Contains logic facilitating swapping using Uniswap
abstract contract SwapHelperUniswap {
    using BytesLib for bytes;
    using SafeERC20 for IERC20;

    /// @dev The length of the bytes encoded swap action
    uint256 internal constant ACTION_SIZE = 1;

    /// @dev The length of the bytes encoded address
    uint256 internal constant ADDR_SIZE = 20;

    /// @dev The length of the bytes encoded fee
    uint256 internal constant FEE_SIZE = 3;

    /// @dev The offset of a single token address and pool fee
    uint256 internal constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;

    /// @dev Maximum V2 path length (4 swaps)
    uint256 internal constant MAX_V2_PATH = ADDR_SIZE * 3;

    /// @dev V3 WETH path length
    uint256 internal constant WETH_V3_PATH_SIZE = FEE_SIZE + FEE_SIZE;

    /// @dev Minimum V3 custom path length (2 swaps)
    uint256 internal constant MIN_V3_PATH = FEE_SIZE + NEXT_OFFSET;

    /// @dev Maximum V3 path length (4 swaps)
    uint256 internal constant MAX_V3_PATH = FEE_SIZE + NEXT_OFFSET * 3;

    /// @notice Uniswap router supporting Uniswap V2 and V3
    ISwapRouter02 internal immutable uniswapRouter;

    /// @notice Address of WETH token
    address private immutable WETH;

    /**
     * @notice Sets initial values
     * @param _uniswapRouter Uniswap router address
     * @param _WETH WETH token address
     */
    constructor(ISwapRouter02 _uniswapRouter, address _WETH) {
        uniswapRouter = _uniswapRouter;
        WETH = _WETH;
    }

    /**
     * @notice Approve reward token and swap the `amount` to a strategy underlying asset
     * @param from Token to swap from
     * @param to Token to swap to
     * @param amount Amount of tokens to swap
     * @param swapData Swap details showing the path of the swap
     * @return result Amount of underlying (`to`) tokens recieved
     */
    function _approveAndSwapUniswap(
        IERC20 from,
        IERC20 to,
        uint256 amount,
        SwapData calldata swapData
    ) internal virtual returns (uint256) {

        // if there is nothing to swap, return
        if(amount == 0)
            return 0;

        // if amount is not uint256 max approve unswap router to spend tokens
        // otherwise rewards were already sent to the router
        if(amount < type(uint256).max) {
            from.safeApprove(address(uniswapRouter), amount);
        } else {
            amount = 0;
        }

        // get swap action from first byte
        SwapAction action = SwapAction(swapData.path.toUint8(0));
        uint256 result;

        if (action == SwapAction.UNI_V2_DIRECT) { // V2 Direct
            address[] memory path = new address[](2);
            result = _swapV2(from, to, amount, swapData.slippage, path);
        } else if (action == SwapAction.UNI_V2_WETH) { // V2 WETH
            address[] memory path = new address[](3);
            path[1] = WETH;
            result = _swapV2(from, to, amount, swapData.slippage, path);
        } else if (action == SwapAction.UNI_V2) { // V2 Custom
            address[] memory path = _getV2Path(swapData.path);
            result = _swapV2(from, to, amount, swapData.slippage, path);
        } else if (action == SwapAction.UNI_V3_DIRECT) { // V3 Direct
            result = _swapDirectV3(from, to, amount, swapData.slippage, swapData.path);
        } else if (action == SwapAction.UNI_V3_WETH) { // V3 WETH
            bytes memory wethPath = _getV3WethPath(swapData.path);
            result = _swapV3(from, to, amount, swapData.slippage, wethPath);
        } else if (action == SwapAction.UNI_V3) { // V3 Custom
            require(swapData.path.length > MIN_V3_PATH, "SwapHelper::_approveAndSwap: Path too short");
            uint256 actualpathSize = swapData.path.length - ACTION_SIZE;
            require((actualpathSize - FEE_SIZE) % NEXT_OFFSET == 0 &&
                actualpathSize <= MAX_V3_PATH,
                "SwapHelper::_approveAndSwap: Bad V3 path");

            result = _swapV3(from, to, amount, swapData.slippage, swapData.path[ACTION_SIZE:]);
        } else {
            revert("SwapHelper::_approveAndSwap: No action");
        }

        if (from.allowance(address(this), address(uniswapRouter)) > 0) {
            from.safeApprove(address(uniswapRouter), 0);
        }
        return result;
    }

    /**
     * @notice Swaps tokens using Uniswap V2
     * @param from Token to swap from
     * @param to Token to swap to
     * @param amount Amount of tokens to swap
     * @param slippage Allowed slippage
     * @param path Steps to complete the swap
     * @return result Amount of underlying (`to`) tokens recieved
     */
    function _swapV2(
        IERC20 from,
        IERC20 to,
        uint256 amount,
        uint256 slippage,
        address[] memory path
    ) internal virtual returns (uint256) {
        path[0] = address(from);
        path[path.length - 1] = address(to);

        return uniswapRouter.swapExactTokensForTokens(
            amount,
            slippage,
            path,
            address(this)
        );
    }

    /**
     * @notice Swaps tokens using Uniswap V3
     * @param from Token to swap from
     * @param to Token to swap to
     * @param amount Amount of tokens to swap
     * @param slippage Allowed slippage
     * @param path Steps to complete the swap
     * @return result Amount of underlying (`to`) tokens recieved
     */
    function _swapV3(
        IERC20 from,
        IERC20 to,
        uint256 amount,
        uint256 slippage,
        bytes memory path
    ) internal virtual returns (uint256) {
        IV3SwapRouter.ExactInputParams memory params =
            IV3SwapRouter.ExactInputParams({
                path: abi.encodePacked(address(from), path, address(to)),
                recipient: address(this),
                amountIn: amount,
                amountOutMinimum: slippage
            });

        // Executes the swap.
        uint received = uniswapRouter.exactInput(params);

        return received;
    }

    /**
     * @notice Does a direct swap from `from` address to the `to` address using Uniswap V3
     * @param from Token to swap from
     * @param to Token to swap to
     * @param amount Amount of tokens to swap
     * @param slippage Allowed slippage
     * @param fee V3 direct fee configuration
     * @return result Amount of underlying (`to`) tokens recieved
     */
    function _swapDirectV3(
        IERC20 from,
        IERC20 to,
        uint256 amount,
        uint256 slippage,
        bytes memory fee
    ) internal virtual returns (uint256) {
        require(fee.length == FEE_SIZE + ACTION_SIZE, "SwapHelper::_swapDirectV3: Bad V3 direct fee");

        IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter.ExactInputSingleParams(
            address(from),
            address(to),
            // ignore first byte
            fee.toUint24(ACTION_SIZE),
            address(this),
            amount,
            slippage,
            0
        );

        return uniswapRouter.exactInputSingle(params);
    }

    /**
     * @notice Converts passed bytes to V2 path
     * @param pathBytes Swap path in bytes, converted to addresses
     * @return path list of addresses in the swap path (skipping first and last element)
     */
    function _getV2Path(bytes calldata pathBytes) internal pure returns(address[] memory) {
        require(pathBytes.length > ACTION_SIZE, "SwapHelper::_getV2Path: No path provided");
        uint256 actualpathSize = pathBytes.length - ACTION_SIZE;
        require(actualpathSize % ADDR_SIZE == 0 && actualpathSize <= MAX_V2_PATH, "SwapHelper::_getV2Path: Bad V2 path");

        uint256 pathLength = actualpathSize / ADDR_SIZE;
        address[] memory path = new address[](pathLength + 2);

        // ignore first byte
        path[1] = pathBytes.toAddress(ACTION_SIZE);
        for (uint256 i = 1; i < pathLength; i++) {
            path[i + 1] = pathBytes.toAddress(i * ADDR_SIZE + ACTION_SIZE);
        }

        return path;
    }

    /**
     * @notice Get Unswap V3 path to swap tokens via WETH LP pool
     * @param pathBytes Swap path in bytes
     * @return wethPath Unswap V3 path routing via WETH pool
     */
    function _getV3WethPath(bytes calldata pathBytes) internal view returns(bytes memory) {
        require(pathBytes.length == WETH_V3_PATH_SIZE + ACTION_SIZE, "SwapHelper::_getV3WethPath: Bad V3 WETH path");
        // ignore first byte as it's used for swap action
        return abi.encodePacked(pathBytes[ACTION_SIZE:4], WETH, pathBytes[4:]);
    }
}