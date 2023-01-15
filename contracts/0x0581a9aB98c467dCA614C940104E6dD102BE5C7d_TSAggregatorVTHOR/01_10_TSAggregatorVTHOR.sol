// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {SafeTransferLib} from "../lib/SafeTransferLib.sol";
import {TSAggregator} from "./TSAggregator.sol";
import {IThorchainRouter} from "./interfaces/IThorchainRouter.sol";
import {IUniswapRouterV2} from "./interfaces/IUniswapRouterV2.sol";

import {IERC20} from "./interfaces/IERC20.sol";
import {IERC4626} from "./interfaces/IERC4626.sol";

contract TSAggregatorVTHOR is TSAggregator {
    using SafeTransferLib for address;

    IERC20 public thor;
    IERC4626 public vthor;

    address public weth;
    IUniswapRouterV2 public swapRouter;

    constructor(
        address _thor,
        address _vthor,
        address _ttp,
        address _weth,
        address _swapRouter // sushiswap
    ) TSAggregator(_ttp) {
        thor = IERC20(_thor);
        vthor = IERC4626(_vthor);

        weth = _weth;
        swapRouter = IUniswapRouterV2(_swapRouter);
    }

    function sendFeesToStakers() public nonReentrant {
        address(thor).safeApprove(address(vthor), thor.balanceOf(address(this)));
        thor.transfer(address(vthor), thor.balanceOf(address(this)));
    }

    function redeemDeposit(
        address tcRouter,
        address tcVault,
        string calldata memo,
        uint256 shares,
        uint256 deadline
    ) public nonReentrant {
        uint256 thorAmount = vthor.redeem(shares, address(this), msg.sender);
        uint256 amountOut = skimFee(thorAmount);

        address(thor).safeApprove(address(tcRouter), amountOut);

        IThorchainRouter(tcRouter).depositWithExpiry{value: 0}(
            payable(tcVault),
            address(thor),
            amountOut,
            memo,
            deadline
        );
    }

    function redeemSwapEthDeposit(
        address tcRouter,
        address tcVault,
        string calldata memo,
        uint256 shares,
        uint256 amountOutMin,
        uint256 deadline
    ) public nonReentrant {
        uint256 thorAmount = vthor.redeem(shares, address(this), msg.sender);
        uint256 amountOut = skimFee(thorAmount);

        thor.approve(address(swapRouter), amountOut);

        address[] memory path = new address[](2);
        path[0] = address(thor);
        path[1] = weth;
        swapRouter.swapExactTokensForETH(
            amountOut,
            amountOutMin,
            path,
            address(this),
            deadline
        );

        IThorchainRouter(tcRouter).depositWithExpiry{value: address(this).balance}(
            payable(tcVault),
            address(0),
            amountOut,
            memo,
            deadline
        );
    }

    // swapOut from tcRouter and (swap)deposit for vTHOR
    function swapOut(
        address token, // not used now, could allow for more token staking in the future
        address to,
        uint256 amountOutMin
    ) public payable nonReentrant {
        // B. We receive ETH from the router: swap it for thor and stake
        // Can't get ERC20 transferOut from tcRouter...
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = address(thor);
        swapRouter.swapExactETHForTokens{value: msg.value}(
            _parseAmountOutMin(amountOutMin),
            path,
            to,
            type(uint256).max
        );

        address(thor).safeApprove(address(vthor), thor.balanceOf(address(this)));
        vthor.deposit(address(this).balance, to);
    }
}