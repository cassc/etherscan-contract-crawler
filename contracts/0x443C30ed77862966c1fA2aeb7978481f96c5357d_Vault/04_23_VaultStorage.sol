// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
import "../access-control/AccessControlMixin.sol";
import "../library/IterableIntMap.sol";
import "../library/StableMath.sol";
import "../token/IPegToken.sol";
import "./IVaultBuffer.sol";
import "../library/BocRoles.sol";
import "../strategy/IStrategy.sol";
import "../price-feeds/IValueInterpreter.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract VaultStorage is Initializable, ReentrancyGuardUpgradeable, AccessControlMixin {
    using StableMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using IterableIntMap for IterableIntMap.AddressToIntMap;

    /// @param lastReport The last report timestamp
    /// @param totalDebt The total asset of this strategy
    /// @param profitLimitRatio The limited ratio of profit
    /// @param lossLimitRatio The limited ratio for loss
    /// @param enforceChangeLimit The switch of enforce change Limit
    struct StrategyParams {
        uint256 lastReport;
        uint256 totalDebt;
        uint256 profitLimitRatio;
        uint256 lossLimitRatio;
        bool enforceChangeLimit;
    }

    /// @param strategy The new strategy to add
    /// @param profitLimitRatio The limited ratio of profit
    /// @param lossLimitRatio The limited ratio for loss
    struct StrategyAdd {
        address strategy;
        uint256 profitLimitRatio;
        uint256 lossLimitRatio;
    }

    event AddAsset(address _asset);
    event RemoveAsset(address _asset);
    event AddStrategies(address[] _strategies);
    event RemoveStrategies(address[] _strategies);
    event RemoveStrategyByForce(address _strategy);
    event Mint(address _account, address[] _assets, uint256[] _amounts, uint256 _mintAmount);
    event Burn(
        address _account,
        uint256 _amount,
        uint256 _actualAmount,
        uint256 _shareAmount,
        address[] _assets,
        uint256[] _amounts
    );
    event Exchange(
        address _platform,
        address _srcAsset,
        uint256 _srcAmount,
        address _distAsset,
        uint256 _distAmount
    );
    event Redeem(address _strategy, uint256 _debtChangeAmount, address[] _assets, uint256[] _amounts);
    event LendToStrategy(
        address indexed _strategy,
        address[] _wants,
        uint256[] _amounts,
        uint256 _lendValue
    );
    event RepayFromStrategy(
        address indexed _strategy,
        uint256 _strategyWithdrawValue,
        uint256 _strategyTotalValue,
        address[] _assets,
        uint256[] _amounts
    );
    event StrategyReported(
        address indexed _strategy,
        uint256 _gain,
        uint256 _loss,
        uint256 _lastStrategyTotalDebt,
        uint256 _nowStrategyTotalDebt,
        address[] _rewardTokens,
        uint256[] _claimAmounts,
        uint256 _type
    );
    event RemoveStrategyFromQueue(address[] _strategies);
    event SetEmergencyShutdown(bool _shutdown);
    event RebasePaused();
    event RebaseUnpaused();
    event RebaseThresholdUpdated(uint256 _threshold);
    event TrusteeFeeBpsChanged(uint256 _basis);
    event MaxTimestampBetweenTwoReportedChanged(uint256 _maxTimestampBetweenTwoReported);
    event MinCheckedStrategyTotalDebtChanged(uint256 _minCheckedStrategyTotalDebt);
    event MinimumInvestmentAmountChanged(uint256 _minimumInvestmentAmount);
    event TreasuryAddressChanged(address _address);
    event ExchangeManagerAddressChanged(address _address);
    event SetAdjustPositionPeriod(bool _adjustPositionPeriod);
    event RedeemFeeUpdated(uint256 _redeemFeeBps);
    event SetWithdrawalQueue(address[] _queues);
    event Rebase(uint256 _totalShares, uint256 _totalValue, uint256 _newUnderlyingUnitsPerShare);
    event StartAdjustPosition(
        uint256 _totalDebtOfBeforeAdjustPosition,
        address[] _trackedAssets,
        uint256[] _vaultCashDetatil,
        uint256[] _vaultBufferCashDetail
    );
    event EndAdjustPosition(
        uint256 _transferValue,
        uint256 _redeemValue,
        uint256 _totalDebt,
        uint256 _totalValueOfAfterAdjustPosition,
        uint256 _totalValueOfBeforeAdjustPosition
    );
    event PegTokenSwapCash(uint256 _pegTokenAmount, address[] _assets, uint256[] _amounts);

    address internal constant ZERO_ADDRESS = address(0);

    //max percentage 100%
    uint256 internal constant MAX_BPS = 10000;

    // all strategy
    EnumerableSet.AddressSet internal strategySet;
    // Assets supported by the Vault, i.e. Stablecoins
    EnumerableSet.AddressSet internal assetSet;
    // Assets held by Vault
    IterableIntMap.AddressToIntMap internal trackedAssetsMap;
    // Decimals of the assets held by Vault
    mapping(address => uint256) internal trackedAssetDecimalsMap;

    //adjust Position Period
    bool public adjustPositionPeriod;
    // emergency shutdown
    bool public emergencyShutdown;
    // Pausing bools
    bool public rebasePaused;
    // over this difference ratio automatically rebase. rebaseThreshold is the numerator and the denominator is 10000000 x/10000000.
    uint256 public rebaseThreshold;
    // Deprecated
    uint256 public maxSupplyDiff;
    // Amount of yield collected in basis points
    uint256 public trusteeFeeBps;
    // Redemption fee in basis points
    uint256 public redeemFeeBps;
    //all strategy asset
    uint256 public totalDebt;
    // treasury contract that can collect a percentage of yield
    address public treasury;
    //valueInterpreter
    address public valueInterpreter;
    //exchangeManager
    address public exchangeManager;
    // strategy info
    mapping(address => StrategyParams) public strategies;

    //withdraw strategy set
    address[] public withdrawQueue;
    //keccak256("USDi.vault.governor.admin.impl");
    bytes32 internal constant ADMIN_IMPL_POSITION =
        0x3d78d3961e16fde088e2e26c1cfa163f5f8bb870709088dd68c87eb4091137e2;

    //vault Buffer Address
    address public vaultBufferAddress;
    // usdi PegToken address
    address public pegTokenAddress;
    // Assets held in Vault from vault buffer
    mapping(address => uint256) internal transferFromVaultBufferAssetsMap;
    // redeem Assets where ad
    mapping(address => uint256) internal redeemAssetsMap;
    // Assets held in Vault and buffer before Adjust Position
    mapping(address => uint256) internal beforeAdjustPositionAssetsMap;
    // totalDebt before Adjust Position
    uint256 internal totalDebtOfBeforeAdjustPosition;
    // totalAsset/totalShare
    uint256 public underlyingUnitsPerShare;
    //Maximum timestamp between two reported
    uint256 public maxTimestampBetweenTwoReported;
    //Minimum strategy total debt that will be checked for the strategy reporting
    uint256 public minCheckedStrategyTotalDebt;
    //Minimum investment amount
    uint256 public minimumInvestmentAmount;

    //max percentage 10000000/10000000
    uint256 internal constant TEN_MILLION_BPS = 10000000;

    /**
     * @dev set the implementation for the admin, this needs to be in a base class else we cannot set it
     * @param _newImpl address of the implementation
     */
    function setAdminImpl(address _newImpl) external onlyGovOrDelegate {
        require(AddressUpgradeable.isContract(_newImpl), "new implementation is not a contract");
        bytes32 _position = ADMIN_IMPL_POSITION;
        assembly {
            sstore(_position, _newImpl)
        }
    }
}