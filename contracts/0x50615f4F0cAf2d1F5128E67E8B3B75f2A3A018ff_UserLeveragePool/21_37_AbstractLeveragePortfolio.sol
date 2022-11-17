// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import "../libraries/DecimalsConverter.sol";

import "../interfaces/IPolicyBookRegistry.sol";
import "../interfaces/ILeveragePortfolio.sol";
import "../interfaces/IPolicyBookFabric.sol";
import "../interfaces/IPolicyBook.sol";
import "../interfaces/ICapitalPool.sol";
import "../interfaces/ILeveragePortfolioView.sol";

import "./AbstractDependant.sol";

import "../Globals.sol";

abstract contract AbstractLeveragePortfolio is
    ILeveragePortfolio,
    Initializable,
    AbstractDependant
{
    using SafeMath for uint256;
    using Math for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 private constant MAX_INVESTED_POOLS = 20;

    ICapitalPool public capitalPool;
    IPolicyBookRegistry public policyBookRegistry;
    ILeveragePortfolioView public leveragePortfolioView;

    address public policyBookAdmin;

    address public reinsurancePoolAddress;

    uint256 public override targetUR;
    uint256 public override d_ProtocolConstant;
    uint256 public override a_ProtocolConstant;
    uint256 public override max_ProtocolConstant;

    uint256 public override totalLiquidity;
    uint256 public rebalancingThreshold;

    mapping(address => uint256) public poolsLDeployedAmount;
    mapping(address => uint256) public poolsVDeployedAmount;
    EnumerableSet.AddressSet internal leveragedCoveragePools;

    event LeverageStableDeployed(address policyBook, uint256 deployedAmount);
    event VirtualStableDeployed(address policyBook, uint256 deployedAmount);
    event ProvidedLeverageReevaluated(LeveragePortfolio leveragePool);
    event PremiumAdded(uint256 premiumAmount);
    event LiquidityWithdrawn(
        address _liquidityHolder,
        uint256 _tokensToWithdraw,
        uint256 _newTotalLiquidity
    );

    modifier onlyPolicyBookFacade() {
        require(policyBookRegistry.isPolicyBookFacade(msg.sender), "LP: No access");
        _;
    }

    modifier onlyCapitalPool() {
        require(msg.sender == address(capitalPool), "LP: No access");
        _;
    }

    modifier onlyPolicyBookAdmin() {
        require(msg.sender == policyBookAdmin, "LP: Not a PBA");
        _;
    }

    function __LeveragePortfolio_init() internal initializer {
        a_ProtocolConstant = 100 * PRECISION;
        d_ProtocolConstant = 5 * PRECISION;
        targetUR = 45 * PRECISION;
        max_ProtocolConstant = PERCENTAGE_100;
        rebalancingThreshold = DEFAULT_REBALANCING_THRESHOLD;
    }

    /// @notice deploy lStable from user leverage pool or reinsurance pool using 2 formulas: access by policybook.
    /// @param leveragePoolType LeveragePortfolio is determine the pool which call the function
    function deployLeverageStableToCoveragePools(LeveragePortfolio leveragePoolType)
        external
        override
        onlyPolicyBookFacade
        returns (uint256)
    {
        return
            _deployLeverageStableToCoveragePools(
                leveragePoolType,
                address((IPolicyBookFacade(msg.sender)).policyBook())
            );
    }

    /// @notice deploy the vStable from RP in v2 and for next versions it will be from RP and LP : access by policybook.
    /// @return the amount of vstable to deploy
    function deployVirtualStableToCoveragePools()
        external
        override
        onlyPolicyBookFacade
        returns (uint256)
    {
        address policyBookAddr = address((IPolicyBookFacade(msg.sender)).policyBook());

        return _deployVirtualStableToCoveragePools(policyBookAddr, 0);
    }

    /// @notice add the portion of 80% of premium to user leverage pool where the leverage provide lstable : access policybook
    /// add the 20% of premium + portion of 80% of premium where reisnurance pool participate in coverage pools (vStable)  : access policybook
    /// @param epochsNumber uint256 the number of epochs which the policy holder will pay a premium for , zero for RP
    /// @param  premiumAmount uint256 the premium amount which is a portion of 80% of the premium
    function addPolicyPremium(uint256 epochsNumber, uint256 premiumAmount)
        external
        virtual
        override;

    /// @notice set the threshold % for re-evaluation of the lStable provided across all Coverage pools
    /// @param _threshold uint256 is the reevaluatation threshold
    function setRebalancingThreshold(uint256 _threshold) external override onlyPolicyBookAdmin {
        rebalancingThreshold = _threshold;
    }

    /// @notice set the protocol constant
    /// @notice set the protocol constant : access by owner
    /// @param _targetUR uint256 target utitlization ration
    /// @param _d_ProtocolConstant uint256 D protocol constant
    /// @param  _a1_ProtocolConstant uint256 A1 protocol constant
    /// @param _max_ProtocolConstant uint256 the max % included
    function setProtocolConstant(
        uint256 _targetUR,
        uint256 _d_ProtocolConstant,
        uint256 _a1_ProtocolConstant,
        uint256 _max_ProtocolConstant
    ) external override onlyPolicyBookAdmin {
        targetUR = _targetUR;
        d_ProtocolConstant = _d_ProtocolConstant;
        a_ProtocolConstant = _a1_ProtocolConstant;
        max_ProtocolConstant = _max_ProtocolConstant;
    }

    /// @notice Used to get a list of coverage pools which get leveraged , use with count()
    /// @return _coveragePools a list containing policybook addresses
    function listleveragedCoveragePools(uint256 offset, uint256 limit)
        external
        view
        override
        returns (address[] memory _coveragePools)
    {
        uint256 to = (offset.add(limit)).min(leveragedCoveragePools.length()).max(offset);

        _coveragePools = new address[](to - offset);

        for (uint256 i = offset; i < to; i++) {
            _coveragePools[i - offset] = leveragedCoveragePools.at(i);
        }
    }

    /// @notice get count of coverage pools which get leveraged
    function countleveragedCoveragePools() external view override returns (uint256) {
        return leveragedCoveragePools.length();
    }

    function _deployVirtualStableToCoveragePools(address policyBookAddress, uint256 vStableWeight)
        internal
        returns (uint256 deployedAmount)
    {
        if (isExceedMaxInvestedPools(policyBookAddress)) {
            return 0;
        }
        if (vStableWeight == 0) {
            vStableWeight = leveragePortfolioView.calcvStableFormulaforAllPools();
        }
        (uint256 _amountToDeploy, uint256 _maxAmount) =
            leveragePortfolioView.calcMaxVirtualFunds(policyBookAddress, vStableWeight);

        if (_amountToDeploy > _maxAmount) {
            deployedAmount = _maxAmount;
        } else {
            deployedAmount = _amountToDeploy;
        }

        if (deployedAmount > 0) {
            poolsVDeployedAmount[policyBookAddress] = deployedAmount;
            leveragedCoveragePools.add(policyBookAddress);
        } else {
            poolsVDeployedAmount[policyBookAddress] = 0;
        }

        emit VirtualStableDeployed(policyBookAddress, deployedAmount);
    }

    /// @dev using two formulas , if formula 1 get zero then use the formula 2
    /// otherwise get the min value of both
    /// calculate the net mpl for the other pool RP or LP
    function _deployLeverageStableToCoveragePools(
        LeveragePortfolio leveragePoolType,
        address policyBookAddress
    ) internal returns (uint256 deployedAmount) {
        if (isExceedMaxInvestedPools(policyBookAddress)) {
            return 0;
        }
        IPolicyBookFacade _policyBookFacade =
            leveragePortfolioView.getPolicyBookFacade(policyBookAddress);

        uint256 _netMPL;
        uint256 _netMPLn;
        if (leveragePoolType == LeveragePortfolio.USERLEVERAGEPOOL) {
            _netMPL = totalLiquidity.mul(_policyBookFacade.userleveragedMPL()).div(PERCENTAGE_100);

            _netMPLn = _netMPLn.add(
                ILeveragePortfolio(reinsurancePoolAddress)
                    .totalLiquidity()
                    .mul(_policyBookFacade.reinsurancePoolMPL())
                    .div(PERCENTAGE_100)
            );
        } else {
            _netMPL = totalLiquidity.mul(_policyBookFacade.reinsurancePoolMPL()).div(
                PERCENTAGE_100
            );
        }
        _netMPLn = _netMPLn.add(
            leveragePortfolioView.calcNetMPLn(leveragePoolType, address(_policyBookFacade))
        );

        deployedAmount = leveragePortfolioView.calcMaxLevFunds(
            LevFundsFactors(_netMPL, _netMPLn, policyBookAddress)
        );

        if (deployedAmount > 0) {
            if (deployedAmount >= poolsVDeployedAmount[policyBookAddress]) {
                deployedAmount = deployedAmount.sub(poolsVDeployedAmount[policyBookAddress]);
            }

            leveragedCoveragePools.add(policyBookAddress);
        } else {
            leveragedCoveragePools.remove(policyBookAddress);
        }
        poolsLDeployedAmount[policyBookAddress] = deployedAmount.add(
            poolsVDeployedAmount[policyBookAddress]
        );

        emit LeverageStableDeployed(policyBookAddress, deployedAmount);
    }

    function isExceedMaxInvestedPools(address _policyBookAdd)
        internal
        view
        returns (bool _isExceed)
    {
        if (
            !leveragedCoveragePools.contains(_policyBookAdd) &&
            leveragedCoveragePools.length() >= MAX_INVESTED_POOLS
        ) {
            _isExceed = true;
        }
    }

    /// @notice reevaluate all pools provided by the leverage stable upon threshold
    /// @param leveragePool LeveragePortfolio is determine the pool which call the function
    /// @param newAmount the new amount added or subtracted from the pool
    function _reevaluateProvidedLeverageStable(LeveragePortfolio leveragePool, uint256 newAmount)
        internal
    {
        uint256 _newAmountPercentage;
        if (totalLiquidity > 0) {
            _newAmountPercentage = newAmount.mul(PERCENTAGE_100).div(totalLiquidity);
        }
        if (
            (totalLiquidity > 0 && _newAmountPercentage > rebalancingThreshold) ||
            totalLiquidity == 0
        ) {
            _rebalanceInvestedPools(leveragePool);

            emit ProvidedLeverageReevaluated(leveragePool);
        }
    }

    /// @notice rebalance all pools provided by the leverage stable or virtual stable
    /// @param leveragePool LeveragePortfolio is determine the pool which call the function
    function _rebalanceInvestedPools(LeveragePortfolio leveragePool) internal {
        uint256 vStableWeight;
        if (leveragePool == LeveragePortfolio.REINSURANCEPOOL) {
            vStableWeight = leveragePortfolioView.calcvStableFormulaforAllPools();
        }
        address policyBookAddress;

        IPolicyBookFacade _policyBookFacade;
        for (uint256 i = 0; i < leveragedCoveragePools.length(); i++) {
            policyBookAddress = leveragedCoveragePools.at(i);

            _policyBookFacade = leveragePortfolioView.getPolicyBookFacade(policyBookAddress);
            uint256 deployedAmount;
            if (leveragePool == LeveragePortfolio.REINSURANCEPOOL) {
                deployedAmount = _deployVirtualStableToCoveragePools(
                    policyBookAddress,
                    vStableWeight
                );

                _policyBookFacade.deployVirtualFundsAfterRebalance(deployedAmount);
            }

            deployedAmount = _deployLeverageStableToCoveragePools(leveragePool, policyBookAddress);
            _policyBookFacade.deployLeverageFundsAfterRebalance(deployedAmount, leveragePool);
        }
    }

    function updateLiquidity(uint256 _lostLiquidity) external virtual override;

    function forceUpdateBMICoverStakingRewardMultiplier() external virtual override;
}