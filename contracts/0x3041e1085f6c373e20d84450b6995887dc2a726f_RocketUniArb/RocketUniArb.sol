/**
 *Submitted for verification at Etherscan.io on 2023-03-26
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.17;

interface IUniswapV3PoolActions {
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}
interface IUniswapV3SwapCallback {
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}
interface RocketStorageInterface {
    function getAddress(bytes32 _key) external view returns (address);
}
interface RocketDepositPoolInterface {
    function deposit() external payable;
}
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}
interface IWETH9 {
    function withdraw(uint256) external;
}



contract RocketUniArb is IUniswapV3SwapCallback {
    address immutable weth;
    address immutable reth;

    address immutable rocketStorage;
    bytes32 immutable depositPoolKey;
    
    constructor(address _weth, address _rocketStorage) {
        weth = _weth;
        reth = RocketStorageInterface(_rocketStorage).getAddress(keccak256("contract.addressrocketTokenRETH"));

        rocketStorage = _rocketStorage;
        depositPoolKey = keccak256("contract.addressrocketDepositPool");
    }

    receive () external payable { }

    function arb(uint256 depositAmount, uint256 minProfit, bytes calldata swapData) external {
        // Our calldata should contain
        // 1: the address of the uniswap v3 weth <-> rEth pool we should swap on
        // 2: the amount of rEth to swap into the pool (aka the amount of rEth we expect to recieve from minting)
        (address uniPool, uint256 rethExpected) = abi.decode(swapData, (address, uint256));

        // do a swap on our hardcoded uniswap v3 pool - we're swapping `rethExpected` amount of rEth for some unknown amount of weth
        // the pool will pay the weth to us, then call uniswapV3SwapCallback() in which we'll actually do the rEth mint, and pay the rEth back to the pool
        {
            bool swapZeroForOne = true; // config parameter telling the pool which direction to swap. true when swapping reth to weth, false when swapping weth to reth
            uint160 priceLimit = 4295128740; // This constant essentially tells uniswap v3 that we do not have a price limit.
            bytes memory innerCalldata = abi.encode(depositAmount);
            IUniswapV3PoolActions(uniPool).swap(address(this), swapZeroForOne, int256(rethExpected), priceLimit, innerCalldata);
        }

        // all eth left in this contract is arb profit
        uint256 profit = address(this).balance;
        require(profit > minProfit, "LOW PROFIT");
        payable(msg.sender).transfer(profit);
    }

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external override {
        // unwrap all weth owned by this contract
        uint256 wethBalance = IERC20(weth).balanceOf(address(this));
        IWETH9(weth).withdraw(wethBalance);

        // the amount to deposit to rocketpool is in our calldata, extract it
        uint256 depositAmount = abi.decode(data, (uint256));

        // deposit to rocketpool, and use the pool (ie msg.sender) as the recipient
        address rocketDepositPool = RocketStorageInterface(rocketStorage).getAddress(depositPoolKey);
        RocketDepositPoolInterface(rocketDepositPool).deposit{value:depositAmount}();

        // repay the pool
        // The amount we need to repay is just whichever amount delta is positive. But because we know statically which direction we're swapping in, we know it's amount0Delta
        uint256 repayAmount = uint256(amount0Delta);
        IERC20(reth).transfer(msg.sender, repayAmount);
    }
}