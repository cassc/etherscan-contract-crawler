// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { IUniswapV3Factory } from "../src/interfaces/uniswap/IUniswapV3Factory.sol";
import { INonfungiblePositionManager } from "../src/interfaces/uniswap/INonfungiblePositionManager.sol";
import { IUniswapV3Pool } from "../src/interfaces/uniswap/IUniswapV3Pool.sol";
import { ISwapRouter } from  "../src/interfaces/uniswap/ISwapRouter.sol";


contract FakeToken is ERC20 {
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }
}

contract Failer {
    address tka;
    address tkb;

    constructor(address tka_, address tkb_) {
        tka = tka_;
        tkb = tkb_;
    }

    function exec() public {
        ISwapRouter router = ISwapRouter(0xB971eF87ede563556b2ED4b1C0b0019111Dd85d2);
        uint256 amount = 1e18;
        ISwapRouter.ExactInputSingleParams memory swap =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: address(tka),
                tokenOut: address(tkb),
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp + 100000,
                amountIn: amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0 });
        IERC20(tka).approve(address(router), amount);
        router.exactInputSingle(swap);
    }
}


contract Scratch2 is Script {
    uint256 pk;
    address deployerAddress;

    address public uniswapV3Factory = 0xdB1d10011AD0Ff90774D0C6Bb92e5C5c8b4461F7;
    address public nonfungiblePositionManager = 0x7b8A01B39D58278b5DE7e48c8449c9f4F5170613;
    address public swapRouter = 0xB971eF87ede563556b2ED4b1C0b0019111Dd85d2;
    address public quoterV2 = 0x78D78E420Da98ad378D7799bE8f4AF69033EB077;

    IUniswapV3Pool public uniswapV3Pool;
    INonfungiblePositionManager public manager;

    function setUp() public {
        pk = vm.envUint("BSC_PRIVATE_KEY");
        deployerAddress = vm.envAddress("BSC_DEPLOYER_ADDRESS");
    }

    function run() public {
        console.log("Scratch2");

        vm.startBroadcast(pk);

        FakeToken tka = new FakeToken("FakeTokenA", "FTA", 100e18);
        FakeToken tkb = new FakeToken("FakeTokenB", "FTB", 100e18);
        console.log("tka", address(tka));
        console.log("tkb", address(tkb));


        // -- Set up Uniswap pool -- //
        uint160 initialPrice = 78831026366734653132768280576;
        address token0;
        address token1;
        if (tka < tkb) (token0, token1) = (address(tka), address(tkb));
        else (token0, token1) = (address(tkb), address(tka));
        manager = INonfungiblePositionManager(nonfungiblePositionManager);
        IUniswapV3Factory factory = IUniswapV3Factory(uniswapV3Factory);
        uniswapV3Pool = IUniswapV3Pool(factory.getPool(token0, token1, 3000));
        if (address(uniswapV3Pool) == address(0)) {
            uniswapV3Pool = IUniswapV3Pool(factory.createPool(token0, token1, 3000));
            uniswapV3Pool.initialize(initialPrice);
        }
        console.log("uniswapV3Pool is:", address(uniswapV3Pool));

        // -- Add liquidity to the pool -- //
        {
            uint256 before = uniswapV3Pool.liquidity();
            console.log("Liquidity before:", before);
            manager = INonfungiblePositionManager(nonfungiblePositionManager);

            uint256 token0Amount = 10e18;
            uint256 token1Amount = 10e18;
            int24 tickLower = -6960;
            int24 tickUpper = 6960;
            INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
                token0: token0,
                token1: token1,
                fee: 3000,
                tickLower: tickLower,
                tickUpper: tickUpper,
                amount0Desired: token0Amount,
                amount1Desired: token1Amount,
                amount0Min: 0,
                amount1Min: 0,
                recipient: deployerAddress,
                deadline: block.timestamp + 10000 });
            console.log("Made params");

            IERC20(params.token0).approve(address(manager), token0Amount);
            IERC20(params.token1).approve(address(manager), token1Amount);
            manager.mint(params);

            console.log("Minted");
            uint256 aft = uniswapV3Pool.liquidity();
            console.log("Liquidity after:", aft);
        }

        {
            Failer failer = new Failer(address(tka), address(tkb));
            tka.transfer(address(failer), 10e18);
            console.log("failer", address(failer));
            /* failer.exec(); */
        }
        return;

        // -- Attempt a swap -- //
        {
            ISwapRouter router = ISwapRouter(0xB971eF87ede563556b2ED4b1C0b0019111Dd85d2);
            uint256 amount = 1e18;
            ISwapRouter.ExactInputSingleParams memory swap =
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: address(tka),
                    tokenOut: address(tkb),
                    fee: 3000,
                    recipient: deployerAddress,
                    deadline: block.timestamp + 100000,
                    amountIn: amount,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0 });
            tka.approve(address(router), amount);
            console.log("block.timestamp + 100000", block.timestamp + 100000);
            router.exactInputSingle(swap);
        }

        vm.stopBroadcast();
    }
}