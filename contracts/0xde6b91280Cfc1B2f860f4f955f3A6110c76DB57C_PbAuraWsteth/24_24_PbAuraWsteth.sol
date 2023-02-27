// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./PbAuraBase.sol";
import "../interface/IChainlink.sol";
import "../interface/IWeth.sol";
import "../interface/IWsteth.sol";

contract PbAuraWsteth is PbAuraBase {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable constant WSTETH = IERC20Upgradeable(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
    IERC20Upgradeable constant LDO = IERC20Upgradeable(0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32);
    IChainlink constant ETH_USD_PRICE_ORACLE = IChainlink(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    IChainlink constant STETH_ETH_PRICE_ORACLE = IChainlink(0x86392dC19c0b719886221c78AB11eb8Cf5c52812);
    bytes32 constant POOL_ID = 0x32296969ef14eb0c6d29669c550d4a0449130230000200000000000000000080; // WSTETH/WETH BALANCER
    
    function initialize(uint pid_, IERC20Upgradeable rewardToken_) external initializer {
        __Ownable_init();

        (address _lpToken,,, address _gauge) = BOOSTER.poolInfo(pid_);
        lpToken = IERC20Upgradeable(_lpToken);
        gauge = IGauge(_gauge);
        pid = pid_;
        rewardToken = rewardToken_;
        treasury = msg.sender;

        (,,,,,,, address aTokenAddr) = LENDING_POOL.getReserveData(address(rewardToken));
        aToken = IERC20Upgradeable(aTokenAddr);

        BAL.safeApprove(address(BALANCER), type(uint).max);
        AURA.safeApprove(address(BALANCER), type(uint).max);
        LDO.safeApprove(address(BALANCER), type(uint).max);
        WETH.safeApprove(address(BALANCER), type(uint).max);
        WETH.safeApprove(address(ZAP), type(uint).max);
        WSTETH.safeApprove(address(ZAP), type(uint).max);
        lpToken.safeApprove(address(BOOSTER), type(uint).max);
        rewardToken.safeApprove(address(LENDING_POOL), type(uint).max);
    }

    function deposit(
        IERC20Upgradeable token,
        uint amount,
        uint amountOutMin
    ) external payable override nonReentrant whenNotPaused {
        require(token == WETH || token == WSTETH || token == lpToken, "Invalid token");
        require(amount > 0, "Invalid amount");

        uint currentPool = gauge.balanceOf(address(this));
        if (currentPool > 0) harvest();

        uint lpTokenAmt;
        if (token != lpToken) {
            uint[] memory maxAmountsIn = new uint[](2);
            if (token == WETH) {
                require(msg.value == amount, "Invalid ETH");
                IWeth(address(WETH)).deposit{value: msg.value}();
                maxAmountsIn[1] = amount;
            } else {
                token.safeTransferFrom(msg.sender, address(this), amount);
                maxAmountsIn[0] = amount;
            }
            depositedBlock[msg.sender] = block.number;

            IBalancer.JoinPoolRequest memory request = IBalancer.JoinPoolRequest({
                assets: _getAssets(),
                maxAmountsIn: maxAmountsIn,
                userData: abi.encode(IBalancer.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, maxAmountsIn, amountOutMin),
                fromInternalBalance: false
            });
            ZAP.depositSingle(address(gauge), address(token), amount, POOL_ID, request);
            lpTokenAmt = gauge.balanceOf(address(this)) - currentPool;

        } else { // token == lpToken
            lpToken.safeTransferFrom(msg.sender, address(this), amount);
            BOOSTER.deposit(pid, amount, true);
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
        require(token == WETH || token == WSTETH || token == lpToken, "Invalid token");
        User storage user = userInfo[msg.sender];
        require(lpTokenAmt > 0 && user.lpTokenBalance >= lpTokenAmt, "Invalid lpTokenAmt");
        require(depositedBlock[msg.sender] != block.number, "Not allow withdraw within same block");

        harvest();

        user.lpTokenBalance = user.lpTokenBalance - lpTokenAmt;
        user.rewardStartAt = user.lpTokenBalance * accRewardPerlpToken / 1e36;
        gauge.withdrawAndUnwrap(lpTokenAmt, false);

        uint tokenAmt = 0;
        if (token != lpToken) {
            uint[] memory minAmountsOut = new uint[](2);
            uint exitTokenIndex;
            if (token == WETH) {
                minAmountsOut[1] = amountOutMin;
                exitTokenIndex = 1;
            } else { // WSTETH
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
            BALANCER.exitPool(POOL_ID, address(this), payable(address(this)), request);

            tokenAmt = token.balanceOf(address(this));
            if (token == WETH) {
                IWeth(address(WETH)).withdraw(tokenAmt);
                (bool success,) = msg.sender.call{value: tokenAmt}("");
                require(success, "ETH transfer failed");
            } else { // WSTETH
                token.safeTransfer(msg.sender, tokenAmt);
            }

        } else { // token == lpToken
            lpToken.safeTransfer(msg.sender, lpTokenAmt);
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

        uint balAmt = BAL.balanceOf(address(this));
        uint auraAmt = AURA.balanceOf(address(this));
        uint ldoAmt = LDO.balanceOf(address(this));
        if (balAmt > 1 ether || auraAmt > 1 ether) {
            uint wethAmt = 0;
            
            // Swap BAL to WETH
            if (balAmt > 1 ether) {
                wethAmt = _swap(
                    0x5c6ee304399dbdb9c8ef030ab642b10820db8f56000200000000000000000014,
                    address(BAL),
                    address(WETH),
                    balAmt
                );

                emit Harvest(address(BAL), balAmt, 0);
            }

            // Swap AURA to WETH
            if (auraAmt > 1 ether) {
                wethAmt += _swap(
                    0xc29562b045d80fd77c69bec09541f5c16fe20d9d000200000000000000000251,
                    address(AURA),
                    address(WETH),
                    auraAmt
                );

                emit Harvest(address(AURA), auraAmt, 0);
            }

            // Swap extra token to WETH if any
            if (ldoAmt > 1 ether) {
                wethAmt += _swap(
                    0xbf96189eee9357a95c7719f4f5047f76bde804e5000200000000000000000087,
                    address(LDO),
                    address(WETH),
                    ldoAmt
                );

                emit Harvest(address(LDO), ldoAmt, 0);
            }

            // Swap WETH to reward token
            uint rewardTokenAmt = _swap(
                0x96646936b91d6b9d7d0c47c496afbf3d6ec7b6f8000200000000000000000019,
                address(WETH),
                address(USDC),
                wethAmt
            );

            // Calculate fee
            uint fee = rewardTokenAmt * yieldFeePerc / 10000;
            emit Harvest(address(rewardToken), rewardTokenAmt, fee);
            rewardTokenAmt -= fee;
            rewardToken.safeTransfer(treasury, fee);

            // Update accRewardPerlpToken
            accRewardPerlpToken += (rewardTokenAmt * 1e36 / allPool);

            // Deposit reward token into Aave to get interest bearing aToken
            LENDING_POOL.deposit(address(rewardToken), rewardTokenAmt, address(this), 0);

            // Update lastATokenAmt
            lastATokenAmt = aToken.balanceOf(address(this));
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
                    LENDING_POOL.withdraw(address(rewardToken), aTokenAmt, address(this));
                } else {
                    // Last withdraw: to prevent withdrawal fail from LENDING_POOL due to minor variation
                    LENDING_POOL.withdraw(address(rewardToken), aTokenBal, address(this));
                }

                // Transfer rewardToken to user
                uint rewardTokenAmt = rewardToken.balanceOf(address(this));
                rewardToken.safeTransfer(msg.sender, rewardTokenAmt);

                emit Claim(msg.sender, rewardTokenAmt);
            }
        }
    }

    function _swap(bytes32 poolId_, address tokenIn, address tokenOut, uint amount) private returns (uint amountOut) {
        IBalancer.SingleSwap memory singleSwap = IBalancer.SingleSwap({
            poolId: poolId_,
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
        amountOut = BALANCER.swap(singleSwap, funds, 0, block.timestamp);
    }

    function _getAssets() private pure returns (address[] memory assets) {
        assets = new address[](2);
        assets[0] = address(WSTETH);
        assets[1] = address(WETH);
    }

    function getPricePerFullShareInUSD() public view override returns (uint) {
        // balances = [token0Balance, token1Balance]
        (, uint[] memory balances,) = BALANCER.getPoolTokens(POOL_ID);
        // get eth amount by get steth amount from WSTETH, multiple by steth price in eth
        uint stethAmt = IWsteth(address(WSTETH)).getStETHByWstETH(balances[0]);
        (, int latestPrice,,,) = STETH_ETH_PRICE_ORACLE.latestRoundData(); // return 18 decimals
        uint ethAmt = stethAmt * uint(latestPrice) / 1 ether;
        // ethAmt = WSTETH amount in eth, balances[1] = WETH amount
        return (ethAmt + balances[1]) * 1 ether / lpToken.totalSupply();
    }

    ///@notice return 18 decimals
    function getAllPool() public view override returns (uint) {
        // gauge.balanceOf return AURA lpToken amount, 18 decimals
        // 1 AURA lpToken == 1 BAL lpToken (bpt)
        return gauge.balanceOf(address(this));
    }

    ///@notice return 6 decimals
    function getAllPoolInUSD() external view override returns (uint allPoolInUSD) {
        uint allPool = getAllPool();
        if (allPool > 0) {
            (, int latestPrice,,,) = ETH_USD_PRICE_ORACLE.latestRoundData();
            allPoolInUSD = allPool * getPricePerFullShareInUSD() * uint(latestPrice) / 1e38;
        }
    }

    function getPoolPendingReward() external view override returns (uint pendingBal, uint pendingAura) {
        pendingBal = gauge.earned(address(this));

        // short calculation version of AURA.sol function mint()
        uint cliff = (AURA.totalSupply() - 5e25) / 1e23;
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
        (, int latestPrice,,,) = ETH_USD_PRICE_ORACLE.latestRoundData();
        return userInfo[account].lpTokenBalance * getPricePerFullShareInUSD() * uint(latestPrice) / 1e38;
    }
}