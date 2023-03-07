// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./Miner.sol";

contract LiquidityMiner is Miner {
    constructor(
        address _XFT,
        address _aUSD,
        address _WETH,
        IUniswapV3Pool _xftPool,
        IUniswapV3Pool _tokenPool,
        INonfungiblePositionManager _nonfungiblePositionManager,
        IOracle _oracle,
        IUniswapV3Staker _uniswapV3Staker,
        address _chainlinkFeed,
        uint256 _startTime,
        uint256 _endTime,
        address _refundee
    )
        Miner(
            _XFT,
            _aUSD,
            _WETH,
            _xftPool,
            _tokenPool,
            _nonfungiblePositionManager,
            _oracle,
            _uniswapV3Staker,
            _chainlinkFeed,
            _startTime,
            _endTime,
            _refundee
        )
    {}

    function emergencyShift(uint256 _amount)
        public
        payable
        onlyOwner
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        require(msg.value >= getETHAmount(_amount), "Insufficient ETH provided");
        uint256 etherAmount = msg.value;
        _simpleShift(_amount);
        // Approve the position manager
        aUSD.approve(address(nonfungiblePositionManager), _amount);
        //wrap the ether into WETH to make the process more flexible
        WETH.deposit{ value: etherAmount }();
        WETH.approve(address(nonfungiblePositionManager), etherAmount);

        uint256 amount0Desired;
        uint256 amount1Desired;

        if (tokenPool.token0() == address(WETH)) {
            amount0Desired = etherAmount;
            amount1Desired = _amount;
        } else {
            amount0Desired = _amount;
            amount1Desired = etherAmount;
        }

        // The values for tickLower and tickUpper may not work for all tick spacings.
        // Setting amount0Min and amount1Min to 0 is unsafe.
        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: tokenPool.token0(),
            token1: tokenPool.token1(),
            fee: tokenPool.fee(),
            tickLower: TickMath.MIN_TICK - (TickMath.MIN_TICK % tokenPool.tickSpacing()),
            tickUpper: TickMath.MAX_TICK - (TickMath.MAX_TICK % tokenPool.tickSpacing()),
            amount0Desired: amount0Desired,
            amount1Desired: amount1Desired,
            amount0Min: 0,
            amount1Min: 0,
            recipient: msg.sender,
            deadline: block.timestamp + 300 //Five minutes from "now"
        });

        (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager.mint(params);

        // Remove allowance and refund in both assets.
        if (tokenPool.token0() == address(WETH)) {
            if (amount0 < etherAmount) {
                WETH.approve(address(nonfungiblePositionManager), 0);
                uint256 refund0 = etherAmount - amount0;
                WETH.transfer(msg.sender, refund0);
            }

            if (amount1 < _amount) {
                aUSD.approve(address(nonfungiblePositionManager), 0);
                uint256 refund1 = _amount - amount1;
                aUSD.transfer(msg.sender, refund1);
            }
        } else {
            if (amount0 < _amount) {
                aUSD.approve(address(nonfungiblePositionManager), 0);
                uint256 refund0 = _amount - amount0;
                aUSD.transfer(msg.sender, refund0);
            }

            if (amount1 < etherAmount) {
                WETH.approve(address(nonfungiblePositionManager), 0);
                uint256 refund1 = etherAmount - amount1;
                WETH.transfer(msg.sender, refund1);
            }
        }
    }
}