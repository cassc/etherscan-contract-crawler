// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {
    BaseStrategy,
    StrategyParams
} from "@yearnvaults/contracts/BaseStrategy.sol";
import {IERC20Metadata} from "@yearnvaults/contracts/yToken.sol";

import "./interfaces/Angle/IStableMaster.sol";
import "./interfaces/Angle/IAngleGauge.sol";
import "./interfaces/Yearn/ITradeFactory.sol";
import "./interfaces/Uniswap/IUniV2.sol";
import {AngleStrategyVoterProxy} from "./AngleStrategyVoterProxy.sol";


interface IBaseFee {
    function isCurrentBaseFeeAcceptable() external view returns (bool);
}

contract Strategy is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;

    event Cloned(address indexed clone);

    bool public isOriginal = true;

    IERC20 public constant angleToken = IERC20(0x31429d1856aD1377A8A0079410B297e1a9e214c2);
    IStableMaster public constant angleStableMaster = IStableMaster(0x5adDc89785D75C86aB939E9e15bfBBb7Fc086A87);
    AngleStrategyVoterProxy public strategyProxy;

    uint256 public constant MAX_BPS = 10000;

    // variable for determining how much governance token to hold for voting rights
    uint256 public percentKeep;
    IERC20 public sanToken;
    IAngleGauge public sanTokenGauge;
    address public constant treasury = 0x93A62dA5a14C80f265DAbC077fCEE437B1a0Efde; // To change this, migrate
    address public constant unirouter = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F; // SushiSwap
    address public constant usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public poolManager;
    address public tradeFactory = address(0);

    // keeper stuff
    uint256 public harvestProfitMin; // minimum size in USD (6 decimals) that we want to harvest
    uint256 public harvestProfitMax; // maximum size in USD (6 decimals) that we want to harvest
    uint256 public creditThreshold; // amount of credit in underlying tokens that will automatically trigger a harvest
    bool internal forceHarvestTriggerOnce; // only set this to true when we want to trigger our keepers to harvest for us

    constructor(
        address _vault,
        address _sanToken,
        address _sanTokenGauge,
        address _poolManager,
        address _strategyProxy
    ) public BaseStrategy(_vault) {
        // Constructor should initialize local variables
        _initializeStrategy(
            _sanToken,
            _sanTokenGauge,
            _poolManager,
            _strategyProxy
        );
    }

    // Cloning & initialization code adapted from https://github.com/yearn/yearn-vaults/blob/43a0673ab89742388369bc0c9d1f321aa7ea73f6/contracts/BaseStrategy.sol#L866

    function _initializeStrategy(
        address _sanToken,
        address _sanTokenGauge,
        address _poolManager,
        address _strategyProxy
    ) internal {
        sanToken = IERC20(_sanToken);
        sanTokenGauge = IAngleGauge(_sanTokenGauge);
        poolManager = _poolManager;
        strategyProxy = AngleStrategyVoterProxy(_strategyProxy);

        percentKeep = 1000;
        healthCheck = 0xDDCea799fF1699e98EDF118e0629A974Df7DF012;
        doHealthCheck = true;

        maxReportDelay = 21 days; // 21 days in seconds, if we hit this then harvestTrigger = True
        harvestProfitMin = 2_000e6;
        harvestProfitMax = 10_000e6;
        creditThreshold = 1e6 * 1e18;
        
    }

    function initialize(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper,
        address _sanToken,
        address _sanTokenGauge,
        address _poolManager,
        address _strategyProxy
    ) external {
        _initialize(_vault, _strategist, _rewards, _keeper);
        _initializeStrategy(
            _sanToken,
            _sanTokenGauge,
            _poolManager,
            _strategyProxy
        );
    }

    function cloneAngle(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper,
        address _sanToken,
        address _sanTokenGauge,
        address _poolManager,
        address _strategyProxy
    ) external returns (address newStrategy) {
        require(isOriginal, "!clone");
        bytes20 addressBytes = bytes20(address(this));

        assembly {
            // EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(
                clone_code,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(
                add(clone_code, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            newStrategy := create(0, clone_code, 0x37)
        }

        Strategy(newStrategy).initialize(
            _vault,
            _strategist,
            _rewards,
            _keeper,
            _sanToken,
            _sanTokenGauge,
            _poolManager,
            _strategyProxy
        );

        emit Cloned(newStrategy);
    }

    function name() external view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "StrategyAngle",
                    IERC20Metadata(address(want)).symbol()
                )
            );
    }

    // returns sum of all assets, realized and unrealized
    function estimatedTotalAssets() public view override returns (uint256) {
        return balanceOfWant() + valueOfStakedSanToken() + valueOfSanToken();
    }

    function prepareReturn(uint256 _debtOutstanding)
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        )
    {
        // Run initial profit + loss calculations.

        uint256 _totalAssets = estimatedTotalAssets();
        uint256 _totalDebt = vault.strategies(address(this)).totalDebt;

        if (_totalAssets >= _totalDebt) {
            // Implicitly, _profit & _loss are 0 before we change them.
            _profit = _totalAssets - _totalDebt;
        } else {
            _loss = _totalDebt - _totalAssets;
        }

        // Free up _debtOutstanding + our profit, and make any necessary adjustments to the accounting.

        (uint256 _amountFreed, uint256 _liquidationLoss) =
            liquidatePosition(_debtOutstanding + _profit);

        _loss = _loss + _liquidationLoss;

        _debtPayment = Math.min(_debtOutstanding, _amountFreed);

        if (_loss > _profit) {
            _loss = _loss - _profit;
            _profit = 0;
        } else {
            _profit = _profit - _loss;
            _loss = 0;
        }

        // we're done harvesting, so reset our trigger if we used it
        forceHarvestTriggerOnce = false;
    }

    // Deposit value & stake
    function adjustPosition(uint256 _debtOutstanding) internal override {
        if (emergencyExit) {
            return;
        }

        // Claim rewards here so that we can chain tend() -> yswap sell -> harvest() in a single transaction
        strategyProxy.claimRewards(address(sanTokenGauge));

        uint256 _tokensAvailable = balanceOfAngleToken();
        if (_tokensAvailable > 0) {
            uint256 _tokensToKeep =
                (_tokensAvailable * percentKeep) / MAX_BPS;
            if (_tokensToKeep > 0) {
                IERC20(angleToken).transfer(address(strategyProxy.yearnAngleVoter()), _tokensToKeep);
            }
        }

        uint256 _balanceOfWant = balanceOfWant();

        // do not invest if we have more debt than want
        if (_debtOutstanding > _balanceOfWant) {
            return;
        }

        // Invest the rest of the want
        uint256 _wantAvailable = _balanceOfWant - _debtOutstanding;
        if (_wantAvailable > 0) {
            // deposit for sanToken
            want.safeTransfer(address(strategyProxy), _wantAvailable);
            depositToStableMaster(_wantAvailable);
        }

        // Stake any san tokens, whether they originated through the above deposit or some other means (e.g. migration)
        uint256 _sanTokenBalance = balanceOfSanToken();
        if (_sanTokenBalance > 0) {
            strategyProxy.stake(address(sanTokenGauge), _sanTokenBalance, address(sanToken));
        }
    }

    function liquidateAllPositions()
        internal
        override
        returns (uint256 _amountFreed)
    {
        (_amountFreed, ) = liquidatePosition(estimatedTotalAssets());
    }

    function liquidatePosition(uint256 _amountNeeded)
        internal
        override
        returns (uint256 _liquidatedAmount, uint256 _loss)
    {
        // NOTE: Maintain invariant `_liquidatedAmount + _loss <= _amountNeeded`
        _amountNeeded = Math.min(_amountNeeded, estimatedTotalAssets()); // This makes it safe to request to liquidate more than we have

        uint256 _balanceOfWant = balanceOfWant();
        if (_balanceOfWant < _amountNeeded) {
            // We need to withdraw to get back more want
            _withdrawSome(_amountNeeded - _balanceOfWant);
            // reload balance of want after side effect
            _balanceOfWant = balanceOfWant();
        }

        if (_balanceOfWant >= _amountNeeded) {
            _liquidatedAmount = _amountNeeded;
        } else {
            _liquidatedAmount = _balanceOfWant;
            _loss = _amountNeeded - _balanceOfWant;
        }
    }

    // withdraw some want from Angle
    function _withdrawSome(uint256 _amount) internal {
        uint256 _amountInSanToken = wantToSanToken(_amount);

        uint256 _sanTokenBalance = balanceOfSanToken();
        if (_amountInSanToken > _sanTokenBalance) {
            _amountInSanToken = Math.min(_amountInSanToken - _sanTokenBalance, balanceOfStakedSanToken());
            strategyProxy.withdraw(
                address(sanTokenGauge),
                address(sanToken),
                _amountInSanToken
            );
            IERC20(sanToken).safeTransfer(address(strategyProxy), _amountInSanToken);
        }

        withdrawFromStableMaster(_amountInSanToken);
    }

    // can be used in conjunction with migration if this function is still working
    function claimRewards() external onlyVaultManagers {
        strategyProxy.claimRewards(address(sanTokenGauge));
    }

    // transfers all tokens to new strategy
    function prepareMigration(address _newStrategy) internal override {
        // Claim rewards is called externally + sweep by governance
        // Governance can then revoke this strategy and approve the new one so the 
        // funds assigned to this gauge in the proxy are available
    }

    function protectedTokens()
        internal
        view
        override
        returns (address[] memory)
    {}


    function ethToWant(uint256 _amtInWei)
        public
        view
        override
        returns (uint256)
    {
        return _amtInWei;
    }

    /* ========== KEEP3RS ========== */
    // use this to determine when to harvest
    function harvestTrigger(uint256 callCostinEth)
        public
        view
        override
        returns (bool)
    {
        // Should not trigger if strategy is not active (no assets and no debtRatio). This means we don't need to adjust keeper job.
        if (!isActive()) {
            return false;
        }

        // harvest if we have a profit to claim at our upper limit without considering gas price
        uint256 claimableProfit = claimableProfitInUsdt();
        if (claimableProfit > harvestProfitMax) {
            return true;
        }

        // check if the base fee gas price is higher than we allow. if it is, block harvests.
        if (!isBaseFeeAcceptable()) {
            return false;
        }

        // trigger if we want to manually harvest, but only if our gas price is acceptable
        if (forceHarvestTriggerOnce) {
            return true;
        }

        // harvest if we have a sufficient profit to claim, but only if our gas price is acceptable
        if (claimableProfit > harvestProfitMin) {
            return true;
        }

        StrategyParams memory params = vault.strategies(address(this));
        // harvest no matter what once we reach our maxDelay
        if (block.timestamp - params.lastReport > maxReportDelay) {
            return true;
        }

        // harvest our credit if it's above our threshold
        if (vault.creditAvailable() > creditThreshold) {
            return true;
        }

        // otherwise, we don't harvest
        return false;
    }

    /// @notice The value in dollars that our claimable rewards are worth (in USDT, 6 decimals).
    function claimableProfitInUsdt() public view returns (uint256) {
        address[] memory path = new address[](3);
        path[0] = address(angleToken);
        path[1] = weth;
        path[2] = address(usdt);

        uint256 _claimableRewards = sanTokenGauge.claimable_reward(address(this), address(angleToken));

        if (_claimableRewards < 1e18) { // Dust check
            return 0;
        }

        uint256[] memory amounts = IUniV2(unirouter).getAmountsOut(
            _claimableRewards,
            path
        );

        return amounts[amounts.length - 1];
    }

    // check if the current baseFee is below our external target
    function isBaseFeeAcceptable() internal view returns (bool) {
        return
            IBaseFee(0xb5e1CAcB567d98faaDB60a1fD4820720141f064F)
                .isCurrentBaseFeeAcceptable();
    }


    // ---------------------- SETTERS -----------------------

    // This allows us to manually harvest with our keeper as needed
    function setForceHarvestTriggerOnce(bool _forceHarvestTriggerOnce)
        external
        onlyVaultManagers
    {
        forceHarvestTriggerOnce = _forceHarvestTriggerOnce;
    }

    // Min profit to start checking for harvests if gas is good, max will harvest no matter gas (both in USDT, 6 decimals). Credit threshold is in want token, and will trigger a harvest if credit is large enough. check earmark to look at convex's booster.
    function setHarvestTriggerParams(
        uint256 _harvestProfitMin,
        uint256 _harvestProfitMax,
        uint256 _creditThreshold
    ) external onlyVaultManagers {
        harvestProfitMin = _harvestProfitMin;
        harvestProfitMax = _harvestProfitMax;
        creditThreshold = _creditThreshold;
    }

    function setKeepInBips(uint256 _percentKeep) external onlyVaultManagers {
        require(
            _percentKeep <= MAX_BPS,
            "_percentKeep can't be larger than 10,000"
        );
        percentKeep = _percentKeep;
    }

    // ----------------- SUPPORT & UTILITY FUNCTIONS ----------

    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    function balanceOfStakedSanToken() public view returns (uint256) {
        return strategyProxy.balanceOfStakedSanToken(address(sanTokenGauge));
    }

    function balanceOfSanToken() public view returns (uint256) {
        return strategyProxy.balanceOfSanToken(address(sanToken));
    }

    function balanceOfAngleToken() public view returns (uint256) {
        return angleToken.balanceOf(address(this));
    }

    function valueOfSanToken() public view returns (uint256) {
        return sanTokenToWant(balanceOfSanToken());
    }

    function valueOfStakedSanToken() public view returns (uint256) {
        return sanTokenToWant(balanceOfStakedSanToken());
    }

    function sanTokenToWant(uint256 _sanTokenAmount)
        public
        view
        returns (uint256)
    {
        return (_sanTokenAmount * getSanRate()) / 1e18;
    }

    function wantToSanToken(uint256 _wantAmount) public view returns (uint256) {
        return ((_wantAmount * 1e18) / getSanRate()) + 1;
    }

    // Get rate of conversion between sanTokens and want
    function getSanRate() public view returns (uint256) {
        (, , , , , uint256 _sanRate, , , ) =
            IStableMaster(angleStableMaster).collateralMap(poolManager);

        return _sanRate;
    }

    function depositToStableMaster(uint256 _amount) internal {
        strategyProxy.depositToStableMaster(
            address(angleStableMaster),
            _amount,
            poolManager,
            address(want),
            address(sanTokenGauge)
        );
    }

    function withdrawFromStableMaster(uint256 _amountInSanToken) internal {
        strategyProxy.withdrawFromStableMaster(
            address(angleStableMaster),
            _amountInSanToken,
            poolManager,
            address(sanToken),
            address(sanTokenGauge)
        );
    }

    // ---------------------- YSWAPS FUNCTIONS ----------------------

    function setTradeFactory(address _tradeFactory) external onlyGovernance {
        if (tradeFactory != address(0)) {
            _removeTradeFactoryPermissions();
        }
        angleToken.safeApprove(_tradeFactory, type(uint256).max);
        ITradeFactory tf = ITradeFactory(_tradeFactory);
        tf.enable(address(angleToken), address(want));
        tradeFactory = _tradeFactory;
    }

    function removeTradeFactoryPermissions() external onlyEmergencyAuthorized {
        _removeTradeFactoryPermissions();
    }

    function _removeTradeFactoryPermissions() internal {
        angleToken.safeApprove(tradeFactory, 0);
        tradeFactory = address(0);
    }
}