// solhint-disable no-unused-vars
// SPDX-License-Identifier:MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

//  libraries
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

//  helper contracts
import { Modifiers } from "../../earn-protocol-configuration/contracts/Modifiers.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

//  interfaces
import { IAaveV2PriceOracle } from "@optyfi/defi-legos/ethereum/aavev2/contracts/IAaveV2PriceOracle.sol";
import {
    IAaveV2LendingPoolAddressesProvider
} from "@optyfi/defi-legos/ethereum/aavev2/contracts/IAaveV2LendingPoolAddressesProvider.sol";
import {
    IAaveV2LendingPoolAddressProviderRegistry
} from "@optyfi/defi-legos/ethereum/aavev2/contracts/IAaveV2LendingPoolAddressProviderRegistry.sol";
import { IAaveV2, ReserveDataV2, UserAccountData } from "@optyfi/defi-legos/ethereum/aavev2/contracts/IAaveV2.sol";
import { IAaveV2Token } from "@optyfi/defi-legos/ethereum/aavev2/contracts/IAaveV2Token.sol";
import {
    IAaveV2ProtocolDataProvider,
    UserReserveData,
    ReserveDataProtocol,
    ReserveConfigurationData
} from "@optyfi/defi-legos/ethereum/aavev2/contracts/IAaveV2ProtocolDataProvider.sol";
import { IHarvestCodeProvider } from "../interfaces/IHarvestCodeProvider.sol";
import { IAdapter } from "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapter.sol";
import { IAdapterBorrow } from "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapterBorrow.sol";
import "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapterInvestLimit.sol";

/**
 * @title Adapter for AaveV2 protocol
 * @author Opty.fi
 * @dev Abstraction layer to AaveV2's pools
 */
