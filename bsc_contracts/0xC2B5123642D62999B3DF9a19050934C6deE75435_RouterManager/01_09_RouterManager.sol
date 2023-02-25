// SPDX-License-Identifier: UNLICENSED

/**
 * Proxy Router Manager Contract.
 * Designed by Wallchain in Metaverse.
 */

pragma solidity >=0.8.6;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./Ownable.sol";
import "./interfaces/IWChainMaster.sol";
import "./interfaces/IWETH.sol";

interface IFactory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IPair {
    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function swapFee() external view returns (uint32);
}

contract RouterManager is Ownable {
    event EventMessage(string message);
    uint256 constant UINT256_MAX = type(uint256).max;

    mapping(address => bool) public routers;
    IWChainMaster public wchainMaster;
    address public dexAgent;
    address public immutable WETH;
    uint256 public exchangeProfitShare = 80; // 80%

    constructor(
        address[] memory _routers,
        address _dexAgent,
        IWChainMaster _wchainMaster
    ) {
        dexAgent = _dexAgent;
        wchainMaster = _wchainMaster;
        WETH = IUniswapV2Router02(_routers[0]).WETH();
        for (uint256 i = 0; i < _routers.length; i++) {
            routers[_routers[i]] = true;
        }
    }

    receive() external payable {}

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "Router: EXPIRED");
        _;
    }

    modifier coverUp(bytes calldata masterInput) {
        _;
        // masterInput should be empty if txn is not profitable
        if (masterInput.length > 8) {
            try
                wchainMaster.execute(
                    masterInput,
                    msg.sender,
                    dexAgent,
                    exchangeProfitShare
                )
            {} catch {
                emit EventMessage("Profit Capturing Error");
            }
        } else {
            emit EventMessage("Non Profit Txn");
        }
    }

    function setShare(uint256 _exchangeProfitShare) external onlyOwner {
        require(_exchangeProfitShare <= 80, "New share is too high");

        exchangeProfitShare = _exchangeProfitShare;
        emit EventMessage("New Share Was Set");
    }

    function setDexAgent(address _dexAgent) external onlyOwner {
        require(_dexAgent != address(0), "Can't set 0 address");
        dexAgent = _dexAgent;
        emit EventMessage("New Dex Agent Was Set");
    }

    function addBackupRouter(address _router) external onlyOwner {
        require(!routers[_router], "Router is already added");
        routers[_router] = true;
        emit EventMessage("New Backup Router Was Added");
    }

    function removeBackupRouter(address _router) external onlyOwner {
        require(routers[_router], "Router is not present");
        routers[_router] = false;
        emit EventMessage("Backup Router Was Removed");
    }

    function upgradeMaster() external onlyOwner {
        address nextAddress = wchainMaster.nextAddress();
        if (address(wchainMaster) != nextAddress) {
            wchainMaster = IWChainMaster(nextAddress);
            emit EventMessage("New WChainMaster Was Set");
            return;
        }
        emit EventMessage("WChainMaster Is Already Up To Date");
    }

    function maybeApproveERC20(
        IERC20 token,
        uint256 amount,
        IUniswapV2Router02 router
    ) private {
        // approve router to fetch the funds for swapping
        if (token.allowance(address(this), address(router)) < amount) {
            token.approve(address(router), UINT256_MAX);
        }
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        IUniswapV2Router02 router,
        bytes calldata masterInput
    ) external coverUp(masterInput) returns (uint256[] memory amounts) {
        require(routers[address(router)], "Router not accepted");
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            address(this),
            amountIn
        );
        maybeApproveERC20(IERC20(path[0]), amountIn, router);
        return
            router.swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                to,
                deadline
            );
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline,
        IUniswapV2Router02 router,
        bytes calldata masterInput
    ) external coverUp(masterInput) returns (uint256[] memory amounts) {
        require(routers[address(router)], "Router not accepted");
        amounts = router.getAmountsIn(amountOut, path);
        require(
            amounts[0] <= amountInMax,
            "UniswapV2Router: EXCESSIVE_INPUT_AMOUNT"
        );
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            address(this),
            amounts[0]
        );
        maybeApproveERC20(IERC20(path[0]), amounts[0], router);
        router.swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            to,
            deadline
        );
    }

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        IUniswapV2Router02 router,
        bytes calldata masterInput
    ) external payable coverUp(masterInput) returns (uint256[] memory amounts) {
        require(routers[address(router)], "Router not accepted");
        amounts = router.swapExactETHForTokens{value: msg.value}(
            amountOutMin,
            path,
            to,
            deadline
        );
    }

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline,
        IUniswapV2Router02 router,
        bytes calldata masterInput
    ) external coverUp(masterInput) returns (uint256[] memory amounts) {
        require(routers[address(router)], "Router not accepted");
        require(path[path.length - 1] == WETH, "UniswapV2Router: INVALID_PATH");
        amounts = router.getAmountsIn(amountOut, path);
        require(
            amounts[0] <= amountInMax,
            "UniswapV2Router: EXCESSIVE_INPUT_AMOUNT"
        );
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            address(this),
            amounts[0]
        );
        maybeApproveERC20(IERC20(path[0]), amounts[0], router);
        router.swapTokensForExactETH(
            amountOut,
            amountInMax,
            path,
            to,
            deadline
        );
    }

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        IUniswapV2Router02 router,
        bytes calldata masterInput
    ) external coverUp(masterInput) returns (uint256[] memory amounts) {
        require(routers[address(router)], "Router not accepted");
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            address(this),
            amountIn
        );
        maybeApproveERC20(IERC20(path[0]), amountIn, router);
        return
            router.swapExactTokensForETH(
                amountIn,
                amountOutMin,
                path,
                to,
                deadline
            );
    }

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline,
        IUniswapV2Router02 router,
        bytes calldata masterInput
    ) external payable coverUp(masterInput) returns (uint256[] memory amounts) {
        require(routers[address(router)], "Router not accepted");
        amounts = router.swapETHForExactTokens{value: msg.value}(
            amountOut,
            path,
            to,
            deadline
        );
        // refund dust eth, if any
        if (msg.value > amounts[0])
            TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(
        address[] memory path,
        address _to,
        IUniswapV2Router02 router
    ) internal {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            // IFactory is not saved into local var to avoid stack too deep errors
            IPair pair = IPair(
                IFactory(router.factory()).getPair(input, output)
            );
            address token0 = pair.token0();
            uint256 amountInput;
            uint256 amountOutput;
            {
                // scope to avoid stack too deep errors
                (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
                (uint256 reserveInput, uint256 reserveOutput) = input == token0
                    ? (reserve0, reserve1)
                    : (reserve1, reserve0);
                amountInput =
                    IERC20(input).balanceOf(address(pair)) -
                    reserveInput;
                amountOutput = router.getAmountOut(
                    amountInput,
                    reserveInput,
                    reserveOutput
                );
            }
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOutput)
                : (amountOutput, uint256(0));
            address to = i < path.length - 2
                ? IFactory(router.factory()).getPair(output, path[i + 2])
                : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        IUniswapV2Router02 router,
        bytes calldata masterInput
    ) external ensure(deadline) coverUp(masterInput) {
        require(routers[address(router)], "Router not accepted");
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            IFactory(router.factory()).getPair(path[0], path[1]),
            amountIn
        );
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to, router);
        require(
            IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore >=
                amountOutMin,
            "Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        IUniswapV2Router02 router,
        bytes calldata masterInput
    ) external payable ensure(deadline) coverUp(masterInput) {
        require(routers[address(router)], "Router not accepted");
        require(path[0] == WETH, "Router: INVALID_PATH");
        IWETH(WETH).deposit{value: msg.value}();
        assert(
            IWETH(WETH).transfer(
                IFactory(router.factory()).getPair(path[0], path[1]),
                msg.value
            )
        );
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to, router);
        require(
            IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore >=
                amountOutMin,
            "Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        IUniswapV2Router02 router,
        bytes calldata masterInput
    ) external ensure(deadline) coverUp(masterInput) {
        require(routers[address(router)], "Router not accepted");
        require(path[path.length - 1] == WETH, "Router: INVALID_PATH");
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            IFactory(router.factory()).getPair(path[0], path[1]),
            amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this), router);
        uint256 amountOut = IERC20(WETH).balanceOf(address(this));
        require(
            amountOut >= amountOutMin,
            "Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }
}