// SPDX-License-Identifier: AGPL-3.0
// Feel free to change the license, but this is what we use

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
import "../integrations/aura/ICvx.sol";
import "../integrations/aura/IAuraToken.sol";
import "../integrations/aura/IAuraMinter.sol";
import "../integrations/convex/IConvexRewards.sol";
import "../integrations/convex/IConvexDeposit.sol";

import "../utils/AuraMath.sol";
import "../utils/Utils.sol";

contract RocketAuraStrategy is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using AuraMath for uint256;

    IBalancerV2Vault internal constant balancerVault =
        IBalancerV2Vault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    address internal constant bRethStable =
        0x1E19CF2D73a72Ef1332C882F20534B6519Be0276;
    address internal constant auraBRethStable =
        0x001B78CEC62DcFdc660E06A91Eb1bC966541d758;
    address internal constant auraToken =
        0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF;
    address internal constant balToken =
        0xba100000625a3754423978a60c9317c58a424e3D;
    address internal constant auraBooster =
        0xA57b8d98dAE62B26Ec3bcC4a365338157060B234;
    address internal constant rETH = 0xae78736Cd615f374D3085123A210448E74Fc6393;

    bytes32 internal constant rEthEthPoolId =
        bytes32(
            0x1e19cf2d73a72ef1332c882f20534b6519be0276000200000000000000000112
        );
    bytes32 internal constant balEthPoolId =
        bytes32(
            0x5c6ee304399dbdb9c8ef030ab642b10820db8f56000200000000000000000014
        );
    bytes32 internal constant auraEthPoolId =
        bytes32(
            0xc29562b045d80fd77c69bec09541f5c16fe20d9d000200000000000000000251
        );

    uint256 public bptSlippage = 9900; // 1%
    uint256 public rewardsSlippage = 9700; // 3%

    constructor(address _vault) BaseStrategy(_vault) {
        want.approve(address(balancerVault), type(uint256).max);
        IERC20(bRethStable).approve(auraBooster, type(uint256).max);
        IERC20(auraToken).approve(address(balancerVault), type(uint256).max);
        IERC20(balToken).approve(address(balancerVault), type(uint256).max);
    }

    function name() external view override returns (string memory) {
        return "StrategyRocketAura";
    }

    /// @notice Balance of want sitting in our strategy.
    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    function balanceOfAuraBpt() public view returns (uint256) {
        return IERC20(auraBRethStable).balanceOf(address(this));
    }

    function balanceOfAura() public view returns (uint256) {
        return IERC20(auraToken).balanceOf(address(this));
    }

    function balanceOfBal() public view returns (uint256) {
        return IERC20(balToken).balanceOf(address(this));
    }

    function balanceOfUnstakedBpt() public view returns (uint256) {
        return IERC20(bRethStable).balanceOf(address(this));
    }

    function balRewards() public view returns (uint256) {
        return IConvexRewards(auraBRethStable).earned(address(this));
    }

    function auraRewards() public view returns (uint256) {
        return AuraRewardsMath.convertCrvToCvx(balRewards());
    }

    function auraBptToBpt(uint _amountAuraBpt) public pure returns (uint256) {
        return _amountAuraBpt;
    }

    function estimatedTotalAssets()
        public
        view
        override
        returns (uint256 _wants)
    {
        _wants = balanceOfWant();

        uint256 bptTokens = balanceOfUnstakedBpt() +
            auraBptToBpt(balanceOfAuraBpt());
        _wants += bptToWant(bptTokens);
        uint256 balTokens = balRewards() + balanceOfBal();
        if (balTokens > 0) {
            _wants += balToWant(balTokens);
        }

        uint256 auraTokens = auraRewards() + balanceOfAura();
        if (auraTokens > 0) {
            _wants += auraToWant(auraTokens);
        }

        return _wants;
    }

    function wantToBpt(uint _amountWant) public view returns (uint _amount) {
        uint unscaled = _amountWant.mul(1e18).div(
            IBalancerPool(bRethStable).getRate()
        );
        return
            Utils.scaleDecimals(
                unscaled,
                ERC20(address(want)),
                ERC20(bRethStable)
            );
    }

    function bptToWant(uint _amountBpt) public view returns (uint _amount) {
        uint unscaled = _amountBpt.mul(getBptPrice()).div(1e18);
        return
            Utils.scaleDecimals(
                unscaled,
                ERC20(bRethStable),
                ERC20(address(want))
            );
    }

    function auraToWant(uint256 auraTokens) public view returns (uint256) {
        uint unscaled = auraTokens.mul(getAuraPrice()).div(1e18);
        return
            Utils.scaleDecimals(
                unscaled,
                ERC20(auraToken),
                ERC20(address(want))
            );
    }

    function balToWant(uint256 balTokens) public view returns (uint256) {
        uint unscaled = balTokens.mul(getBalPrice()).div(1e18);
        return
            Utils.scaleDecimals(
                unscaled,
                ERC20(balToken),
                ERC20(address(want))
            );
    }

    function getBalPrice() public view returns (uint256 price) {
        address priceOracle = 0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56;
        IBalancerPriceOracle.OracleAverageQuery[] memory queries;
        queries = new IBalancerPriceOracle.OracleAverageQuery[](1);
        queries[0] = IBalancerPriceOracle.OracleAverageQuery({
            variable: IBalancerPriceOracle.Variable.PAIR_PRICE,
            secs: 1800,
            ago: 0
        });
        uint256[] memory results = IBalancerPriceOracle(priceOracle)
            .getTimeWeightedAverage(queries);
        price = 1e36 / results[0];
    }

    function getAuraPrice() public view returns (uint256 price) {
        address priceOracle = 0xc29562b045D80fD77c69Bec09541F5c16fe20d9d;
        IBalancerPriceOracle.OracleAverageQuery[] memory queries;
        queries = new IBalancerPriceOracle.OracleAverageQuery[](1);
        queries[0] = IBalancerPriceOracle.OracleAverageQuery({
            variable: IBalancerPriceOracle.Variable.PAIR_PRICE,
            secs: 1800,
            ago: 0
        });
        uint256[] memory results;
        results = IBalancerPriceOracle(priceOracle).getTimeWeightedAverage(
            queries
        );
        price = results[0];
    }

    function getBptPrice() public view returns (uint256 price) {
        address priceOracle = 0x1E19CF2D73a72Ef1332C882F20534B6519Be0276;
        IBalancerPriceOracle.OracleAverageQuery[] memory queries;
        queries = new IBalancerPriceOracle.OracleAverageQuery[](1);
        queries[0] = IBalancerPriceOracle.OracleAverageQuery({
            variable: IBalancerPriceOracle.Variable.BPT_PRICE,
            secs: 1800,
            ago: 0
        });
        uint256[] memory results;
        results = IBalancerPriceOracle(priceOracle).getTimeWeightedAverage(
            queries
        );
        price = results[0];
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

        if (_liquidWant <= _profit) {
            // enough to pay profit (partial or full) only
            _profit = _liquidWant;
            _debtPayment = 0;
        } else {
            // enough to pay for all profit and _debtOutstanding (partial or full)
            _debtPayment = Math.min(_liquidWant - _profit, _debtOutstanding);
        }
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        if (balRewards() > 0) {
            IConvexRewards(auraBRethStable).getReward(address(this), true);
        }
        _sellBalAndAura(
            IERC20(balToken).balanceOf(address(this)),
            IERC20(auraToken).balanceOf(address(this))
        );

        uint256 _wethBal = want.balanceOf(address(this));
        if (_wethBal > _debtOutstanding) {
            uint256 _excessWeth = _wethBal - _debtOutstanding;

            uint256[] memory _amountsIn = new uint256[](2);
            _amountsIn[0] = 0;
            _amountsIn[1] = _excessWeth;

            address[] memory _assets = new address[](2);
            _assets[0] = rETH;
            _assets[1] = address(want);

            uint256[] memory _maxAmountsIn = new uint256[](2);
            _maxAmountsIn[0] = 0;
            _maxAmountsIn[1] = _excessWeth;

            uint256 _minimumBPT = (wantToBpt(_excessWeth) * bptSlippage) /
                10000;

            bytes memory _userData = abi.encode(
                IBalancerV2Vault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
                _amountsIn,
                _minimumBPT
            );

            IBalancerV2Vault.JoinPoolRequest memory _request;
            _request = IBalancerV2Vault.JoinPoolRequest({
                assets: _assets,
                maxAmountsIn: _maxAmountsIn,
                userData: _userData,
                fromInternalBalance: false
            });

            balancerVault.joinPool({
                poolId: rEthEthPoolId,
                sender: address(this),
                recipient: payable(address(this)),
                request: _request
            });
        }
        if (_wethBal > _debtOutstanding || balanceOfUnstakedBpt() > 0) {
            bool auraSuccess = IConvexDeposit(auraBooster).deposit(
                15, // PID
                IBalancerPool(bRethStable).balanceOf(address(this)),
                true // stake
            );
            assert(auraSuccess);
        }
    }

    function _sellBalAndAura(uint256 _balAmount, uint256 _auraAmount) internal {
        if (_balAmount == 0 || _auraAmount == 0) return;

        IBalancerV2Vault.BatchSwapStep[]
            memory swaps = new IBalancerV2Vault.BatchSwapStep[](2);

        // bal to weth
        swaps[0] = IBalancerV2Vault.BatchSwapStep({
            poolId: balEthPoolId,
            assetInIndex: 0,
            assetOutIndex: 2,
            amount: _balAmount,
            userData: abi.encode(0)
        });

        // aura to Weth
        swaps[1] = IBalancerV2Vault.BatchSwapStep({
            poolId: auraEthPoolId,
            assetInIndex: 1,
            assetOutIndex: 2,
            amount: _auraAmount,
            userData: abi.encode(0)
        });

        address[] memory assets = new address[](3);
        assets[0] = balToken;
        assets[1] = auraToken;
        assets[2] = address(want);

        int estimatedRewards = int(
            balToWant(_balAmount) + auraToWant(_auraAmount)
        );
        int[] memory limits = new int[](3);
        limits[0] = int(_balAmount);
        limits[1] = int(_auraAmount);
        limits[2] = (-1) * ((estimatedRewards * int(rewardsSlippage)) / 10000);

        balancerVault.batchSwap(
            IBalancerV2Vault.SwapKind.GIVEN_IN,
            swaps,
            assets,
            getFundManagement(),
            limits,
            block.timestamp
        );
    }

    function withdrawSome(uint256 _amountNeeded) internal {
        uint256 balTokens = balRewards() + balanceOfBal();
        uint256 auraTokens = auraRewards() + balanceOfAura();
        uint256 rewardsTotal = balToWant(balTokens) + auraToWant(auraTokens);

        if (rewardsTotal >= _amountNeeded) {
            IConvexRewards(auraBRethStable).getReward(address(this), true);
            _sellBalAndAura(balanceOfBal(), balanceOfAura());
        } else {
            uint256 bptToUnstake = Math.min(
                wantToBpt(_amountNeeded),
                IERC20(auraBRethStable).balanceOf(address(this))
            );

            if (bptToUnstake > 0) {
                _exitPosition(bptToUnstake);
            }
        }
    }

    function liquidatePosition(
        uint256 _amountNeeded
    ) internal override returns (uint256 _liquidatedAmount, uint256 _loss) {
        uint256 _wethBal = want.balanceOf(address(this));
        if (_wethBal >= _amountNeeded) {
            return (_amountNeeded, 0);
        }

        withdrawSome(_amountNeeded);

        _wethBal = want.balanceOf(address(this));
        if (_amountNeeded > _wethBal) {
            _liquidatedAmount = _wethBal;
            _loss = _amountNeeded - _wethBal;
        } else {
            _liquidatedAmount = _amountNeeded;
        }
    }

    function liquidateAllPositions() internal override returns (uint256) {
        IConvexRewards(auraBRethStable).getReward(address(this), true);
        _sellBalAndAura(
            IERC20(balToken).balanceOf(address(this)),
            IERC20(auraToken).balanceOf(address(this))
        );
        _exitPosition(IERC20(auraBRethStable).balanceOf(address(this)));
        return want.balanceOf(address(this));
    }

    function _exitPosition(uint256 bptAmount) internal {
        IConvexRewards(auraBRethStable).withdrawAndUnwrap(bptAmount, false);

        address[] memory _assets = new address[](2);
        _assets[0] = rETH;
        _assets[1] = address(want);

        uint256[] memory _minAmountsOut = new uint256[](2);
        _minAmountsOut[0] = 0;
        _minAmountsOut[1] = (bptToWant(bptAmount) * bptSlippage) / 10000;

        bytes memory userData = abi.encode(
            IBalancerV2Vault.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
            bptAmount,
            1 // exitTokenIndex
        );

        IBalancerV2Vault.ExitPoolRequest memory request;
        request = IBalancerV2Vault.ExitPoolRequest({
            assets: _assets,
            minAmountsOut: _minAmountsOut,
            userData: userData,
            toInternalBalance: false
        });

        balancerVault.exitPool({
            poolId: rEthEthPoolId,
            sender: address(this),
            recipient: payable(address(this)),
            request: request
        });
    }

    function prepareMigration(address _newStrategy) internal override {
        // auraBRethStable do not allow to transfer so we just unwrap it
        IConvexRewards auraPool = IConvexRewards(auraBRethStable);
        auraPool.withdrawAndUnwrap(auraPool.balanceOf(address(this)), true);

        uint256 auraBal = IERC20(auraToken).balanceOf(address(this));
        if (auraBal > 0) {
            IERC20(auraToken).safeTransfer(_newStrategy, auraBal);
        }
        uint256 balancerBal = IERC20(balToken).balanceOf(address(this));
        if (balancerBal > 0) {
            IERC20(balToken).safeTransfer(_newStrategy, balancerBal);
        }
        uint256 bptBal = IERC20(bRethStable).balanceOf(address(this));
        if (bptBal > 0) {
            IERC20(bRethStable).safeTransfer(_newStrategy, bptBal);
        }
    }

    function protectedTokens()
        internal
        view
        override
        returns (address[] memory)
    {
        address[] memory protected = new address[](4);
        protected[0] = bRethStable;
        protected[1] = auraBRethStable;
        protected[2] = balToken;
        protected[3] = auraToken;
        return protected;
    }

    function ethToWant(
        uint256 _amtInWei
    ) public view virtual override returns (uint256) {
        return _amtInWei;
    }

    function setBptSlippage(uint256 _slippage) external onlyStrategist {
        require(_slippage < 10_000, "!_slippage");
        bptSlippage = _slippage;
    }

    function setRewardsSlippage(uint256 _slippage) external onlyStrategist {
        require(_slippage < 10_000, "!_slippage");
        rewardsSlippage = _slippage;
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