// SPDX-License-Identifier: MIT
//Twitter: https://twitter.com/FLIP_Tools

pragma solidity ^0.8.0;

import "./IUniswapV2Router02.sol";
import "./ISwapRouter.sol";
import "./IERC20.sol";
import "./IWETH.sol";

contract FlipAggregateRouter {
    error VersionNotSupported();

    address public zeroAdd;
    address public deadAdd = 0x000000000000000000000000000000000000dEaD;
    address public deployer;
    string public twitter = "https://twitter.com/FLIP_Tools";
    string public telegram;
    string public discord;

    mapping(uint256 => IUniswapV2Router02) public v2Routers;// 0 - Uniswap | 1 - Sushiswap
    mapping(uint256 => ISwapRouter) public v3Routers;// 0 - Uniswap | 2 - Camelot
    IWETH public weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    modifier activeDex(uint version, uint256 dexID) {
        address routerAdd;
        if (version == 2) {
            routerAdd = address(v2Routers[dexID]);
        } else if (version == 3) {
            routerAdd = address(v3Routers[dexID]);
        }
        require(routerAdd != zeroAdd,"Dex not active.");
        require(routerAdd != deadAdd,"Dex is blocked");
        _;
    }

    modifier onlyDep() {
        require(msg.sender == deployer,"Only Deployer");
        _;
    }

    constructor () {
        deployer = msg.sender;
        v2Routers[0] = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        v2Routers[1] = IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
        v3Routers[0] = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        v3Routers[2] = ISwapRouter(0xc873fEcbd354f5A56E00E710B90EF4201db2448d);
    }

    receive() external payable {}

    function checkDexActive(uint version, uint256 dexID) external view returns (bool) {
        address routerAdd;
        if (version == 2) {
            routerAdd = address(v2Routers[dexID]);
        } else if (version == 3) {
            routerAdd = address(v3Routers[dexID]);
        }
        if (routerAdd != zeroAdd && routerAdd != deadAdd) {
            return true;
        } else {
            return false;
        }
    }

    function getRouter(uint version, uint256 dexID) external view returns (address) {
        if (version == 2) {
            return address(v2Routers[dexID]);
        } else if (version == 3) {
            return address(v3Routers[dexID]);
        } else {
            revert VersionNotSupported();
        }
    }

    function addRouter(uint version, uint256 dexID, address routerAdd) external onlyDep {
        if (version == 2) {
            require(address(v2Routers[dexID]) == address(0),"Dex already initiated.");
            v2Routers[dexID] = IUniswapV2Router02(routerAdd);
        } else if (version == 3) {
            require(address(v3Routers[dexID]) == address(0),"Dex already initiated.");
            v3Routers[dexID] = ISwapRouter(routerAdd);
        } else {
            revert VersionNotSupported();
        }
    }

    function blockRouter(uint version, uint256 dexID) external onlyDep activeDex(version, dexID) {
        if (version == 2) {
            v2Routers[dexID] = IUniswapV2Router02(deadAdd);
        } else if (version == 3) {
            v3Routers[dexID] = ISwapRouter(deadAdd);
        }
    }

    function setSocials(string memory _twitter, string memory _telegram, string memory _discord) external onlyDep {
        if (bytes(_twitter).length > 0) {
            twitter = _twitter;
        }
        if (bytes(_telegram).length > 0) {
            telegram = _telegram;
        }
        if (bytes(_discord).length > 0) {
            discord = _discord;
        }
    }

    function swapV2ETH(address token, uint256 amount, uint256 dexID, bool isSell) external payable activeDex(2, dexID) returns(uint[] memory amountsOut) {
        IUniswapV2Router02 router = v2Routers[dexID];
        address[] memory path = new address[](2);
        if (isSell) {
            IERC20 Itoken = IERC20(token);
            Itoken.transferFrom(msg.sender, address(this), amount);
            Itoken.approve(address(router), amount);
            path[0] = token;
            path[1] = address(weth);
            amountsOut = router.swapExactTokensForETH(
                amount,
                0,
                path,
                msg.sender,
                block.timestamp
            );
        } else {
            require(msg.value == amount,"Incorrect ETH");
            path[0] = address(weth);
            path[1] = token;
            amountsOut = router.swapExactETHForTokens{value: amount}(
                0,
                path,
                msg.sender,
                block.timestamp
            );
        }
    }

    function swapV2WETH(address token, uint256 amount, uint256 dexID, bool isSell) external activeDex(2, dexID) returns (uint[] memory amountsOut) {
        IUniswapV2Router02 router = v2Routers[dexID];
        address[] memory path = new address[](2);
        if (isSell) {
            IERC20 Itoken = IERC20(token);
            Itoken.transferFrom(msg.sender, address(this), amount);
            Itoken.approve(address(router), amount);
            path[0] = token;
            path[1] = address(weth);
        } else {
            weth.transferFrom(msg.sender, address(this), amount);
            weth.approve(address(router), amount);
            path[0] = address(weth);
            path[1] = token;
        }
        amountsOut = router.swapExactTokensForTokens(
            amount,
            0,
            path,
            msg.sender,
            block.timestamp
        );
    }

    function swapV3WETH(address token, uint256 amount, uint256 dexID, uint24 poolFee, bool isSell) external activeDex(3, dexID) returns (uint256 amountOut) {
        ISwapRouter router = v3Routers[dexID];
        ISwapRouter.ExactInputSingleParams memory params;
        if (isSell) {
            IERC20 Itoken = IERC20(token);
            Itoken.transferFrom(msg.sender, address(this), amount);
            Itoken.approve(address(router), amount);
            params = ISwapRouter.ExactInputSingleParams({
                tokenIn: token,
                tokenOut: address(weth),
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        } else {
            weth.transferFrom(msg.sender, address(this), amount);
            weth.approve(address(router), amount);
            params = ISwapRouter.ExactInputSingleParams({
                tokenIn: address(weth),
                tokenOut: token,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        }
        amountOut = router.exactInputSingle(params);
    }

    function swapV3ETH(address token, uint256 amount, uint256 dexID, uint24 poolFee, bool isSell) external payable activeDex(3, dexID) returns (uint256 amountOut) {
        ISwapRouter router = v3Routers[dexID];
        ISwapRouter.ExactInputSingleParams memory params;
        if (isSell) {
            IERC20 Itoken = IERC20(token);
            Itoken.transferFrom(msg.sender, address(this), amount);
            Itoken.approve(address(router), amount);
            params = ISwapRouter.ExactInputSingleParams({
                tokenIn: token,
                tokenOut: address(weth),
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
            amountOut = router.exactInputSingle(params);
            weth.withdraw(amountOut);
            payable(msg.sender).transfer(amountOut);
        } else {
            require(msg.value == amount,"Incorrect ETH sent");
            weth.deposit{value: amount}();
            weth.approve(address(router), amount);
            params = ISwapRouter.ExactInputSingleParams({
                tokenIn: address(weth),
                tokenOut: token,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
            amountOut = router.exactInputSingle(params);
        }
    }

}