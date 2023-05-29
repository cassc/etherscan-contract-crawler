// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";

import "./interfaces/IUnipilotVault.sol";
import "./interfaces/external/IWETH9.sol";
import "./interfaces/IUnipilotMigrator.sol";
import "./libraries/TransferHelper.sol";
import "./interfaces/external/IUniswapLiquidityManager.sol";
import "./interfaces/popsicle-interfaces/IPopsicleV3Optimizer.sol";
import "./interfaces/visor-interfaces/IVault.sol";
import "./interfaces/lixir-interfaces/ILixirVaultETH.sol";
import "./interfaces/external/IUnipilot.sol";
import "./base/PeripheryPayments.sol";

/// @title Uniswap V2, V3, Sushiswap, Visor, Lixir, Popsicle Liquidity Migrator
contract UnipilotMigrator is
    IUnipilotMigrator,
    PeripheryPayments,
    IERC721Receiver,
    Context
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address private immutable ulm;
    address private immutable positionManager;

    IUnipilot private unipilot;

    constructor(
        address _positionManager,
        address _unipilot,
        address _ulm
    ) {
        positionManager = _positionManager;
        ulm = _ulm;

        unipilot = IUnipilot(_unipilot);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return IERC721Receiver(0).onERC721Received.selector;
    }

    function migrateUnipilotLiquididty(MigrateV3Params memory params) external {
        address caller = _msgSender();
        IUniswapLiquidityManager.Position
            memory userPosition = IUniswapLiquidityManager(ulm).userPositions(
                params.tokenId
            );

        IExchangeManager.WithdrawParams memory withdrawParam = IExchangeManager
            .WithdrawParams({
                pilotToken: false,
                wethToken: true,
                exchangeManagerAddress: ulm,
                liquidity: userPosition.liquidity,
                tokenId: params.tokenId
            });

        unipilot.safeTransferFrom(caller, address(this), params.tokenId);

        unipilot.withdraw(withdrawParam, abi.encode(address(this)));

        uint256 amount0 = _balanceOf(params.token0, address(this));
        uint256 amount1 = _balanceOf(params.token1, address(this));

        require(amount0 > 0 && amount1 > 0, "IF");

        _tokenApproval(params.token0, params.vault, amount0);
        _tokenApproval(params.token1, params.vault, amount1);

        (params.token0, amount0, params.token1, amount1) = _sortTokenAmount(
            params.token0,
            params.token1,
            amount0,
            amount1
        );

        (
            uint256 amount0Unipilot,
            uint256 amount1Unipilot
        ) = _addLiquidityUnipilot(params.vault, amount0, amount1, caller);

        _refundRemainingLiquidiy(
            RefundLiquidityParams({
                vault: params.vault,
                token0: params.token0,
                token1: params.token1,
                amount0Unipilot: amount0Unipilot,
                amount1Unipilot: amount1Unipilot,
                amount0Recieved: amount0,
                amount1Recieved: amount1,
                amount0ToMigrate: amount0,
                amount1ToMigrate: amount1,
                refundAsETH: params.refundAsETH
            })
        );

        emit LiquidityMigratedFromV3(
            true,
            params.vault,
            caller,
            amount0Unipilot,
            amount1Unipilot
        );
    }

    function migrateV2Liquidity(MigrateV2Params calldata params) external {
        require(
            params.percentageToMigrate > 0 && params.percentageToMigrate <= 100,
            "IPA"
        );

        IUniswapV2Pair(params.pair).transferFrom(
            _msgSender(),
            params.pair,
            params.liquidityToMigrate
        );

        (uint256 amount0V2, uint256 amount1V2) = IUniswapV2Pair(params.pair)
            .burn(address(this));

        uint256 amount0ToMigrate = FullMath.mulDiv(
            amount0V2,
            params.percentageToMigrate,
            100
        );

        uint256 amount1ToMigrate = FullMath.mulDiv(
            amount1V2,
            params.percentageToMigrate,
            100
        );

        _tokenApproval(params.token0, params.vault, amount0ToMigrate);

        _tokenApproval(params.token1, params.vault, amount1ToMigrate);

        (uint256 amount0V3, uint256 amount1V3) = _addLiquidityUnipilot(
            params.vault,
            amount0ToMigrate,
            amount1ToMigrate,
            _msgSender()
        );

        _refundRemainingLiquidiy(
            RefundLiquidityParams({
                vault: params.vault,
                token0: params.token0,
                token1: params.token1,
                amount0Unipilot: amount0V3,
                amount1Unipilot: amount1V3,
                amount0Recieved: amount0V2,
                amount1Recieved: amount1V2,
                amount0ToMigrate: amount0ToMigrate,
                amount1ToMigrate: amount1ToMigrate,
                refundAsETH: params.refundAsETH
            })
        );

        emit LiquidityMigratedFromV2(
            params.pair,
            params.vault,
            _msgSender(),
            amount0V3,
            amount1V3
        );
    }

    function migrateV3Liquidity(MigrateV3Params calldata params) external {
        INonfungiblePositionManager periphery = INonfungiblePositionManager(
            positionManager
        );

        periphery.safeTransferFrom(_msgSender(), address(this), params.tokenId);

        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            uint128 liquidityV3,
            ,
            ,
            ,

        ) = INonfungiblePositionManager(positionManager).positions(
                params.tokenId
            );

        periphery.decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: params.tokenId,
                liquidity: liquidityV3,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp + 120
            })
        );

        // returns the total amount of Liquidity with collected fees to user
        (uint256 amount0V3, uint256 amount1V3) = periphery.collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: params.tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );

        // approve the Unipilot up to the maximum token amounts
        _tokenApproval(params.token0, params.vault, amount0V3);
        _tokenApproval(params.token1, params.vault, amount1V3);

        (
            uint256 amount0Unipilot,
            uint256 amount1Unipilot
        ) = _addLiquidityUnipilot(
                params.vault,
                amount0V3,
                amount1V3,
                _msgSender()
            );

        _refundRemainingLiquidiy(
            RefundLiquidityParams({
                vault: params.vault,
                token0: params.token0,
                token1: params.token1,
                amount0Unipilot: amount0Unipilot,
                amount1Unipilot: amount1Unipilot,
                amount0Recieved: amount0V3,
                amount1Recieved: amount1V3,
                amount0ToMigrate: amount0V3,
                amount1ToMigrate: amount1V3,
                refundAsETH: params.refundAsETH
            })
        );

        periphery.burn(params.tokenId);

        emit LiquidityMigratedFromV3(
            false,
            params.vault,
            _msgSender(),
            amount0Unipilot,
            amount1Unipilot
        );
    }

    function migrateVisorLiquidity(MigrateV2Params memory params) external {
        require(
            params.percentageToMigrate > 0 && params.percentageToMigrate <= 100,
            "IPA"
        );

        IERC20(params.pair).safeTransferFrom(
            _msgSender(),
            address(this),
            params.liquidityToMigrate
        );

        (uint256 amount0V2, uint256 amount1V2) = IVault(params.pair).withdraw(
            params.liquidityToMigrate,
            address(this),
            address(this)
        );

        uint256 amount0ToMigrate = FullMath.mulDiv(
            amount0V2,
            params.percentageToMigrate,
            100
        );

        uint256 amount1ToMigrate = FullMath.mulDiv(
            amount1V2,
            params.percentageToMigrate,
            100
        );

        _tokenApproval(params.token0, params.vault, amount0ToMigrate);
        _tokenApproval(params.token1, params.vault, amount1ToMigrate);

        (
            params.token0,
            amount0ToMigrate,
            params.token1,
            amount1ToMigrate
        ) = _sortTokenAmount(
            params.token0,
            params.token1,
            amount0ToMigrate,
            amount1ToMigrate
        );

        (uint256 amount0V3, uint256 amount1V3) = _addLiquidityUnipilot(
            params.vault,
            amount0ToMigrate,
            amount1ToMigrate,
            _msgSender()
        );

        _refundRemainingLiquidiy(
            RefundLiquidityParams({
                vault: params.vault,
                token0: params.token0,
                token1: params.token1,
                amount0Unipilot: amount0V3,
                amount1Unipilot: amount1V3,
                amount0Recieved: amount0V2,
                amount1Recieved: amount1V2,
                amount0ToMigrate: amount0ToMigrate,
                amount1ToMigrate: amount1ToMigrate,
                refundAsETH: params.refundAsETH
            })
        );

        emit LiquidityMigratedFromV2(
            params.pair,
            params.vault,
            _msgSender(),
            amount0V3,
            amount1V3
        );
    }

    function migrateLixirLiquidity(MigrateV2Params memory params) external {
        require(
            params.percentageToMigrate > 0 && params.percentageToMigrate <= 100,
            "IPA"
        );

        (uint256 amount0V2, uint256 amount1V2) = ILixirVaultETH(
            payable(address(params.pair))
        ).withdrawETHFrom(
                _msgSender(),
                params.liquidityToMigrate,
                0,
                0,
                address(this),
                block.timestamp + 120
            );

        (
            address alt,
            uint256 altAmountReceived,
            address weth,
            uint256 wethAmountReceived
        ) = _sortWethAmount(params.token0, params.token1, amount0V2, amount1V2);

        IWETH9(WETH).deposit{ value: wethAmountReceived }();

        uint256 wethAmountToMigrate = FullMath.mulDiv(
            wethAmountReceived,
            params.percentageToMigrate,
            100
        );

        uint256 altAmountToMigrate = FullMath.mulDiv(
            altAmountReceived,
            params.percentageToMigrate,
            100
        );

        _tokenApproval(alt, params.vault, altAmountToMigrate);
        _tokenApproval(weth, params.vault, wethAmountToMigrate);

        (params.token0, amount0V2, params.token1, amount1V2) = _sortTokenAmount(
            alt,
            weth,
            altAmountReceived,
            wethAmountReceived
        );

        (uint256 amount0V3, uint256 amount1V3) = _addLiquidityUnipilot(
            params.vault,
            amount0V2,
            amount1V2,
            _msgSender()
        );

        _refundRemainingLiquidiy(
            RefundLiquidityParams({
                vault: params.vault,
                token0: alt,
                token1: weth,
                amount0Unipilot: amount0V3,
                amount1Unipilot: amount1V3,
                amount0Recieved: altAmountReceived,
                amount1Recieved: wethAmountReceived,
                amount0ToMigrate: altAmountToMigrate,
                amount1ToMigrate: wethAmountToMigrate,
                refundAsETH: params.refundAsETH
            })
        );

        emit LiquidityMigratedFromV2(
            params.pair,
            params.vault,
            _msgSender(),
            amount0V3,
            amount1V3
        );
    }

    function migratePopsicleLiquidity(MigrateV2Params memory params) external {
        require(
            params.percentageToMigrate > 0 && params.percentageToMigrate <= 100,
            "IPA"
        );

        IERC20(params.pair).transferFrom(
            _msgSender(),
            address(this),
            params.liquidityToMigrate
        );

        (uint256 amount0, uint256 amount1) = IPopsicleV3Optimizer(params.pair)
            .withdraw(params.liquidityToMigrate, address(this));

        uint256 amount0ToMigrate = FullMath.mulDiv(
            amount0,
            params.percentageToMigrate,
            100
        );

        uint256 amount1ToMigrate = FullMath.mulDiv(
            amount1,
            params.percentageToMigrate,
            100
        );

        _tokenApproval(params.token0, params.vault, amount0ToMigrate);
        _tokenApproval(params.token1, params.vault, amount1ToMigrate);

        (
            params.token0,
            amount0ToMigrate,
            params.token1,
            amount1ToMigrate
        ) = _sortTokenAmount(
            params.token0,
            params.token1,
            amount0ToMigrate,
            amount1ToMigrate
        );

        (uint256 amount0V3, uint256 amount1V3) = _addLiquidityUnipilot(
            params.vault,
            amount0ToMigrate,
            amount1ToMigrate,
            _msgSender()
        );

        _refundRemainingLiquidiy(
            RefundLiquidityParams({
                vault: params.vault,
                token0: params.token0,
                token1: params.token1,
                amount0Unipilot: amount0V3,
                amount1Unipilot: amount1V3,
                amount0Recieved: amount0,
                amount1Recieved: amount1,
                amount0ToMigrate: amount0ToMigrate,
                amount1ToMigrate: amount1ToMigrate,
                refundAsETH: params.refundAsETH
            })
        );

        emit LiquidityMigratedFromV2(
            params.pair,
            params.vault,
            _msgSender(),
            amount0V3,
            amount1V3
        );
    }

    function _refundRemainingLiquidiy(RefundLiquidityParams memory params)
        private
    {
        if (params.amount0Unipilot < params.amount0Recieved) {
            if (params.amount0Unipilot < params.amount0ToMigrate) {
                TransferHelper.safeApprove(params.token0, params.vault, 0);
            }
            if (params.refundAsETH && params.token0 == WETH) {
                unwrapWETH9(0, _msgSender());
            } else {
                sweepToken(params.token0, 0, _msgSender());
            }
        }
        if (params.amount1Unipilot < params.amount1Recieved) {
            if (params.amount1Unipilot < params.amount1ToMigrate) {
                TransferHelper.safeApprove(params.token1, params.vault, 0);
            }
            if (params.refundAsETH && params.token1 == WETH) {
                unwrapWETH9(0, _msgSender());
            } else {
                sweepToken(params.token1, 0, _msgSender());
            }
        }
    }

    function _addLiquidityUnipilot(
        address vault,
        uint256 amount0,
        uint256 amount1,
        address recipient
    ) private returns (uint256 despositedAmount0, uint256 despositedAmount1) {
        (, despositedAmount0, despositedAmount1) = IUnipilotVault(vault)
            .deposit(amount0, amount1, recipient);
    }

    function _sortWethAmount(
        address _token0,
        address _token1,
        uint256 _amount0,
        uint256 _amount1
    )
        private
        view
        returns (
            address tokenAlt,
            uint256 altAmount,
            address tokenWeth,
            uint256 wethAmount
        )
    {
        (
            address tokenA,
            address tokenB,
            uint256 amountA,
            uint256 amountB
        ) = _token0 == WETH
                ? (_token0, _token1, _amount0, _amount1)
                : (_token0, _token1, _amount1, _amount0);

        (tokenAlt, altAmount, tokenWeth, wethAmount) = tokenA == WETH
            ? (tokenB, amountB, tokenA, amountA)
            : (tokenA, amountA, tokenB, amountB);
    }

    function _sortTokenAmount(
        address _token0,
        address _token1,
        uint256 _amount0,
        uint256 _amount1
    )
        private
        view
        returns (
            address tokenAlt1,
            uint256 altAmount1,
            address tokenAlt2,
            uint256 altAmount2
        )
    {
        (tokenAlt1, altAmount1, tokenAlt2, altAmount2) = _token0 < _token1
            ? (_token0, _amount0, _token1, _amount1)
            : (_token1, _amount1, _token0, _amount0);
    }

    function _tokenApproval(
        address _token,
        address _vault,
        uint256 _amount
    ) private {
        TransferHelper.safeApprove(_token, _vault, _amount);
    }

    function _balanceOf(address _token, address _caller)
        private
        view
        returns (uint256)
    {
        return IERC20(_token).balanceOf(_caller);
    }
}