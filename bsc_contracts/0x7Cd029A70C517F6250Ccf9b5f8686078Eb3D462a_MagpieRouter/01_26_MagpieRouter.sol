// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/balancer-v2/IVault.sol";
import "./interfaces/uniswap-v2/IUniswapV2Router02.sol";
import "./interfaces/uniswap-v3/IUniswapV3Router.sol";
import "./interfaces/IMagpieCurveRouter.sol";
import "./lib/LibAsset.sol";
import "./lib/LibBytes.sol";
import "./lib/LibSwap.sol";
import "./interfaces/IWETH.sol";

contract MagpieRouter is ReentrancyGuard, Ownable, IMagpieRouter {
    using LibSwap for IMagpieRouter.SwapArgs;
    using LibAsset for address;
    using LibBytes for bytes;
    address public magpieCoreAddress;
    address public magpieSimulatorAddress;

    mapping(uint16 => Amm) private amms;

    modifier onlyMagpieCoreOrSimulator() {
        require(msg.sender == magpieCoreAddress || msg.sender == magpieSimulatorAddress, "MagpieRouter: only MagpieCore or MagpieSimulator allowed");
        _;
    }

    function updateMagpieCore(address _magpieCoreAddress) external override onlyOwner {
        magpieCoreAddress = _magpieCoreAddress;
    }

    function updateMagpieSimulator(address _magpieSimulatorAddress) external override onlyOwner {
        magpieSimulatorAddress = _magpieSimulatorAddress;
    }

    function updateAmms(Amm[] calldata _amms) external override onlyOwner {
        require(_amms.length > 0, "MagpieRouter: invalid amms");
        for (uint256 i = 0; i < _amms.length; i++) {
            Amm memory amm = Amm({id: _amms[i].id, index: _amms[i].index, protocolIndex: _amms[i].protocolIndex});

            require(amm.id != address(0), "MagpieRouter: invalid amm address");
            require(amm.index > 0, "MagpieRouter: invalid amm index");
            require(amm.protocolIndex > 0, "MagpieRouter: invalid amm protocolIndex");

            amms[amm.index] = amm;
        }

        emit AmmsUpdated(_amms, msg.sender);
    }

    receive() external payable {}

    function withdraw(address weth, uint256 amount) external override onlyMagpieCoreOrSimulator {
        IWETH(weth).withdraw(amount);
        (bool success, ) = msg.sender.call{value: amount}(new bytes(0));
        require(success, "MagpieRouter: eth transfer failed");
    }

    function swap(SwapArgs memory swapArgs) external override onlyMagpieCoreOrSimulator returns (uint256[] memory amountOuts) {
        amountOuts = new uint256[](swapArgs.routes.length);
        address fromAssetAddress = swapArgs.getFromAssetAddress();
        address toAssetAddress = swapArgs.getToAssetAddress();
        uint256 startingBalance = toAssetAddress.getBalance();
        uint256 amountIn = swapArgs.getAmountIn();

        for (uint256 i = 0; i < swapArgs.routes.length; i++) {
            Route memory route = swapArgs.routes[i];
            Hop memory firstHop = route.hops[0];
            Hop memory lastHop = route.hops[route.hops.length - 1];
            require(fromAssetAddress == swapArgs.assets[firstHop.path[0]], "MagpieRouter: invalid fromAssetAddress");
            require(
                toAssetAddress == swapArgs.assets[lastHop.path[lastHop.path.length - 1]],
                "MagpieRouter: invalid toAssetAddress"
            );

            amountOuts[i] = _swapRoute(route, swapArgs.assets, swapArgs.deadline);
        }

        uint256 amountOut = 0;
        for (uint256 i = 0; i < amountOuts.length; i++) {
            amountOut += amountOuts[i];
        }

        if (fromAssetAddress == toAssetAddress) {
            startingBalance -= amountIn;
        }

        require(toAssetAddress.getBalance() == startingBalance + amountOut, "MagpieRouter: invalid amountOut");

        for (uint256 j = 0; j < swapArgs.assets.length; j++) {
            require(swapArgs.assets[j] != address(0), "MagpieRouter: invalid asset - address0");
        }

        require(amountOut >= swapArgs.amountOutMin, "MagpieRouter: insufficient output amount");

        if (msg.sender == magpieCoreAddress) {
            toAssetAddress.transfer(payable(msg.sender), amountOut);
        }
    }

    function _swapRoute(
        Route memory route,
        address[] memory assets,
        uint256 deadline
    ) private returns (uint256) {
        require(route.hops.length > 0, "MagpieRouter: invalid hop size");
        uint256 lastAmountOut = 0;

        for (uint256 i = 0; i < route.hops.length; i++) {
            uint256 amountIn = i == 0 ? route.amountIn : lastAmountOut;
            Hop memory hop = route.hops[i];
            address toAssetAddress = assets[hop.path[hop.path.length - 1]];
            uint256 beforeSwapBalance = toAssetAddress.getBalance();
            _swapHop(amountIn, hop, assets, deadline);
            uint256 afterSwapBalance = toAssetAddress.getBalance();
            lastAmountOut = afterSwapBalance - beforeSwapBalance;
        }

        return lastAmountOut;
    }

    function _swapHop(
        uint256 amountIn,
        Hop memory hop,
        address[] memory assets,
        uint256 deadline
    ) private {
        Amm memory amm = amms[hop.ammIndex];

        require(amm.id != address(0), "MagpieRouter: invalid amm");
        require(hop.path.length > 1, "MagpieRouter: invalid path size");
        address fromAssetAddress = assets[hop.path[0]];

        if (fromAssetAddress.getAllowance(address(this), amm.id) < amountIn) {
            fromAssetAddress.approve(amm.id, type(uint256).max);
        }

        if (amm.protocolIndex == 1) {
            _swapUniswapV2(amountIn, hop, assets, deadline);
        } else if (amm.protocolIndex == 2 || amm.protocolIndex == 3) {
            _swapBalancerV2(amountIn, hop, assets, deadline);
        } else if (amm.protocolIndex == 6) {
            _swapUniswapV3(amountIn, hop, assets, deadline);
        } else if (amm.protocolIndex == 4 || amm.protocolIndex == 5 || amm.protocolIndex == 7) {
            _swapCurve(amountIn, hop, assets);
        }
    }

    function _swapUniswapV2(
        uint256 amountIn,
        Hop memory hop,
        address[] memory assets,
        uint256 deadline
    ) private {
        Amm memory amm = amms[hop.ammIndex];
        address[] memory path = new address[](hop.path.length);
        for (uint256 i = 0; i < hop.path.length; i++) {
            path[i] = assets[hop.path[i]];
        }
        IUniswapV2Router02(amm.id).swapExactTokensForTokens(amountIn, 0, path, address(this), deadline);
    }

    function _swapUniswapV3(
        uint256 amountIn,
        Hop memory hop,
        address[] memory assets,
        uint256 deadline
    ) private {
        Amm memory amm = amms[hop.ammIndex];
        uint256 poolIdIndex = 0;
        bytes memory path;
        for (uint256 i = 0; i < hop.path.length; i++) {
            path = bytes.concat(path, abi.encodePacked(assets[hop.path[i]]));
            if (i < hop.path.length - 1) {
                path = bytes.concat(path, abi.encodePacked(hop.poolData.toUint24(poolIdIndex)));
                poolIdIndex += 3;
            }
        }
        require(hop.poolData.length == poolIdIndex, "MagpieRouter: poolData is invalid");

        IUniswapV3Router.ExactInputParams memory params = IUniswapV3Router.ExactInputParams(
            path,
            address(this),
            deadline,
            amountIn,
            0
        );
        IUniswapV3Router(amm.id).exactInput(params);
    }

    function _swapBalancerV2(
        uint256 amountIn,
        Hop memory hop,
        address[] memory assets,
        uint256 deadline
    ) private {
        Amm memory amm = amms[hop.ammIndex];
        IVault.BatchSwapStep[] memory swaps = new IVault.BatchSwapStep[](hop.path.length - 1);
        uint256 poolIdIndex = 0;
        IAsset[] memory balancerAssets = new IAsset[](hop.path.length);
        int256[] memory limits = new int256[](hop.path.length);
        for (uint256 i = 0; i < hop.path.length - 1; i++) {
            swaps[i] = IVault.BatchSwapStep({
                poolId: hop.poolData.toBytes32(poolIdIndex),
                assetInIndex: i,
                assetOutIndex: i + 1,
                amount: i == 0 ? amountIn : 0,
                userData: "0x"
            });
            poolIdIndex += 32;
            balancerAssets[i] = IAsset(assets[hop.path[i]]);
            limits[i] = i == 0 ? int256(amountIn) : int256(0);

            if (i == hop.path.length - 2) {
                balancerAssets[i + 1] = IAsset(assets[hop.path[i + 1]]);
                limits[i + 1] = int256(0);
            }
        }
        require(hop.poolData.length == poolIdIndex, "MagpieRouter: poolData is invalid");
        IVault.FundManagement memory funds = IVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });

        IVault(amm.id).batchSwap(IVault.SwapKind.GIVEN_IN, swaps, balancerAssets, funds, limits, deadline);
    }

    function _swapCurve(
        uint256 amountIn,
        Hop memory hop,
        address[] memory assets
    ) private {
        Amm memory amm = amms[hop.ammIndex];
        IMagpieCurveRouter(amm.id).exchange(
            IMagpieCurveRouter.ExchangeArgs({
                pool: hop.poolData.toAddress(0),
                from: assets[hop.path[0]],
                to: assets[hop.path[1]],
                amount: amountIn,
                expected: 0,
                receiver: address(this)
            })
        );
    }
}