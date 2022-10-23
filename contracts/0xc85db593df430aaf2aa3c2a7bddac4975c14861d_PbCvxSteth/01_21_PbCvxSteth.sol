// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./PbCvxBase.sol";
import "../interface/IChainlink.sol";
import "../interface/IRouter.sol";

contract PbCvxSteth is PbCvxBase {

    IERC20Upgradeable constant stETH = IERC20Upgradeable(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
    IERC20Upgradeable constant ldo = IERC20Upgradeable(0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32);
    IChainlink constant ethUsdPriceOracle = IChainlink(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    IRouter constant router = IRouter(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F); // sushiswap
    
    function initialize(uint _pid, IPool _pool, IERC20Upgradeable _rewardToken) external initializer {
        __Ownable_init();

        (address _lpToken,,, address _gauge) = booster.poolInfo(_pid);
        lpToken = IERC20Upgradeable(_lpToken);
        gauge = IGauge(_gauge);
        pid = _pid;
        pool = _pool;
        rewardToken = _rewardToken;
        treasury = msg.sender;

        (,,,,,,, address aTokenAddr,,,,) = lendingPool.getReserveData(address(rewardToken));
        aToken = IERC20Upgradeable(aTokenAddr);

        crv.approve(address(swapRouter), type(uint).max);
        cvx.approve(address(swapRouter), type(uint).max);
        ldo.approve(address(router), type(uint).max);
        stETH.approve(address(pool), type(uint).max);
        lpToken.approve(address(booster), type(uint).max);
        lpToken.approve(address(pool), type(uint).max);
        rewardToken.approve(address(lendingPool), type(uint).max);
    }

    function deposit(
        IERC20Upgradeable token,
        uint amount,
        uint amountOutMin
    ) external payable override nonReentrant whenNotPaused {
        require(token == weth || token == stETH || token == lpToken, "Invalid token");
        require(amount > 0, "Invalid amount");

        uint currentPool = gauge.balanceOf(address(this));
        if (currentPool > 0) harvest();

        if (token == weth) {
            require(msg.value == amount, "Invalid ETH");
        } else {
            token.transferFrom(msg.sender, address(this), amount);
        }
        depositedBlock[msg.sender] = block.number;

        uint lpTokenAmt;
        if (token != lpToken) {
            uint[2] memory amounts;
            if (token == weth) amounts[0] = amount;
            else amounts[1] = amount; // token == steth
            lpTokenAmt = pool.add_liquidity{value: msg.value}(amounts, amountOutMin);
        } else {
            lpTokenAmt = amount;
        }

        booster.deposit(pid, lpTokenAmt, true);

        User storage user = userInfo[msg.sender];
        user.lpTokenBalance += lpTokenAmt;
        user.rewardStartAt += (lpTokenAmt * accRewardPerlpToken / 1e36);

        emit Deposit(msg.sender, address(token), amount, lpTokenAmt);
    }

    function withdraw(
        IERC20Upgradeable token,
        uint lpTokenAmt,
        uint amountOutMin
    ) external payable override nonReentrant {
        require(token == weth || token == stETH || token == lpToken, "Invalid token");
        User storage user = userInfo[msg.sender];
        require(lpTokenAmt > 0 && user.lpTokenBalance >= lpTokenAmt, "Invalid lpTokenAmt");
        require(depositedBlock[msg.sender] != block.number, "Not allow withdraw within same block");

        harvest();

        user.lpTokenBalance = user.lpTokenBalance - lpTokenAmt;
        user.rewardStartAt = user.lpTokenBalance * accRewardPerlpToken / 1e36;
        gauge.withdrawAndUnwrap(lpTokenAmt, false);

        uint tokenAmt;
        if (token != lpToken) {
            int128 i;
            if (token == weth) i = 0;
            else i = 1; // steth
            tokenAmt = pool.remove_liquidity_one_coin(lpTokenAmt, i, amountOutMin);
        } else {
            tokenAmt = lpTokenAmt;
        }

        if (token == weth) {
            (bool success,) = msg.sender.call{value: tokenAmt}("");
            require(success, "ETH transfer failed");
        } else {
            token.transfer(msg.sender, tokenAmt);
        }

        emit Withdraw(msg.sender, address(token), lpTokenAmt, tokenAmt);
    }

    receive() external payable {}

    function harvest() public override {
        // Update accrued amount of aToken
        uint allPool = getAllPool();
        uint aTokenAmt = aToken.balanceOf(address(this));
        if (aTokenAmt > lastATokenAmt) {
            uint accruedAmt = aTokenAmt - lastATokenAmt;
            accRewardPerlpToken += (accruedAmt * 1e36 / allPool);
            lastATokenAmt = aTokenAmt;
        }

        gauge.getReward(address(this), true); // true = including extra reward

        uint crvAmt = crv.balanceOf(address(this));
        uint cvxAmt = cvx.balanceOf(address(this));
        uint ldoAmt = ldo.balanceOf(address(this));
        if (crvAmt > 1 ether || cvxAmt > 1 ether) {
            uint rewardTokenAmt;
            
            // Swap crv to rewardToken
            if (crvAmt > 1 ether) {
                ISwapRouter.ExactInputParams memory params = 
                ISwapRouter.ExactInputParams({
                    path: abi.encodePacked(address(crv), uint24(10000), address(weth), uint24(500), address(usdc)),
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: crvAmt,
                    amountOutMinimum: 0
                });
                rewardTokenAmt = swapRouter.exactInput(params);
                emit Harvest(address(crv), crvAmt, 0);
            }

            // Swap cvx to rewardToken
            if (cvxAmt > 1 ether) {
                ISwapRouter.ExactInputParams memory params = 
                    ISwapRouter.ExactInputParams({
                        path: abi.encodePacked(address(cvx), uint24(10000), address(weth), uint24(500), address(usdc)),
                        recipient: address(this),
                        deadline: block.timestamp,
                        amountIn: cvxAmt,
                        amountOutMinimum: 0
                    });
                rewardTokenAmt += swapRouter.exactInput(params);
                emit Harvest(address(cvx), cvxAmt, 0);
            }

            // Swap extra token to reward token
            if (ldoAmt > 1 ether) {
                address[] memory path = new address[](3);
                path[0] = address(ldo);
                path[1] = address(weth);
                path[2] = address(usdc);
                rewardTokenAmt += router.swapExactTokensForTokens(ldoAmt, 0, path, address(this), block.timestamp)[2];
                emit Harvest(address(ldo), ldoAmt, 0);
            }

            // Calculate fee
            uint fee = rewardTokenAmt * yieldFeePerc / 10000;
            emit Harvest(address(rewardToken), rewardTokenAmt, fee);
            rewardTokenAmt -= fee;
            rewardToken.transfer(treasury, fee);

            // Update accRewardPerlpToken
            accRewardPerlpToken += (rewardTokenAmt * 1e36 / allPool);

            // Deposit reward token into Aave to get interest bearing aToken
            lendingPool.deposit(address(rewardToken), rewardTokenAmt, address(this), 0);

            // Update lastATokenAmt
            lastATokenAmt = aToken.balanceOf(address(this));

            // Update accumulate reward token amount
            accRewardTokenAmt += rewardTokenAmt;
        }
    }

    function claim() public override nonReentrant {
        harvest();

        User storage user = userInfo[msg.sender];
        if (user.lpTokenBalance > 0) {
            // Calculate user reward
            uint aTokenAmt = (user.lpTokenBalance * accRewardPerlpToken / 1e36) - user.rewardStartAt;
            if (aTokenAmt > 0) {
                user.rewardStartAt += aTokenAmt;

                // Update lastATokenAmt
                if (lastATokenAmt >= aTokenAmt) {
                    lastATokenAmt -= aTokenAmt;
                } else {
                    // Last claim: to prevent arithmetic underflow error due to minor variation
                    lastATokenAmt = 0;
                }

                // Withdraw aToken to rewardToken
                uint aTokenBal = aToken.balanceOf(address(this));
                if (aTokenBal >= aTokenAmt) {
                    lendingPool.withdraw(address(rewardToken), aTokenAmt, address(this));
                } else {
                    // Last withdraw: to prevent withdrawal fail from lendingPool due to minor variation
                    lendingPool.withdraw(address(rewardToken), aTokenBal, address(this));
                }

                // Transfer rewardToken to user
                uint rewardTokenAmt = rewardToken.balanceOf(address(this));
                rewardToken.transfer(msg.sender, rewardTokenAmt);

                emit Claim(msg.sender, rewardTokenAmt);
            }
        }
    }

    function getPricePerFullShareInUSD() public view override returns (uint) {
        return pool.get_virtual_price() / 1e12; // 6 decimals
    }

    function getAllPool() public view override returns (uint) {
        // convex lpToken, 18 decimals
        // 1 convex lpToken == 1 curve lpToken
        return gauge.balanceOf(address(this));
    }

    function getAllPoolInUSD() external view override returns (uint) {
        uint allPool = getAllPool();
        if (allPool == 0) return 0;
        (, int latestPrice,,,) = ethUsdPriceOracle.latestRoundData();
        return allPool * getPricePerFullShareInUSD() * uint(latestPrice) / 1e26; // 6 decimals
    }

    function getPoolPendingReward() external view override returns (uint pendingCrv, uint pendingCvx) {
        pendingCrv = gauge.earned(address(this));
        // short calculation version of Convex.sol function mint()
        uint cliff = cvx.totalSupply() / 1e23;
        if (cliff < 1000) {
            uint reduction = 1000 - cliff;
            pendingCvx = pendingCrv * reduction / 1000;
        }
    }

    function getPoolExtraPendingReward() external view returns (uint) {
        return IGauge(gauge.extraRewards(0)).earned(address(this));
    }

    function getUserPendingReward(address account) external view override returns (uint) {
        User storage user = userInfo[account];
        return (user.lpTokenBalance * accRewardPerlpToken / 1e36) - user.rewardStartAt;
    }

    function getUserBalance(address account) external view override returns (uint) {
        return userInfo[account].lpTokenBalance;
    }

    function getUserBalanceInUSD(address account) external view override returns (uint) {
        (, int latestPrice,,,) = ethUsdPriceOracle.latestRoundData();
        return userInfo[account].lpTokenBalance * getPricePerFullShareInUSD() * uint(latestPrice) / 1e26;
    }
}