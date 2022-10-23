// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./PbAuraBase.sol";
import "../interface/IChainlink.sol";
import "../interface/IWeth.sol";
import "../interface/IWsteth.sol";

contract PbAuraWsteth is PbAuraBase {

    IERC20Upgradeable constant wsteth = IERC20Upgradeable(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
    IERC20Upgradeable constant ldo = IERC20Upgradeable(0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32);
    IChainlink constant ethUsdPriceOracle = IChainlink(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    IChainlink constant stethEthPriceOracle = IChainlink(0x86392dC19c0b719886221c78AB11eb8Cf5c52812);
    bytes32 constant poolId = 0x32296969ef14eb0c6d29669c550d4a0449130230000200000000000000000080; // wsteth/weth balancer
    
    function initialize(uint _pid, IERC20Upgradeable _rewardToken) external initializer {
        __Ownable_init();

        (address _lpToken,,, address _gauge) = booster.poolInfo(_pid);
        lpToken = IERC20Upgradeable(_lpToken);
        gauge = IGauge(_gauge);
        pid = _pid;
        rewardToken = _rewardToken;
        treasury = msg.sender;

        (,,,,,,, address aTokenAddr,,,,) = lendingPool.getReserveData(address(rewardToken));
        aToken = IERC20Upgradeable(aTokenAddr);

        bal.approve(address(balancer), type(uint).max);
        aura.approve(address(balancer), type(uint).max);
        ldo.approve(address(balancer), type(uint).max);
        weth.approve(address(balancer), type(uint).max);
        weth.approve(address(zap), type(uint).max);
        wsteth.approve(address(zap), type(uint).max);
        lpToken.approve(address(booster), type(uint).max);
        rewardToken.approve(address(lendingPool), type(uint).max);
    }

    function deposit(
        IERC20Upgradeable token,
        uint amount,
        uint amountOutMin
    ) external payable override nonReentrant whenNotPaused {
        require(token == weth || token == wsteth || token == lpToken, "Invalid token");
        require(amount > 0, "Invalid amount");

        uint currentPool = gauge.balanceOf(address(this));
        if (currentPool > 0) harvest();

        uint lpTokenAmt;
        if (token != lpToken) {
            uint[] memory maxAmountsIn = new uint[](2);
            if (token == weth) {
                require(msg.value == amount, "Invalid ETH");
                IWeth(address(weth)).deposit{value: msg.value}();
                maxAmountsIn[1] = amount;
            } else {
                token.transferFrom(msg.sender, address(this), amount);
                maxAmountsIn[0] = amount;
            }
            depositedBlock[msg.sender] = block.number;

            IBalancer.JoinPoolRequest memory request = IBalancer.JoinPoolRequest({
                assets: _getAssets(),
                maxAmountsIn: maxAmountsIn,
                userData: abi.encode(IBalancer.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, maxAmountsIn, amountOutMin),
                fromInternalBalance: false
            });
            zap.depositSingle(address(gauge), address(token), amount, poolId, request);
            lpTokenAmt = gauge.balanceOf(address(this)) - currentPool;

        } else { // token == lpToken
            lpToken.transferFrom(msg.sender, address(this), amount);
            booster.deposit(pid, amount, true);
            lpTokenAmt = amount;
        }

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
        require(token == weth || token == wsteth || token == lpToken, "Invalid token");
        User storage user = userInfo[msg.sender];
        require(lpTokenAmt > 0 && user.lpTokenBalance >= lpTokenAmt, "Invalid lpTokenAmt");
        require(depositedBlock[msg.sender] != block.number, "Not allow withdraw within same block");

        harvest();

        user.lpTokenBalance = user.lpTokenBalance - lpTokenAmt;
        user.rewardStartAt = user.lpTokenBalance * accRewardPerlpToken / 1e36;
        gauge.withdrawAndUnwrap(lpTokenAmt, false);

        uint tokenAmt;
        if (token != lpToken) {
            uint[] memory minAmountsOut = new uint[](2);
            uint exitTokenIndex;
            if (token == weth) {
                minAmountsOut[1] = amountOutMin;
                exitTokenIndex = 1;
            } else {
                minAmountsOut[0] = amountOutMin;
                exitTokenIndex = 0;
            }

            IBalancer.ExitPoolRequest memory request = IBalancer.ExitPoolRequest({
                assets: _getAssets(),
                minAmountsOut: minAmountsOut,
                userData: abi.encode(
                    IBalancer.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
                    lpTokenAmt,
                    exitTokenIndex
                ),
                toInternalBalance: false 
            });
            balancer.exitPool(poolId, address(this), payable(address(this)), request);

            tokenAmt = token.balanceOf(address(this));
            if (token == weth) {
                IWeth(address(weth)).withdraw(tokenAmt);
                (bool success,) = msg.sender.call{value: tokenAmt}("");
                require(success, "ETH transfer failed");
            } else {
                token.transfer(msg.sender, tokenAmt);
            }

        } else { // token == lpToken
            lpToken.transfer(msg.sender, lpTokenAmt);
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

        uint balAmt = bal.balanceOf(address(this));
        uint auraAmt = aura.balanceOf(address(this));
        uint ldoAmt = ldo.balanceOf(address(this));
        if (balAmt > 1 ether || auraAmt > 1 ether) {
            uint wethAmt;
            
            // Swap bal to weth
            if (balAmt > 1 ether) {
                wethAmt = _swap(
                    0x5c6ee304399dbdb9c8ef030ab642b10820db8f56000200000000000000000014,
                    address(bal),
                    address(weth),
                    balAmt
                );

                emit Harvest(address(bal), balAmt, 0);
            }

            // Swap aura to weth
            if (auraAmt > 1 ether) {
                wethAmt += _swap(
                    0xc29562b045d80fd77c69bec09541f5c16fe20d9d000200000000000000000251,
                    address(aura),
                    address(weth),
                    auraAmt
                );

                emit Harvest(address(aura), auraAmt, 0);
            }

            // Swap extra token to weth if any
            if (ldoAmt > 1 ether) {
                wethAmt += _swap(
                    0xbf96189eee9357a95c7719f4f5047f76bde804e5000200000000000000000087,
                    address(ldo),
                    address(weth),
                    ldoAmt
                );

                emit Harvest(address(ldo), ldoAmt, 0);
            }

            // Swap weth to reward token
            uint rewardTokenAmt = _swap(
                0x96646936b91d6b9d7d0c47c496afbf3d6ec7b6f8000200000000000000000019,
                address(weth),
                address(usdc),
                wethAmt
            );

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

    function _swap(bytes32 _poolId, address tokenIn, address tokenOut, uint amount) private returns (uint amountOut) {
        IBalancer.SingleSwap memory singleSwap = IBalancer.SingleSwap({
            poolId: _poolId,
            kind: IBalancer.SwapKind.GIVEN_IN,
            assetIn: tokenIn,
            assetOut: tokenOut,
            amount: amount,
            userData: ""
        });
        IBalancer.FundManagement memory funds = IBalancer.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: address(this),
            toInternalBalance: false
        });
        amountOut = balancer.swap(singleSwap, funds, 0, block.timestamp);
    }

    function _getAssets() private pure returns (address[] memory assets) {
        assets = new address[](2);
        assets[0] = address(wsteth);
        assets[1] = address(weth);
    }

    function getPricePerFullShareInUSD() public view override returns (uint) {
        // balances = [token0Balance, token1Balance]
        (, uint[] memory balances,) = balancer.getPoolTokens(poolId);
        // get eth amount by get steth amount from wsteth, multiple by steth price in eth
        uint stethAmt = IWsteth(address(wsteth)).getStETHByWstETH(balances[0]);
        (, int latestPrice,,,) = stethEthPriceOracle.latestRoundData(); // return 18 decimals
        uint ethAmt = stethAmt * uint(latestPrice) / 1 ether;
        // ethAmt = wsteth amount in eth, balances[1] = weth amount
        return (ethAmt + balances[1]) * 1 ether / lpToken.totalSupply();
    }

    ///@notice return 18 decimals
    function getAllPool() public view override returns (uint) {
        // gauge.balanceOf return aura lpToken amount, 18 decimals
        // 1 aura lpToken == 1 bal lpToken (bpt)
        return gauge.balanceOf(address(this));
    }

    ///@notice return 6 decimals
    function getAllPoolInUSD() external view override returns (uint) {
        uint allPool = getAllPool();
        if (allPool == 0) return 0;
        (, int latestPrice,,,) = ethUsdPriceOracle.latestRoundData();
        return allPool * getPricePerFullShareInUSD() * uint(latestPrice) / 1e38;
    }

    function getPoolPendingReward() external view override returns (uint pendingBal, uint pendingAura) {
        pendingBal = gauge.earned(address(this));

        // short calculation version of Aura.sol function mint()
        uint cliff = (aura.totalSupply() - 5e25) / 1e23;
        if (cliff < 500) {
            uint reduction = (500 - cliff) * 5 / 2 + 700;
            pendingAura = pendingBal * reduction / 500;
        }
    }

    function getPoolExtraPendingReward() external view returns (uint) {
        return IGauge(gauge.extraRewards(0)).earned(address(this));
    }

    function getUserPendingReward(address account) external view override returns (uint) {
        User storage user = userInfo[account];
        return (user.lpTokenBalance * accRewardPerlpToken / 1e36) - user.rewardStartAt;
    }

    ///@notice return 18 decimals
    function getUserBalance(address account) external view override returns (uint) {
        return userInfo[account].lpTokenBalance;
    }

    ///@notice return 6 decimals
    function getUserBalanceInUSD(address account) external view override returns (uint) {
        (, int latestPrice,,,) = ethUsdPriceOracle.latestRoundData();
        return userInfo[account].lpTokenBalance * getPricePerFullShareInUSD() * uint(latestPrice) / 1e38;
    }
}