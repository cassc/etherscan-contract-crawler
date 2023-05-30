// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.18;

import {BaseStrategy, StrategyParams} from "@yearn-protocol/contracts/BaseStrategy.sol";

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../integrations/balancer/IBalancerV2Vault.sol";
import "../integrations/balancer/IBalancerPool.sol";
import "../integrations/balancer/IBalancerPriceOracle.sol";
import "../integrations/convex/IConvexDeposit.sol";
import "../integrations/convex/IConvexRewards.sol";

import "../utils/AuraMath.sol";
import "../utils/Utils.sol";

contract AuraWETHStrategy is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using AuraMath for uint256;

    IBalancerV2Vault internal constant balancerVault =
        IBalancerV2Vault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    address internal constant USDC_WETH_BALANCER_POOL =
        0x96646936b91d6B9D7D0c47C496AfBF3D6ec7B6f8;
    address internal constant STABLE_POOL_BALANCER_POOL =
        0x79c58f70905F734641735BC61e45c19dD9Ad60bC;
    address internal constant WETH_AURA_BALANCER_POOL =
        0xCfCA23cA9CA720B6E98E3Eb9B6aa0fFC4a5C08B9;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant AURA = 0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF;
    address internal constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
    address internal constant AURA_BOOSTER =
        0xA57b8d98dAE62B26Ec3bcC4a365338157060B234;
    address internal constant AURA_WETH_REWARDS =
        0x712CC5BeD99aA06fC4D5FB50Aea3750fA5161D0f;
    address internal constant WETH_BAL_BALANCER_POOL =
        0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56;

    bytes32 internal constant WETH_3POOL_BALANCER_POOL_ID =
        0x08775ccb6674d6bdceb0797c364c2653ed84f3840002000000000000000004f0;
    bytes32 internal constant STABLE_POOL_BALANCER_POOL_ID =
        0x79c58f70905f734641735bc61e45c19dd9ad60bc0000000000000000000004e7;
    bytes32 internal constant WETH_AURA_BALANCER_POOL_ID =
        0xcfca23ca9ca720b6e98e3eb9b6aa0ffc4a5c08b9000200000000000000000274;
    bytes32 internal constant WETH_BAL_BALANCER_POOL_ID =
        0x5c6ee304399dbdb9c8ef030ab642b10820db8f56000200000000000000000014;

    uint32 internal constant TWAP_RANGE_SECS = 1800;
    uint256 public slippage = 9700; // 3%

    constructor(address _vault) BaseStrategy(_vault) {
        want.approve(address(balancerVault), type(uint256).max);
        ERC20(BAL).approve(address(balancerVault), type(uint256).max);
        ERC20(AURA).approve(address(balancerVault), type(uint256).max);
        ERC20(WETH).approve(address(balancerVault), type(uint256).max);
        ERC20(WETH_AURA_BALANCER_POOL).approve(
            address(balancerVault),
            type(uint256).max
        );
        ERC20(WETH_AURA_BALANCER_POOL).approve(AURA_BOOSTER, type(uint256).max);
    }

    function name() external pure override returns (string memory) {
        return "StrategyAuraWETH";
    }

    function setSlippage(uint256 _slippage) external onlyStrategist {
        require(_slippage < 10_000, "!_slippage");
        slippage = _slippage;
    }

    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    function balanceOfUnstakedBpt() public view returns (uint256) {
        return IERC20(WETH_AURA_BALANCER_POOL).balanceOf(address(this));
    }

    function balRewards() public view returns (uint256) {
        return IConvexRewards(AURA_WETH_REWARDS).earned(address(this));
    }

    function balanceOfAuraBpt() public view returns (uint256) {
        return IERC20(AURA_WETH_REWARDS).balanceOf(address(this));
    }

    function auraRewards() public view returns (uint256) {
        return AuraRewardsMath.convertCrvToCvx(balRewards());
    }

    function auraBptToBpt(uint _amountAuraBpt) public pure returns (uint256) {
        return _amountAuraBpt;
    }

    function auraToWant(uint256 auraTokens) public view returns (uint256) {
        uint256 scaledAmount = Utils.scaleDecimals(
            auraTokens,
            ERC20(AURA),
            ERC20(address(want))
        );
        return
            scaledAmount.mul(getAuraPrice()).div(
                10 ** ERC20(address(want)).decimals()
            );
    }

    function balToWant(uint256 balTokens) public view returns (uint256) {
        uint256 scaledAmount = Utils.scaleDecimals(
            balTokens,
            ERC20(AURA),
            ERC20(address(want))
        );
        return
            scaledAmount.mul(getBalPrice()).div(
                10 ** ERC20(address(want)).decimals()
            );
    }

    function wantToBpt(
        uint _amountWant
    ) public view virtual returns (uint _amount) {
        uint256 oneBptPrice = bptToWant(1 ether);
        uint256 bptAmountUnscaled = (_amountWant *
            10 ** ERC20(address(want)).decimals()) / oneBptPrice;
        return
            Utils.scaleDecimals(
                bptAmountUnscaled,
                ERC20(address(want)),
                ERC20(WETH_AURA_BALANCER_POOL)
            );
    }

    function bptToWant(uint bptTokens) public view returns (uint _amount) {
        uint scaledAmount = Utils.scaleDecimals(
            bptTokens,
            ERC20(WETH_AURA_BALANCER_POOL),
            ERC20(address(want))
        );
        return
            scaledAmount.mul(getBptPrice()).div(
                10 ** ERC20(address(want)).decimals()
            );
    }

    function estimatedTotalAssets()
        public
        view
        virtual
        override
        returns (uint256 _wants)
    {
        _wants = balanceOfWant();

        uint256 bptTokens = balanceOfUnstakedBpt() +
            auraBptToBpt(balanceOfAuraBpt());
        _wants += bptToWant(bptTokens);
        uint256 balTokens = balRewards() + ERC20(BAL).balanceOf(address(this));
        if (balTokens > 0) {
            _wants += balToWant(balTokens);
        }

        uint256 auraTokens = auraRewards() +
            ERC20(AURA).balanceOf(address(this));
        if (auraTokens > 0) {
            _wants += auraToWant(auraTokens);
        }

        return _wants;
    }

    function getBalPrice() public view returns (uint256 price) {
        address priceOracle = 0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56;
        IBalancerPriceOracle.OracleAverageQuery[] memory queries;
        queries = new IBalancerPriceOracle.OracleAverageQuery[](1);
        queries[0] = IBalancerPriceOracle.OracleAverageQuery({
            variable: IBalancerPriceOracle.Variable.PAIR_PRICE,
            secs: TWAP_RANGE_SECS,
            ago: 0
        });
        uint256[] memory results = IBalancerPriceOracle(priceOracle)
            .getTimeWeightedAverage(queries);
        price = 1e36 / results[0];
        return ethToWant(price);
    }

    function getAuraPrice() public view returns (uint256 price) {
        address priceOracle = 0xc29562b045D80fD77c69Bec09541F5c16fe20d9d;
        IBalancerPriceOracle.OracleAverageQuery[] memory queries;
        queries = new IBalancerPriceOracle.OracleAverageQuery[](1);
        queries[0] = IBalancerPriceOracle.OracleAverageQuery({
            variable: IBalancerPriceOracle.Variable.PAIR_PRICE,
            secs: TWAP_RANGE_SECS,
            ago: 0
        });
        uint256[] memory results;
        results = IBalancerPriceOracle(priceOracle).getTimeWeightedAverage(
            queries
        );
        price = results[0];
        return ethToWant(price);
    }

    /// @notice Safely returns price of LP WETH-50/AURA-50 BPT token in arbitrary want tokens.
    /// @dev This function is intended to be safe against flash loan attacks.
    /// @dev Inspired by formula from Balancer docs: https://docs.balancer.fi/concepts/advanced/valuing-bpt.html
    /// @return price Price of LP BPT token in USDC want tokens.
    function getBptPrice() public view returns (uint256 price) {
        uint256 invariant = IBalancerPool(WETH_AURA_BALANCER_POOL)
            .getInvariant();
        uint256 totalSupply = IERC20(WETH_AURA_BALANCER_POOL).totalSupply();
        uint256 ratio = (invariant * 1e18) / totalSupply;

        uint256 auraComponent = Math.sqrt(2 * getAuraPrice());
        uint256 wethComponent = Math.sqrt(2 * ethToWant(1 ether));

        return
            (Utils.scaleDecimals(ratio, ERC20(WETH), ERC20(address(want))) *
                auraComponent *
                wethComponent) / (10 ** ERC20(address(want)).decimals());
    }

    function prepareReturn(
        uint256 _debtOutstanding
    )
        internal
        override
        returns (uint256 _profit, uint256 _loss, uint256 _debtPayment)
    {
        uint256 _totalAssets = estimatedTotalAssets();
        uint256 _totalDebt = vault.strategies(address(this)).totalDebt;

        if (_totalAssets >= _totalDebt) {
            _profit = _totalAssets - _totalDebt;
            _loss = 0;
        } else {
            _profit = 0;
            _loss = _totalDebt - _totalAssets;
        }

        withdrawSome(_debtOutstanding + _profit);

        uint256 _liquidWant = want.balanceOf(address(this));

        // enough to pay profit (partial or full) only
        if (_liquidWant <= _profit) {
            _profit = _liquidWant;
            _debtPayment = 0;
            // enough to pay for all profit and _debtOutstanding (partial or full)
        } else {
            _debtPayment = Math.min(_liquidWant - _profit, _debtOutstanding);
        }
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        if (balRewards() > 0) {
            IConvexRewards(AURA_WETH_REWARDS).getReward(address(this), true);
        }
        _sellBalAndAura(
            IERC20(BAL).balanceOf(address(this)),
            IERC20(AURA).balanceOf(address(this))
        );

        uint256 _wantBal = want.balanceOf(address(this));
        if (_wantBal > _debtOutstanding) {
            uint256 _excessWant = _wantBal - _debtOutstanding;

            if (_excessWant > 0) {
                IBalancerV2Vault.BatchSwapStep[]
                    memory swaps = new IBalancerV2Vault.BatchSwapStep[](2);

                swaps[0] = IBalancerV2Vault.BatchSwapStep({
                    poolId: STABLE_POOL_BALANCER_POOL_ID,
                    assetInIndex: 0,
                    assetOutIndex: 1,
                    amount: _wantBal,
                    userData: abi.encode(0)
                });

                swaps[1] = IBalancerV2Vault.BatchSwapStep({
                    poolId: WETH_3POOL_BALANCER_POOL_ID,
                    assetInIndex: 1,
                    assetOutIndex: 2,
                    amount: 0,
                    userData: abi.encode(0)
                });

                address[] memory assets = new address[](3);
                assets[0] = address(want);
                assets[1] = STABLE_POOL_BALANCER_POOL;
                assets[2] = WETH;

                uint256 wethExpected = (_excessWant *
                    10 ** ERC20(address(want)).decimals()) / ethToWant(1 ether);

                int[] memory limits = new int[](3);
                limits[0] = int(_excessWant);
                limits[1] = 0;
                limits[2] = -1 * int((wethExpected * slippage) / 10000);

                balancerVault.batchSwap(
                    IBalancerV2Vault.SwapKind.GIVEN_IN,
                    swaps,
                    assets,
                    getFundManagement(),
                    limits,
                    block.timestamp
                );
            }
        }

        uint256 wethBalance = IERC20(WETH).balanceOf(address(this));
        if (wethBalance > 0) {
            uint256[] memory _amountsIn = new uint256[](2);
            _amountsIn[0] = wethBalance;
            _amountsIn[1] = 0;

            address[] memory _assets = new address[](2);
            _assets[0] = WETH;
            _assets[1] = AURA;

            uint256[] memory _maxAmountsIn = new uint256[](2);
            _maxAmountsIn[0] = wethBalance;
            _maxAmountsIn[1] = 0;

            uint256 _bptExpected = (ethToWant(wethBalance) /
                bptToWant(1 ether)) * (10 ** ERC20(address(want)).decimals());
            bytes memory _userData = abi.encode(
                IBalancerV2Vault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
                _amountsIn,
                (_bptExpected * slippage) / 10000
            );

            IBalancerV2Vault.JoinPoolRequest memory _request;
            _request = IBalancerV2Vault.JoinPoolRequest({
                assets: _assets,
                maxAmountsIn: _maxAmountsIn,
                userData: _userData,
                fromInternalBalance: false
            });

            balancerVault.joinPool({
                poolId: WETH_AURA_BALANCER_POOL_ID,
                sender: address(this),
                recipient: payable(address(this)),
                request: _request
            });
        }

        if (balanceOfUnstakedBpt() > 0) {
            bool auraSuccess = IConvexDeposit(AURA_BOOSTER).depositAll(
                0, // PID
                true // stake
            );
            require(auraSuccess, "Aura deposit failed");
        }
    }

    function _sellBalAndAura(uint256 _balAmount, uint256 _auraAmount) internal {
        if (_auraAmount > 0) {
            IBalancerV2Vault.BatchSwapStep[]
                memory swaps = new IBalancerV2Vault.BatchSwapStep[](3);

            swaps[0] = IBalancerV2Vault.BatchSwapStep({
                poolId: WETH_AURA_BALANCER_POOL_ID,
                assetInIndex: 0,
                assetOutIndex: 1,
                amount: _auraAmount,
                userData: abi.encode(0)
            });

            swaps[1] = IBalancerV2Vault.BatchSwapStep({
                poolId: WETH_3POOL_BALANCER_POOL_ID,
                assetInIndex: 1,
                assetOutIndex: 2,
                amount: 0,
                userData: abi.encode(0)
            });

            swaps[2] = IBalancerV2Vault.BatchSwapStep({
                poolId: STABLE_POOL_BALANCER_POOL_ID,
                assetInIndex: 2,
                assetOutIndex: 3,
                amount: 0,
                userData: abi.encode(0)
            });

            address[] memory assets = new address[](4);
            assets[0] = AURA;
            assets[1] = WETH;
            assets[2] = STABLE_POOL_BALANCER_POOL;
            assets[3] = address(want);

            int[] memory limits = new int[](4);
            limits[0] = int256(_auraAmount);
            limits[3] =
                (-1) *
                int((auraToWant(_auraAmount) * slippage) / 10000);

            balancerVault.batchSwap(
                IBalancerV2Vault.SwapKind.GIVEN_IN,
                swaps,
                assets,
                getFundManagement(),
                limits,
                block.timestamp
            );
        }

        if (_balAmount > 0) {
            IBalancerV2Vault.BatchSwapStep[]
                memory swaps = new IBalancerV2Vault.BatchSwapStep[](3);

            swaps[0] = IBalancerV2Vault.BatchSwapStep({
                poolId: WETH_BAL_BALANCER_POOL_ID,
                assetInIndex: 0,
                assetOutIndex: 1,
                amount: _balAmount,
                userData: abi.encode(0)
            });

            swaps[1] = IBalancerV2Vault.BatchSwapStep({
                poolId: WETH_3POOL_BALANCER_POOL_ID,
                assetInIndex: 1,
                assetOutIndex: 2,
                amount: 0,
                userData: abi.encode(0)
            });

            swaps[2] = IBalancerV2Vault.BatchSwapStep({
                poolId: STABLE_POOL_BALANCER_POOL_ID,
                assetInIndex: 2,
                assetOutIndex: 3,
                amount: 0,
                userData: abi.encode(0)
            });

            address[] memory assets = new address[](4);
            assets[0] = BAL;
            assets[1] = WETH;
            assets[2] = STABLE_POOL_BALANCER_POOL;
            assets[3] = address(want);

            int[] memory limits = new int[](4);
            limits[0] = int256(_balAmount);
            limits[3] = (-1) * int((balToWant(_balAmount) * slippage) / 10000);

            balancerVault.batchSwap(
                IBalancerV2Vault.SwapKind.GIVEN_IN,
                swaps,
                assets,
                getFundManagement(),
                limits,
                block.timestamp
            );
        }
    }

    function withdrawSome(uint256 _amountNeeded) internal {
        if (_amountNeeded == 0) {
            return;
        }

        uint256 balTokens = balRewards() + ERC20(BAL).balanceOf(address(this));
        uint256 auraTokens = auraRewards() +
            ERC20(AURA).balanceOf(address(this));
        uint256 rewardsTotal = balToWant(balTokens) + auraToWant(auraTokens);

        if (rewardsTotal >= _amountNeeded) {
            IConvexRewards(AURA_WETH_REWARDS).getReward(address(this), true);
            _sellBalAndAura(
                IERC20(BAL).balanceOf(address(this)),
                IERC20(AURA).balanceOf(address(this))
            );
        } else {
            uint256 bptToUnstake = Math.min(
                wantToBpt(_amountNeeded - rewardsTotal),
                balanceOfAuraBpt()
            );

            if (bptToUnstake > 0) {
                _exitPosition(bptToUnstake);
            }
        }
    }

    function liquidatePosition(
        uint256 _amountNeeded
    ) internal override returns (uint256 _liquidatedAmount, uint256 _loss) {
        uint256 _wantBal = want.balanceOf(address(this));
        if (_wantBal >= _amountNeeded) {
            return (_amountNeeded, 0);
        }

        withdrawSome(_amountNeeded);

        _wantBal = want.balanceOf(address(this));
        if (_amountNeeded > _wantBal) {
            _liquidatedAmount = _wantBal;
            _loss = _amountNeeded - _wantBal;
        } else {
            _liquidatedAmount = _amountNeeded;
        }
    }

    function liquidateAllPositions() internal override returns (uint256) {
        IConvexRewards(AURA_WETH_REWARDS).getReward(address(this), true);
        _sellBalAndAura(
            IERC20(BAL).balanceOf(address(this)),
            IERC20(AURA).balanceOf(address(this))
        );
        _exitPosition(IERC20(AURA_WETH_REWARDS).balanceOf(address(this)));
        return want.balanceOf(address(this));
    }

    function _sellWethForWant() internal {
        uint256 wethBal = IERC20(WETH).balanceOf(address(this));

        if (wethBal > 0) {
            IBalancerV2Vault.BatchSwapStep[]
                memory swaps = new IBalancerV2Vault.BatchSwapStep[](2);

            swaps[0] = IBalancerV2Vault.BatchSwapStep({
                poolId: WETH_3POOL_BALANCER_POOL_ID,
                assetInIndex: 0,
                assetOutIndex: 1,
                amount: wethBal,
                userData: abi.encode(0)
            });

            swaps[1] = IBalancerV2Vault.BatchSwapStep({
                poolId: STABLE_POOL_BALANCER_POOL_ID,
                assetInIndex: 1,
                assetOutIndex: 2,
                amount: 0,
                userData: abi.encode(0)
            });

            address[] memory assets = new address[](3);
            assets[0] = WETH;
            assets[1] = STABLE_POOL_BALANCER_POOL;
            assets[2] = address(want);

            int[] memory limits = new int[](3);
            limits[0] = int256(wethBal);
            limits[2] = (-1) * int((ethToWant(wethBal) * slippage) / 10000);

            balancerVault.batchSwap(
                IBalancerV2Vault.SwapKind.GIVEN_IN,
                swaps,
                assets,
                getFundManagement(),
                limits,
                block.timestamp
            );
        }
    }

    function _exitPosition(uint256 bptAmount) internal {
        IConvexRewards(AURA_WETH_REWARDS).withdrawAndUnwrap(bptAmount, true);

        _sellBalAndAura(
            IERC20(BAL).balanceOf(address(this)),
            IERC20(AURA).balanceOf(address(this))
        );

        uint256 wethAmount = (bptToWant(bptAmount) *
            10 ** ERC20(address(want)).decimals()) / ethToWant(1 ether);
        uint256 wethScaled = Utils.scaleDecimals(
            wethAmount,
            ERC20(address(want)),
            ERC20(WETH)
        );

        address[] memory _assets = new address[](2);
        _assets[0] = WETH;
        _assets[1] = AURA;

        uint256[] memory _minAmountsOut = new uint256[](2);
        _minAmountsOut[0] = (wethScaled * slippage) / 10000;
        _minAmountsOut[1] = 0;

        bytes memory userData = abi.encode(
            IBalancerV2Vault.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
            bptAmount,
            0 // exitTokenIndex
        );

        IBalancerV2Vault.ExitPoolRequest memory request;
        request = IBalancerV2Vault.ExitPoolRequest({
            assets: _assets,
            minAmountsOut: _minAmountsOut,
            userData: userData,
            toInternalBalance: false
        });

        balancerVault.exitPool({
            poolId: WETH_AURA_BALANCER_POOL_ID,
            sender: address(this),
            recipient: payable(address(this)),
            request: request
        });

        _sellWethForWant();
    }

    function prepareMigration(address _newStrategy) internal override {
        IConvexRewards auraPool = IConvexRewards(AURA_WETH_REWARDS);
        auraPool.withdrawAndUnwrap(auraPool.balanceOf(address(this)), true);

        uint256 auraBal = IERC20(AURA).balanceOf(address(this));
        if (auraBal > 0) {
            IERC20(AURA).safeTransfer(_newStrategy, auraBal);
        }
        uint256 balancerBal = IERC20(BAL).balanceOf(address(this));
        if (balancerBal > 0) {
            IERC20(BAL).safeTransfer(_newStrategy, balancerBal);
        }
        uint256 bptBal = IERC20(WETH_AURA_BALANCER_POOL).balanceOf(
            address(this)
        );
        if (bptBal > 0) {
            IERC20(WETH_AURA_BALANCER_POOL).safeTransfer(_newStrategy, bptBal);
        }
    }

    function protectedTokens()
        internal
        view
        override
        returns (address[] memory)
    {
        address[] memory protected = new address[](4);
        protected[0] = AURA_WETH_REWARDS;
        protected[1] = WETH_AURA_BALANCER_POOL;
        protected[2] = BAL;
        protected[3] = AURA;
        return protected;
    }

    function ethToWant(
        uint256 _amtInWei
    ) public view override returns (uint256) {
        IBalancerPriceOracle.OracleAverageQuery[] memory queries;
        queries = new IBalancerPriceOracle.OracleAverageQuery[](1);
        queries[0] = IBalancerPriceOracle.OracleAverageQuery({
            variable: IBalancerPriceOracle.Variable.PAIR_PRICE,
            secs: TWAP_RANGE_SECS,
            ago: 0
        });

        uint256[] memory results;
        results = IBalancerPriceOracle(USDC_WETH_BALANCER_POOL)
            .getTimeWeightedAverage(queries);

        return
            Utils.scaleDecimals(
                (_amtInWei * results[0]) / 1 ether,
                ERC20(WETH),
                ERC20(address(want))
            );
    }

    function getFundManagement()
        internal
        view
        returns (IBalancerV2Vault.FundManagement memory fundManagement)
    {
        fundManagement = IBalancerV2Vault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });
    }
}