// SPDX-License-Identifier: BSL

pragma solidity ^0.7.6;
pragma abicoder v2;

// contracts
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "./base/UniswapV3TwapLiquidityManager.sol";

// libraries
import "../libraries/LiquidityHelper.sol";

contract DefiEdgeTwapStrategy is UniswapV3TwapLiquidityManager {
    using SafeMath for uint256;

    // events
    event Mint(address indexed user, uint256 share, uint256 amount0, uint256 amount1);
    event Burn(address indexed user, uint256 share, uint256 amount0, uint256 amount1);
    event Hold();
    event Rebalance(NewTick[] ticks);
    event PartialRebalance(PartialTick[] ticks);

    struct PartialTick {
        uint256 index;
        bool burn;
        uint256 amount0;
        uint256 amount1;
    }

    struct NewTick {
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0;
        uint256 amount1;
    }

    /**
     * @param _factory Address of the strategy factory
     * @param _pool Address of the pool
     * @param _oneInchRouter Address of the Uniswap V3 periphery swap router
     * @param _chainlinkRegistry Chainlink registry address
     * @param _manager Address of the manager
     * @param _useTwap is twap will be used to fetch usd price or chainlink will be used
     * @param _ticks Array of the ticks
     */
    constructor(
        ITwapStrategyFactory _factory,
        IUniswapV3Pool _pool,
        IOneInchRouter _oneInchRouter,
        FeedRegistryInterface _chainlinkRegistry,
        ITwapStrategyManager _manager,
        bool[2] memory _useTwap,
        Tick[] memory _ticks
    ) {
        require(!isInvalidTicks(_ticks), "IT");
        // checks for valid ticks length
        require(_ticks.length <= MAX_TICK_LENGTH, "ITL");
        manager = _manager;
        factory = _factory;
        oneInchRouter = _oneInchRouter;
        chainlinkRegistry = _chainlinkRegistry;
        pool = _pool;
        token0 = IERC20(pool.token0());
        token1 = IERC20(pool.token1());
        useTwap = _useTwap;
        // useTwap = _useTwapForToken0 ? [true, false] : [false, true];
        for (uint256 i = 0; i < _ticks.length; i++) {
            ticks.push(Tick(_ticks[i].tickLower, _ticks[i].tickUpper));
        }
    }

    /**
     * @notice Adds liquidity to the primary range
     * @param _amount0 Amount of token0
     * @param _amount1 Amount of token1
     * @param _amount0Min Minimum amount of token0 to be minted
     * @param _amount1Min Minimum amount of token1 to be minted
     * @param _minShare Minimum amount of shares to be received to the user
     */
    function mint(
        uint256 _amount0,
        uint256 _amount1,
        uint256 _amount0Min,
        uint256 _amount1Min,
        uint256 _minShare
    )
        external
        onlyValidStrategy
        nonReentrant
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 share
        )
    {
        require(manager.isUserWhiteListed(msg.sender), "UA");

        // get total amounts with fees
        (uint256 totalAmount0, uint256 totalAmount1, , ) = this.getAUMWithFees(true);

        // calculate optimal token0 & token1 amount for mint
        (_amount0, _amount1) = TwapShareHelper.getOptimalAmounts(_amount0, _amount1, _amount0Min, _amount1Min, totalAmount0, totalAmount1);

        amount0 = _amount0;
        amount1 = _amount1;

        if (amount0 > 0) {
            TransferHelper.safeTransferFrom(address(token0), msg.sender, address(this), amount0);
        }
        if (amount1 > 0) {
            TransferHelper.safeTransferFrom(address(token1), msg.sender, address(this), amount1);
        }

        // issue share based on the liquidity added
        share = issueShare(amount0, amount1, totalAmount0, totalAmount1, msg.sender);

        // prevent front running of strategy fee
        require(share >= _minShare, "SC");

        // price slippage check
        require(amount0 >= _amount0Min && amount1 >= _amount1Min, "S");

        uint256 _shareLimit = manager.limit();
        // share limit
        if (_shareLimit != 0) {
            require(totalSupply() <= _shareLimit, "L");
        }
        emit Mint(msg.sender, share, amount0, amount1);
    }

    /**
     * @notice Burn liquidity and transfer tokens back to the user
     * @param _shares Shares to be burned
     * @param _amount0Min Mimimum amount of token0 to be received
     * @param _amount1Min Minimum amount of token1 to be received
     */
    function burn(
        uint256 _shares,
        uint256 _amount0Min,
        uint256 _amount1Min
    ) external nonReentrant returns (uint256 collect0, uint256 collect1) {
        // check if the user has sufficient shares
        require(balanceOf(msg.sender) >= _shares && _shares != 0, "INS");

        uint256 amount0;
        uint256 amount1;

        uint256 totalFee0;
        uint256 totalFee1;

        // burn liquidity based on shares from existing ticks
        for (uint256 i = 0; i < ticks.length; i++) {
            Tick storage tick = ticks[i];

            uint256 fee0;
            uint256 fee1;
            // burn liquidity and collect fees
            (amount0, amount1, fee0, fee1) = burnLiquidity(tick.tickLower, tick.tickUpper, _shares, 0);

            totalFee0 = totalFee0.add(fee0);
            totalFee1 = totalFee1.add(fee1);

            // add to total amounts
            collect0 = collect0.add(amount0);
            collect1 = collect1.add(amount1);
        }

        if (totalFee0 > 0 || totalFee1 > 0) {
            _transferPerformanceFees(totalFee0, totalFee1);
        }

        // transfer performance fees

        // give from unused amounts
        uint256 total0 = IERC20(token0).balanceOf(address(this));
        uint256 total1 = IERC20(token1).balanceOf(address(this));

        uint256 _totalSupply = totalSupply();

        if (total0 > collect0) {
            collect0 = collect0.add(FullMath.mulDiv(total0 - collect0, _shares, _totalSupply));
        }

        if (total1 > collect1) {
            collect1 = collect1.add(FullMath.mulDiv(total1 - collect1, _shares, _totalSupply));
        }

        // check slippage
        require(_amount0Min <= collect0 && _amount1Min <= collect1, "S");

        // burn shares
        _burn(msg.sender, _shares);

        // transfer tokens
        if (collect0 > 0) {
            TransferHelper.safeTransfer(address(token0), msg.sender, collect0);
        }
        if (collect1 > 0) {
            TransferHelper.safeTransfer(address(token1), msg.sender, collect1);
        }

        emit Burn(msg.sender, _shares, collect0, collect1);
    }

    /**
     * @notice Rebalances the strategy
     * @param _swapData Swap data to perform exchange from 1inch
     * @param _existingTicks Array of existing ticks to rebalance
     * @param _newTicks New ticks in case there are any
     * @param _burnAll When burning into new ticks, should we burn all liquidity?
     */
    function rebalance(
        bytes calldata _swapData,
        PartialTick[] calldata _existingTicks,
        NewTick[] calldata _newTicks,
        bool _burnAll
    ) external onlyOperator onlyValidStrategy nonReentrant {
        uint256 totalFee0;
        uint256 totalFee1;

        if (_burnAll) {
            require(_existingTicks.length == 0, "IA");
            onHold = true;
            (totalFee0, totalFee1) = burnAllLiquidity();
            if (totalFee0 > 0 || totalFee1 > 0) {
                _transferPerformanceFees(totalFee0, totalFee1);
            }
            delete ticks;
            emit Hold();
        }

        //swap from 1inch if needed
        if (_swapData.length > 0) {
            _swap(_swapData);
        }

        // redeploy the partial ticks
        if (_existingTicks.length > 0) {
            for (uint256 i = 0; i < _existingTicks.length; i++) {
                // require existing ticks to be in decreasing order
                if (i > 0) require(_existingTicks[i - 1].index > _existingTicks[i].index, "IO"); // invalid order

                Tick memory _tick = ticks[_existingTicks[i].index];

                if (_existingTicks[i].burn) {
                    // burn liquidity from range
                    (, , uint256 fee0, uint256 fee1) = _burnLiquiditySingle(_existingTicks[i].index);

                    totalFee0 = totalFee0.add(fee0);
                    totalFee1 = totalFee1.add(fee1);
                }

                if (_existingTicks[i].amount0 > 0 || _existingTicks[i].amount1 > 0) {
                    // mint liquidity
                    mintLiquidity(_tick.tickLower, _tick.tickUpper, _existingTicks[i].amount0, _existingTicks[i].amount1, address(this));
                } else if (_existingTicks[i].burn) {
                    // shift the index element at last of array
                    ticks[_existingTicks[i].index] = ticks[ticks.length - 1];
                    // remove last element
                    ticks.pop();
                }
            }

            if (totalFee0 > 0 || totalFee1 > 0) {
                _transferPerformanceFees(totalFee0, totalFee1);
            }

            emit PartialRebalance(_existingTicks);
        }

        // deploy liquidity into new ticks
        if (_newTicks.length > 0) {
            redeploy(_newTicks);
            emit Rebalance(_newTicks);
        }

        require(!isInvalidTicks(ticks), "IT");
        // checks for valid ticks length
        require(ticks.length <= MAX_TICK_LENGTH + 10, "ITL");
    }

    /**
     * @notice Redeploys between ticks
     * @param _ticks Array of the ticks with amounts
     */
    function redeploy(NewTick[] memory _ticks) internal {
        // set hold false
        onHold = false;
        // redeploy the liquidity
        for (uint256 i = 0; i < _ticks.length; i++) {
            NewTick memory tick = _ticks[i];

            // mint liquidity
            mintLiquidity(tick.tickLower, tick.tickUpper, tick.amount0, tick.amount1, address(this));

            // push to ticks array
            ticks.push(Tick(tick.tickLower, tick.tickUpper));
        }
    }

    /**
     * @notice Withdraws funds from the contract in case of emergency
     * @dev only governance can withdraw the funds, it can be frozen from the factory permenently
     * @param _token Token to transfer
     * @param _to Where to transfer the token
     * @param _amount Amount to be withdrawn
     * @param _newTicks Ticks data to burn liquidity from
     */
    function emergencyWithdraw(
        address _token,
        address _to,
        uint256 _amount,
        NewTick[] calldata _newTicks
    ) external {
        require(msg.sender == factory.governance() && !factory.freezeEmergency());
        if (_newTicks.length > 0) {
            for (uint256 tickIndex = 0; tickIndex < _newTicks.length; tickIndex++) {
                NewTick memory tick = _newTicks[tickIndex];
                (uint128 currentLiquidity, , , , ) = pool.positions(PositionKey.compute(address(this), tick.tickLower, tick.tickUpper));
                pool.burn(tick.tickLower, tick.tickUpper, currentLiquidity);
                pool.collect(address(this), tick.tickLower, tick.tickUpper, type(uint128).max, type(uint128).max);
            }
        }
        if (_amount > 0) {
            TransferHelper.safeTransfer(_token, _to, _amount);
        }
    }
}