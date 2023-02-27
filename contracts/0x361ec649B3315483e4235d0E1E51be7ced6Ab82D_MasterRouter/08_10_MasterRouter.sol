// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
import {IRouter} from "./interfaces/IRouter.sol";
import {VersionedInitializable} from "./proxy/VersionedInitializable.sol";
import {KeeperCompatibleInterface} from "./interfaces/KeeperCompatibleInterface.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IWETH} from "./interfaces/IWETH.sol";

import "hardhat/console.sol";

contract MasterRouter is
    Ownable,
    VersionedInitializable,
    KeeperCompatibleInterface
{
    IERC20 public arth;
    IERC20 public maha;
    IWETH public weth;

    address private me;

    IRouter public curveRouter;
    IRouter public mahaWethRouter;
    IRouter public arthMahaRouter;

    mapping(IERC20 => IRouter) public routers;
    mapping(IERC20 => uint256) public routerMinimum;

    event RegisterRouter(
        address who,
        IERC20 _token,
        IRouter _router,
        uint256 minNeeded
    );

    receive() external payable {
        weth.deposit{value: msg.value}();
    }

    function initialize(
        address _treasury,
        IERC20 _arth,
        IERC20 _maha,
        IWETH _weth,
        IRouter _curveRouter,
        IRouter _mahaWethRouter
    ) external initializer {
        me = address(this);

        arth = _arth;
        maha = _maha;
        weth = _weth;

        routerMinimum[weth] = 1e18; // 1 eth min
        routers[weth] = _mahaWethRouter;
        weth.approve(address(_mahaWethRouter), type(uint256).max);

        routerMinimum[arth] = 500e18; // 500 arth min
        routers[arth] = _curveRouter;
        arth.approve(address(_curveRouter), type(uint256).max);

        _transferOwnership(_treasury);
    }

    function getRevision() public pure virtual override returns (uint256) {
        return 1;
    }

    function registerRouter(
        IERC20 _token,
        IRouter _router,
        uint256 minNeeded
    ) external onlyOwner {
        routerMinimum[_token] = minNeeded;
        routers[_token] = _router;
        _token.approve(address(_router), type(uint256).max);

        emit RegisterRouter(msg.sender, _token, _router, minNeeded);
    }

    function checkUpkeep(
        bytes calldata
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        uint256 _arthBal = arth.balanceOf(me);
        uint256 _wethBal = weth.balanceOf(me);
        uint256 _mahaBal = maha.balanceOf(me);

        bool _executeArth = _arthBal >= routerMinimum[arth] && _arthBal > 0;
        bool _executeWeth = _wethBal >= routerMinimum[weth] && _wethBal > 0;
        bool _executeMaha = _mahaBal >= routerMinimum[maha] && _mahaBal > 0;

        performData = abi.encode(
            // ARTH/USDC Cruve
            _executeArth ? _arthBal : 0,
            abi.encode(_arthBal, uint256(0)), // uint256 tokenArthAmount, uint256 minLptokens
            // MAHA/WETH Uniswap
            _executeWeth ? _wethBal : 0,
            abi.encode(uint256(0), uint256(0)), // uint256 amount0Min, uint256 amount1Min
            // ARTH/MAHA Uniswap
            _executeMaha ? _mahaBal : 0,
            abi.encode(uint256(0), uint256(0)) // uint256  amount0Min, uint256 amount1Min
        );

        upkeepNeeded = _executeMaha || _executeWeth || _executeArth;
    }

    function performUpkeep(bytes calldata performData) external {
        (
            uint256 _arthBal,
            bytes memory _arthData,
            uint256 _wethBal,
            bytes memory _wethData,
            uint256 _mahaBal,
            bytes memory _mahaData
        ) = abi.decode(
                performData,
                (uint256, bytes, uint256, bytes, uint256, bytes)
            );

        if (_mahaBal > 0) routers[maha].execute(_mahaBal, 0, _mahaData);
        if (_wethBal > 0) routers[weth].execute(0, _wethBal, _wethData);
        if (_arthBal > 0) routers[arth].execute(_arthBal, 0, _arthData);
    }

    /// @dev helper function to get add liquidty to all the pools in one go.
    function addLiquidityToPool() external {
        executeCurve();
        executeUniswapARTHMAHA();
        executeUniswapMAHAWETH();
    }

    /// @notice adds whatever ARTH is in this contract into the curve pool
    function executeCurve() public {
        uint256 arthBalance = arth.balanceOf(me);

        // token0 is ARTH and token1 is USDC according to the curve pool
        if (arthBalance > 0)
            curveRouter.execute(
                arthBalance,
                0,
                abi.encode(uint256(0), uint256(0))
            );
    }

    /// @notice adds whatever MAHA is in this contract into the ARTH/MAHA 1% Uniswap pool
    function executeUniswapARTHMAHA() public {
        uint256 mahaBalance = maha.balanceOf(me);

        // token0 is MAHA Token and token1 is ARTH Token according to the Uniswap v3 pool
        if (mahaBalance > 0)
            arthMahaRouter.execute(
                mahaBalance,
                0,
                abi.encode(uint256(0), uint256(0))
            );
    }

    /// @notice adds whatever WETH is in this contract into the WETH/MAHA 1% Uniswap pool
    function executeUniswapMAHAWETH() public {
        uint256 wethBalance = weth.balanceOf(me);

        // token0 is MAHA Token and token1 is WETH Token according to the Uniswap v3 pool
        if (wethBalance > 0)
            mahaWethRouter.execute(
                0,
                wethBalance,
                abi.encode(uint256(0), uint256(0))
            );
    }

    /// @dev admin-only. send tokens back to treasury
    function refund(IERC20 token) public onlyOwner {
        token.transfer(msg.sender, token.balanceOf(me));
    }
}