contract AaveV2Adapter is IAdapter, IAdapterBorrow, IAdapterInvestLimit, Modifiers {
    using SafeMath for uint256;
    using Address for address;

    /** @notice max deposit value datatypes */
    MaxExposure public maxDepositProtocolMode;

    /** @notice max deposit's protocol value in percentage */
    uint256 public maxDepositProtocolPct; // basis points

    /**
     * @notice numeric representation of the safety of vault's deposited assets against the borrowed assets
     * and its underlying value
     */
    uint256 public healthFactor = 2;

    /**
     * @notice  Percentage of the value in USD of the collateral we can borrow
     * @dev ltv defines as loan-to-value
     */
    uint256 public ltv = 65;

    /** @notice Max percentage value i.e. 100% */
    uint256 public max = 100;

    /** @notice AaveV2's Data provider id */
    bytes32 public constant PROTOCOL_DATA_PROVIDER_ID =
        0x0100000000000000000000000000000000000000000000000000000000000000;

    /** @notice  Maps liquidityPool to max deposit value in percentage */
    mapping(address => uint256) public maxDepositPoolPct; // basis points

    /** @notice  Maps liquidityPool to max deposit value in absolute value for a specific token */
    mapping(address => mapping(address => uint256)) public maxDepositAmount;

    constructor(address _registry) public Modifiers(_registry) {
        setMaxDepositProtocolPct(uint256(10000)); // 100% (basis points)
        setMaxDepositProtocolMode(MaxExposure.Pct);
    }

    /**
     * @inheritdoc IAdapterInvestLimit
     */
    function setMaxDepositPoolPct(address _liquidityPool, uint256 _maxDepositPoolPct)
        external
        override
        onlyRiskOperator
    {
        require(_liquidityPool.isContract(), "!isContract");
        maxDepositPoolPct[_liquidityPool] = _maxDepositPoolPct;
        emit LogMaxDepositPoolPct(maxDepositPoolPct[_liquidityPool], msg.sender);
    }

    /**
     * @inheritdoc IAdapterInvestLimit
     */
    function setMaxDepositAmount(
        address _liquidityPool,
        address _underlyingToken,
        uint256 _maxDepositAmount
    ) external override onlyRiskOperator {
        require(_liquidityPool.isContract(), "!_liquidityPool.isContract()");
        require(_underlyingToken.isContract(), "!_underlyingToken.isContract()");
        maxDepositAmount[_liquidityPool][_underlyingToken] = _maxDepositAmount;
        emit LogMaxDepositAmount(maxDepositAmount[_liquidityPool][_underlyingToken], msg.sender);
    }

    /**
     * @inheritdoc IAdapterInvestLimit
     */
    function setMaxDepositProtocolMode(MaxExposure _mode) public override onlyRiskOperator {
        maxDepositProtocolMode = _mode;
        emit LogMaxDepositProtocolMode(maxDepositProtocolMode, msg.sender);
    }

    /**
     * @inheritdoc IAdapterInvestLimit
     */
    function setMaxDepositProtocolPct(uint256 _maxDepositProtocolPct) public override onlyRiskOperator {
        maxDepositProtocolPct = _maxDepositProtocolPct;
        emit LogMaxDepositProtocolPct(maxDepositProtocolPct, msg.sender);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getDepositAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPoolAddressProviderRegistry
    ) public view override returns (bytes[] memory) {
        uint256 _amount = ERC20(_underlyingToken).balanceOf(_vault);
        return getDepositSomeCodes(_vault, _underlyingToken, _liquidityPoolAddressProviderRegistry, _amount);
    }

    /**
     * @inheritdoc IAdapterBorrow
     */
    function getBorrowAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPoolAddressProviderRegistry,
        address _outputToken
    ) public view override returns (bytes[] memory _codes) {
        address _lendingPool = _getLendingPool(_liquidityPoolAddressProviderRegistry);
        ReserveConfigurationData memory _reserveConfigurationData =
            IAaveV2ProtocolDataProvider(_getProtocolDataProvider(_liquidityPoolAddressProviderRegistry))
                .getReserveConfigurationData(_underlyingToken);
        if (
            _reserveConfigurationData.usageAsCollateralEnabled &&
            _reserveConfigurationData.stableBorrowRateEnabled &&
            _reserveConfigurationData.borrowingEnabled &&
            _reserveConfigurationData.isActive &&
            !_reserveConfigurationData.isFrozen
        ) {
            uint256 _borrow = _availableToBorrowReserve(_vault, _liquidityPoolAddressProviderRegistry, _outputToken);
            if (_borrow > 0) {
                bool _isUserCollateralEnabled =
                    _getUserReserveData(_liquidityPoolAddressProviderRegistry, _underlyingToken, _vault)
                        .usageAsCollateralEnabled;
                if (_isUserCollateralEnabled) {
                    _codes = new bytes[](1);
                    _codes[0] = abi.encode(
                        _lendingPool,
                        abi.encodeWithSignature(
                            "borrow(address,uint256,uint256,uint16,address)",
                            _outputToken,
                            _borrow,
                            uint256(1),
                            uint16(0),
                            _vault
                        )
                    );
                } else {
                    _codes = new bytes[](2);
                    _codes[0] = abi.encode(
                        _lendingPool,
                        abi.encodeWithSignature("setUserUseReserveAsCollateral(address,bool)", _underlyingToken, true)
                    );
                    _codes[1] = abi.encode(
                        _lendingPool,
                        abi.encodeWithSignature(
                            "borrow(address,uint256,uint256,uint16,address)",
                            _outputToken,
                            _borrow,
                            uint256(1),
                            uint16(0),
                            _vault
                        )
                    );
                }
            }
        } else {
            revert("!borrow");
        }
    }

    /**
     * @inheritdoc IAdapterBorrow
     */
    function getRepayAndWithdrawAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPoolAddressProviderRegistry,
        address _outputToken
    ) public view override returns (bytes[] memory _codes) {
        address _lendingPool = _getLendingPool(_liquidityPoolAddressProviderRegistry);
        uint256 _liquidityPoolTokenBalance =
            getLiquidityPoolTokenBalance(_vault, _underlyingToken, _liquidityPoolAddressProviderRegistry);

        // borrow token amount
        uint256 _borrowAmount = ERC20(_outputToken).balanceOf(_vault);

        uint256 _aTokenAmount =
            _maxWithdrawal(
                _vault,
                _liquidityPoolAddressProviderRegistry,
                _liquidityPoolTokenBalance,
                _outputToken,
                _borrowAmount
            );

        uint256 _outputTokenRepayable =
            _over(_vault, _underlyingToken, _liquidityPoolAddressProviderRegistry, _outputToken, _aTokenAmount);

        if (_outputTokenRepayable > 0) {
            if (_outputTokenRepayable > _borrowAmount) {
                _outputTokenRepayable = _borrowAmount;
            }
            if (_outputTokenRepayable > 0) {
                address _liquidityPoolToken =
                    getLiquidityPoolToken(_underlyingToken, _liquidityPoolAddressProviderRegistry);
                _codes = new bytes[](6);
                _codes[0] = abi.encode(
                    _outputToken,
                    abi.encodeWithSignature("approve(address,uint256)", _lendingPool, uint256(0))
                );
                _codes[1] = abi.encode(
                    _outputToken,
                    abi.encodeWithSignature("approve(address,uint256)", _lendingPool, _borrowAmount)
                );
                _codes[2] = abi.encode(
                    _lendingPool,
                    abi.encodeWithSignature(
                        "repay(address,uint256,uint256,address)",
                        _outputToken,
                        _borrowAmount,
                        uint256(1),
                        _vault
                    )
                );
                _codes[3] = abi.encode(
                    _liquidityPoolToken,
                    abi.encodeWithSignature("approve(address,uint256)", _lendingPool, uint256(0))
                );
                _codes[4] = abi.encode(
                    _liquidityPoolToken,
                    abi.encodeWithSignature("approve(address,uint256)", _lendingPool, _aTokenAmount)
                );
                _codes[5] = abi.encode(
                    _lendingPool,
                    abi.encodeWithSignature(
                        "withdraw(address,uint256,address)",
                        _underlyingToken,
                        _aTokenAmount,
                        _vault
                    )
                );
            }
        }
    }

    /**
     * @inheritdoc IAdapter
     */
    function getWithdrawAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPoolAddressProviderRegistry
    ) public view override returns (bytes[] memory) {
        uint256 _redeemAmount =
            getLiquidityPoolTokenBalance(_vault, _underlyingToken, _liquidityPoolAddressProviderRegistry);
        return getWithdrawSomeCodes(_vault, _underlyingToken, _liquidityPoolAddressProviderRegistry, _redeemAmount);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getUnderlyingTokens(address, address _liquidityPoolToken)
        public
        view
        override
        returns (address[] memory _underlyingTokens)
    {
        _underlyingTokens = new address[](1);
        _underlyingTokens[0] = IAaveV2Token(_liquidityPoolToken).UNDERLYING_ASSET_ADDRESS();
    }

    /**
     * @inheritdoc IAdapter
     */
    function getSomeAmountInToken(
        address,
        address,
        uint256 _liquidityPoolTokenAmount
    ) public view override returns (uint256) {
        return _liquidityPoolTokenAmount;
    }

    /**
     * @inheritdoc IAdapterBorrow
     */
    function getAllAmountInTokenBorrow(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPoolAddressProviderRegistry,
        address _borrowToken,
        uint256 _borrowAmount
    ) public view override returns (uint256) {
        uint256 _liquidityPoolTokenBalance =
            getLiquidityPoolTokenBalance(_vault, _underlyingToken, _liquidityPoolAddressProviderRegistry);
        return
            getSomeAmountInTokenBorrow(
                _vault,
                _underlyingToken,
                _liquidityPoolAddressProviderRegistry,
                _liquidityPoolTokenBalance,
                _borrowToken,
                _borrowAmount
            );
    }

    /**
     * @inheritdoc IAdapter
     */
    function calculateAmountInLPToken(
        address,
        address,
        uint256 _underlyingTokenAmount
    ) public view override returns (uint256) {
        return _underlyingTokenAmount;
    }

    /**
     * @inheritdoc IAdapter
     */
    function calculateRedeemableLPTokenAmount(
        address payable,
        address,
        address,
        uint256 _redeemAmount
    ) public view override returns (uint256) {
        return _redeemAmount;
    }

    /**
     * @inheritdoc IAdapter
     */
    function isRedeemableAmountSufficient(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPoolAddressProviderRegistry,
        uint256 _redeemAmount
    ) public view override returns (bool) {
        uint256 _balanceInToken = getAllAmountInToken(_vault, _underlyingToken, _liquidityPoolAddressProviderRegistry);
        return _balanceInToken >= _redeemAmount;
    }

    /**
     * @inheritdoc IAdapter
     */
    function getRewardToken(address) public view override returns (address) {
        return address(0);
    }

    /**
     * @inheritdoc IAdapter
     */
    function canStake(address) public view override returns (bool) {
        return false;
    }

    /**
     * @inheritdoc IAdapter
     */
    function getLiquidityPoolToken(address _underlyingToken, address _liquidityPoolAddressProviderRegistry)
        public
        view
        override
        returns (address)
    {
        address _lendingPool = _getLendingPool(_liquidityPoolAddressProviderRegistry);
        ReserveDataV2 memory _reserveData = IAaveV2(_lendingPool).getReserveData(_underlyingToken);
        return _reserveData.aTokenAddress;
    }

    /**
     * @inheritdoc IAdapter
     */
    function getAllAmountInToken(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPoolAddressProviderRegistry
    ) public view override returns (uint256) {
        return getLiquidityPoolTokenBalance(_vault, _underlyingToken, _liquidityPoolAddressProviderRegistry);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getLiquidityPoolTokenBalance(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPoolAddressProviderRegistry
    ) public view override returns (uint256) {
        return ERC20(getLiquidityPoolToken(_underlyingToken, _liquidityPoolAddressProviderRegistry)).balanceOf(_vault);
    }

    /**
     * @inheritdoc IAdapterBorrow
     */
    function getSomeAmountInTokenBorrow(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPoolAddressProviderRegistry,
        uint256 _liquidityPoolTokenBalance,
        address _borrowToken,
        uint256 _borrowAmount
    ) public view override returns (uint256) {
        uint256 _aTokenAmount =
            _maxWithdrawal(
                _vault,
                _liquidityPoolAddressProviderRegistry,
                _liquidityPoolTokenBalance,
                _borrowToken,
                _borrowAmount
            );
        uint256 _outputTokenRepayable =
            _over(_vault, _underlyingToken, _liquidityPoolAddressProviderRegistry, _borrowToken, _aTokenAmount);
        if (_outputTokenRepayable > _borrowAmount) {
            return _aTokenAmount;
        } else {
            return
                _aTokenAmount.add(
                    IHarvestCodeProvider(registryContract.getHarvestCodeProvider()).getOptimalTokenAmount(
                        _borrowToken,
                        _underlyingToken,
                        _borrowAmount.sub(_outputTokenRepayable)
                    )
                );
        }
    }

    /**
     * @inheritdoc IAdapter
     */
    function getPoolValue(address _liquidityPoolAddressProviderRegistry, address _underlyingToken)
        public
        view
        override
        returns (uint256)
    {
        return _getReserveData(_liquidityPoolAddressProviderRegistry, _underlyingToken).availableLiquidity;
    }

    /**
     * @inheritdoc IAdapter
     */
    function getDepositSomeCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPoolAddressProviderRegistry,
        uint256 _amount
    ) public view override returns (bytes[] memory _codes) {
        uint256 _depositAmount = _getDepositAmount(_liquidityPoolAddressProviderRegistry, _underlyingToken, _amount);
        if (_depositAmount > 0) {
            address _lendingPool = _getLendingPool(_liquidityPoolAddressProviderRegistry);
            _codes = new bytes[](3);
            _codes[0] = abi.encode(
                _underlyingToken,
                abi.encodeWithSignature("approve(address,uint256)", _lendingPool, uint256(0))
            );
            _codes[1] = abi.encode(
                _underlyingToken,
                abi.encodeWithSignature("approve(address,uint256)", _lendingPool, _depositAmount)
            );
            _codes[2] = abi.encode(
                _lendingPool,
                abi.encodeWithSignature(
                    "deposit(address,uint256,address,uint16)",
                    _underlyingToken,
                    _depositAmount,
                    _vault,
                    uint16(0)
                )
            );
        }
    }

    /**
     * @inheritdoc IAdapter
     */
    function getWithdrawSomeCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPoolAddressProviderRegistry,
        uint256 _amount
    ) public view override returns (bytes[] memory _codes) {
        if (_amount > 0) {
            address _lendingPool = _getLendingPool(_liquidityPoolAddressProviderRegistry);
            address _liquidityPoolToken =
                getLiquidityPoolToken(_underlyingToken, _liquidityPoolAddressProviderRegistry);
            _codes = new bytes[](3);
            _codes[0] = abi.encode(
                _liquidityPoolToken,
                abi.encodeWithSignature("approve(address,uint256)", _lendingPool, uint256(0))
            );
            _codes[1] = abi.encode(
                _liquidityPoolToken,
                abi.encodeWithSignature("approve(address,uint256)", _lendingPool, _amount)
            );
            _codes[2] = abi.encode(
                _lendingPool,
                abi.encodeWithSignature("withdraw(address,uint256,address)", _underlyingToken, _amount, _vault)
            );
        }
    }

    function _getLendingPool(address _lendingPoolAddressProviderRegistry) internal view returns (address) {
        return
            IAaveV2LendingPoolAddressesProvider(_getLendingPoolAddressProvider(_lendingPoolAddressProviderRegistry))
                .getLendingPool();
    }

    function _getPriceOracle(address _lendingPoolAddressProviderRegistry) internal view returns (address) {
        return
            IAaveV2LendingPoolAddressesProvider(_getLendingPoolAddressProvider(_lendingPoolAddressProviderRegistry))
                .getPriceOracle();
    }

    function _getDepositAmount(
        address _liquidityPool,
        address _underlyingToken,
        uint256 _amount
    ) internal view returns (uint256) {
        uint256 _limit =
            maxDepositProtocolMode == MaxExposure.Pct
                ? _getMaxDepositAmountByPct(_liquidityPool, _underlyingToken)
                : maxDepositAmount[_liquidityPool][_underlyingToken];
        return _amount > _limit ? _limit : _amount;
    }

    function _getMaxDepositAmountByPct(address _liquidityPool, address _underlyingToken)
        internal
        view
        returns (uint256)
    {
        uint256 _poolValue = getPoolValue(_liquidityPool, _underlyingToken);
        uint256 _poolPct = maxDepositPoolPct[_liquidityPool];
        uint256 _limit =
            _poolPct == 0
                ? _poolValue.mul(maxDepositProtocolPct).div(uint256(10000))
                : _poolValue.mul(_poolPct).div(uint256(10000));
        return _limit;
    }

    function _maxSafeETH(address _vault, address _liquidityPoolAddressProviderRegistry)
        internal
        view
        returns (
            uint256 maxBorrowsETH,
            uint256 totalBorrowsETH,
            uint256 availableBorrowsETH
        )
    {
        UserAccountData memory _userAccountData =
            IAaveV2(_getLendingPool(_liquidityPoolAddressProviderRegistry)).getUserAccountData(_vault);
        uint256 _totalBorrowsETH = _userAccountData.totalDebtETH;
        uint256 _availableBorrowsETH = _userAccountData.availableBorrowsETH;
        uint256 _maxBorrowETH = (_totalBorrowsETH.add(_availableBorrowsETH));
        return (_maxBorrowETH.div(healthFactor), _totalBorrowsETH, _availableBorrowsETH);
    }

    function _availableToBorrowETH(address _vault, address _liquidityPoolAddressProviderRegistry)
        internal
        view
        returns (uint256)
    {
        (uint256 _maxSafeETH_, uint256 _totalBorrowsETH, uint256 _availableBorrowsETH) =
            _maxSafeETH(_vault, _liquidityPoolAddressProviderRegistry);
        _maxSafeETH_ = _maxSafeETH_.mul(95).div(100); // 5% buffer so we don't go into a earn/rebalance loop
        if (_maxSafeETH_ > _totalBorrowsETH) {
            return _availableBorrowsETH.mul(_maxSafeETH_.sub(_totalBorrowsETH)).div(_availableBorrowsETH);
        } else {
            return 0;
        }
    }

    function _getReservePrice(address _liquidityPoolAddressProviderRegistry, address _token)
        internal
        view
        returns (uint256)
    {
        return _getReservePriceETH(_liquidityPoolAddressProviderRegistry, _token);
    }

    function _getReservePriceETH(address _liquidityPoolAddressProviderRegistry, address _token)
        internal
        view
        returns (uint256)
    {
        return IAaveV2PriceOracle(_getPriceOracle(_liquidityPoolAddressProviderRegistry)).getAssetPrice(_token);
    }

    function _availableToBorrowReserve(
        address _vault,
        address _liquidityPoolAddressProvider,
        address _outputToken
    ) internal view returns (uint256) {
        uint256 _available = _availableToBorrowETH(_vault, _liquidityPoolAddressProvider);
        if (_available > 0) {
            return
                _available.mul(uint256(10)**ERC20(_outputToken).decimals()).div(
                    _getReservePrice(_liquidityPoolAddressProvider, _outputToken)
                );
        } else {
            return 0;
        }
    }

    function _getUnderlyingPrice(address _liquidityPoolAddressProviderRegistry, address _underlyingToken)
        internal
        view
        returns (uint256)
    {
        return _getReservePriceETH(_liquidityPoolAddressProviderRegistry, _underlyingToken);
    }

    function _getUnderlyingPriceETH(
        address _underlyingToken,
        address _liquidityPoolAddressProviderRegistry,
        uint256 _amount
    ) internal view returns (uint256) {
        address _liquidityPoolToken = getLiquidityPoolToken(_underlyingToken, _liquidityPoolAddressProviderRegistry);
        _amount = _amount.mul(_getUnderlyingPrice(_liquidityPoolAddressProviderRegistry, _underlyingToken)).div(
            uint256(10)**ERC20(address(_liquidityPoolToken)).decimals()
        ); // Calculate the amount we are withdrawing in ETH
        return _amount.mul(ltv).div(max).div(healthFactor);
    }

    function _over(
        address _vault,
        address _underlyingToken,
        address _liquidityPoolAddressProviderRegistry,
        address _outputToken,
        uint256 _amount
    ) internal view returns (uint256) {
        uint256 _eth = _getUnderlyingPriceETH(_underlyingToken, _liquidityPoolAddressProviderRegistry, _amount);
        (uint256 _maxSafeETH_, uint256 _totalBorrowsETH, ) = _maxSafeETH(_vault, _liquidityPoolAddressProviderRegistry);
        _maxSafeETH_ = _maxSafeETH_.mul(105).div(100); // 5% buffer so we don't go into a earn/rebalance loop
        if (_eth > _maxSafeETH_) {
            _maxSafeETH_ = 0;
        } else {
            _maxSafeETH_ = _maxSafeETH_.sub(_eth); // Add the ETH we are withdrawing
        }
        if (_maxSafeETH_ < _totalBorrowsETH) {
            uint256 _over_ = _totalBorrowsETH.mul(_totalBorrowsETH.sub(_maxSafeETH_)).div(_totalBorrowsETH);
            _over_ = _over_.mul(uint256(10)**ERC20(_outputToken).decimals()).div(
                _getReservePrice(_liquidityPoolAddressProviderRegistry, _outputToken)
            );
            return _over_;
        } else {
            return 0;
        }
    }

    function _getUserReserveData(
        address _liquidityPoolAddressProviderRegistry,
        address _underlyingToken,
        address _vault
    ) internal view returns (UserReserveData memory) {
        return
            IAaveV2ProtocolDataProvider(_getProtocolDataProvider(_liquidityPoolAddressProviderRegistry))
                .getUserReserveData(_underlyingToken, _vault);
    }

    function _getReserveData(address _liquidityPoolAddressProviderRegistry, address _underlyingToken)
        internal
        view
        returns (ReserveDataProtocol memory)
    {
        return
            IAaveV2ProtocolDataProvider(_getProtocolDataProvider(_liquidityPoolAddressProviderRegistry)).getReserveData(
                _underlyingToken
            );
    }

    function _debt(
        address _vault,
        address _liquidityPoolAddressProviderRegistry,
        address _outputToken
    ) internal view returns (uint256) {
        return
            IAaveV2ProtocolDataProvider(_getProtocolDataProvider(_liquidityPoolAddressProviderRegistry))
                .getUserReserveData(_outputToken, _vault)
                .currentStableDebt;
    }

    // % of tokens locked and cannot be withdrawn per user
    // this is impermanent locked, unless the debt out accrues the strategy
    function _locked(
        address _vault,
        address _liquidityPoolAddressProviderRegistry,
        address _borrowToken,
        uint256 _borrowAmount
    ) internal view returns (uint256) {
        return _borrowAmount.mul(1e18).div(_debt(_vault, _liquidityPoolAddressProviderRegistry, _borrowToken));
    }

    // Calculates in impermanent lock due to debt
    function _maxWithdrawal(
        address _vault,
        address _liquidityPoolAddressProviderRegistry,
        uint256 _aTokenAmount,
        address _borrowToken,
        uint256 _borrowAmount
    ) internal view returns (uint256) {
        uint256 _safeWithdraw =
            _aTokenAmount.mul(_locked(_vault, _liquidityPoolAddressProviderRegistry, _borrowToken, _borrowAmount)).div(
                1e18
            );
        if (_safeWithdraw > _aTokenAmount) {
            return _aTokenAmount;
        } else {
            uint256 _diff = _aTokenAmount.sub(_safeWithdraw);
            return _aTokenAmount.sub(_diff.mul(healthFactor)); // technically 150%, not 200%, but adding buffer
        }
    }

    function _getLendingPoolAddressProvider(address _liquidityPoolAddressProviderRegistry)
        internal
        view
        returns (address)
    {
        return
            IAaveV2LendingPoolAddressProviderRegistry(_liquidityPoolAddressProviderRegistry)
                .getAddressesProvidersList()[0];
    }

    function _getProtocolDataProvider(address _liquidityPoolAddressProviderRegistry) internal view returns (address) {
        return
            IAaveV2LendingPoolAddressesProvider(_getLendingPoolAddressProvider(_liquidityPoolAddressProviderRegistry))
                .getAddress(PROTOCOL_DATA_PROVIDER_ID);
    }
}