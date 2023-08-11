// solhint-disable no-unused-vars
// SPDX-License-Identifier:MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

//  libraries
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

//  helper contracts
import { Modifiers } from "../../earn-protocol-configuration/contracts/Modifiers.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { CurveSwapETHGateway } from "./CurveSwapETHGateway.sol";

//  interfaces
import { IAdapter } from "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapter.sol";
import { IAdapterHarvestReward } from "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapterHarvestReward.sol";
import "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapterInvestLimit.sol";
import { IAdapterStaking } from "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapterStaking.sol";
import { IAdapterStakingCurve } from "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapterStakingCurve.sol";
import { ICurveDeposit } from "@optyfi/defi-legos/ethereum/curve/contracts/interfacesV0/ICurveDeposit.sol";
import { ICurveSwap } from "@optyfi/defi-legos/ethereum/curve/contracts/interfacesV0/ICurveSwap.sol";
import { ICurveGauge } from "@optyfi/defi-legos/ethereum/curve/contracts/interfacesV0/ICurveGauge.sol";
import {
    ICurveAddressProvider
} from "@optyfi/defi-legos/ethereum/curve/contracts/interfacesV0/ICurveAddressProvider.sol";
import { ICurveRegistry } from "@optyfi/defi-legos/ethereum/curve/contracts/interfacesV0/ICurveRegistry.sol";
import { ITokenMinter } from "@optyfi/defi-legos/ethereum/curve/contracts/interfacesV0/ITokenMinter.sol";
import { IHarvestCodeProvider } from "../interfaces/IHarvestCodeProvider.sol";

/**
 * @title Adapter for Curve Swap pools
 * @author Opty.fi
 * @dev Abstraction layer to Curve's swap pools
 *      Note 1 : In this adapter, a liquidity pool is actually swap pool
 *      Note 2 : In this adapter, a swap pool is defined as a single-sided liquidity pool
 *      Note 3 : In this adapter, lp token can be redemeed into more than one underlying token
 */
contract CurveSwapPoolAdapter is
    IAdapter,
    IAdapterHarvestReward,
    IAdapterStaking,
    IAdapterInvestLimit,
    IAdapterStakingCurve,
    Modifiers
{
    using SafeMath for uint256;
    using Address for address;

    /** @notice max deposit value datatypes */
    MaxExposure public maxDepositProtocolMode;

    /** @dev ETH gateway contract for curveSwap adapter */
    address public immutable curveSwapETHGatewayContract;

    /** @notice  Curve Registry Address Provider */
    address public constant ADDRESS_PROVIDER = address(0x0000000022D53366457F9d5E68Ec105046FC4383);

    /** @notice HBTC token contract address */
    address public constant HBTC = address(0x0316EB71485b0Ab14103307bf65a021042c6d380);

    /** @notice Curve ETH/sETH StableSwap contract address*/
    address public constant ETH_sETH_STABLESWAP = address(0xc5424B857f758E906013F3555Dad202e4bdB4567);

    /** @notice Curve ETH/ankrETH StableSwap contract address*/
    address public constant ETH_ankrETH_STABLESWAP = address(0xA96A65c051bF88B4095Ee1f2451C2A9d43F53Ae2);

    /** @notice Curve ETH/rETH StableSwap contract address*/
    address public constant ETH_rETH_STABLESWAP = address(0xF9440930043eb3997fc70e1339dBb11F341de7A8);

    /** @notice Curve ETH/stETH StableSwap contract address*/
    address public constant ETH_stETH_STABLESWAP = address(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022);

    /** @notice Curve's iron bank swap contract address */
    address public constant Y_SWAP_POOL = address(0x2dded6Da1BF5DBdF597C45fcFaa3194e53EcfeAF);

    /** WETH ERC20 token address */
    address public constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    /** Address with no private key */
    address public constant ETH = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /** @notice max deposit's default value in percentage */
    uint256 public maxDepositProtocolPct; // basis points

    /** @notice Maps liquidityPool to absolute max deposit value in underlying */
    mapping(address => uint256) public maxDepositAmount;

    /** @notice  Maps liquidityPool to max deposit value in percentage */
    mapping(address => uint256) public maxDepositPoolPct; // basis points

    /**
     * @dev mapp coins and tokens to curve deposit pool
     */
    constructor(address _registry) public Modifiers(_registry) {
        curveSwapETHGatewayContract = address(
            new CurveSwapETHGateway(
                WETH,
                _registry,
                [ETH_sETH_STABLESWAP, ETH_ankrETH_STABLESWAP, ETH_rETH_STABLESWAP, ETH_stETH_STABLESWAP],
                true
            )
        );
        maxDepositProtocolPct = uint256(10000); // 100% (basis points)
        maxDepositProtocolMode = MaxExposure.Pct;
    }

    /**
     * @inheritdoc IAdapterInvestLimit
     */
    function setMaxDepositPoolPct(address _liquidityPool, uint256 _maxDepositPoolPct)
        external
        override
        onlyRiskOperator
    {
        maxDepositPoolPct[_liquidityPool] = _maxDepositPoolPct;
        emit LogMaxDepositPoolPct(maxDepositPoolPct[_liquidityPool], msg.sender);
    }

    /**
     * @inheritdoc IAdapterInvestLimit
     */
    function setMaxDepositAmount(
        address _liquidityPool,
        address,
        uint256 _maxDepositAmount
    ) external override onlyRiskOperator {
        // Note : use 18 as decimals for USD, BTC and ETH
        maxDepositAmount[_liquidityPool] = _maxDepositAmount;
        emit LogMaxDepositAmount(maxDepositAmount[_liquidityPool], msg.sender);
    }

    /**
     * @inheritdoc IAdapterInvestLimit
     */
    function setMaxDepositProtocolMode(MaxExposure _mode) external override onlyRiskOperator {
        maxDepositProtocolMode = _mode;
        emit LogMaxDepositProtocolMode(maxDepositProtocolMode, msg.sender);
    }

    /**
     * @inheritdoc IAdapterInvestLimit
     */
    function setMaxDepositProtocolPct(uint256 _maxDepositProtocolPct) external override onlyRiskOperator {
        maxDepositProtocolPct = _maxDepositProtocolPct;
        emit LogMaxDepositProtocolPct(maxDepositProtocolPct, msg.sender);
    }

    /**
     * @inheritdoc IAdapterStakingCurve
     */
    function getAllAmountInTokenStakeWrite(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool
    ) external override returns (uint256) {
        uint256 _liquidityPoolTokenAmount = getLiquidityPoolTokenBalanceStake(_vault, _liquidityPool);
        return _getAllAmountInTokenStakeWrite(_vault, _underlyingToken, _liquidityPool, _liquidityPoolTokenAmount);
    }

    /**
     * @inheritdoc IAdapterStakingCurve
     */
    function getUnclaimedRewardTokenAmountWrite(
        address payable _vault,
        address _liquidityPool,
        address
    ) external override returns (uint256) {
        return _getUnclaimedRewardTokenAmountWrite(_vault, _liquidityPool);
    }

    /**
     * @inheritdoc IAdapterStakingCurve
     */
    function calculateRedeemableLPTokenAmountStakeWrite(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _redeemAmount
    ) external override returns (uint256) {
        uint256 _stakedLiquidityPoolTokenBalance = getLiquidityPoolTokenBalanceStake(_vault, _liquidityPool);
        uint256 _balanceInTokenStaked =
            _getAllAmountInTokenStakeWrite(_vault, _underlyingToken, _liquidityPool, _stakedLiquidityPoolTokenBalance);
        // can have unintentional rounding errors
        return (_stakedLiquidityPoolTokenBalance.mul(_redeemAmount)).div(_balanceInTokenStaked).add(1);
    }

    /**
     * @inheritdoc IAdapterStakingCurve
     */
    function isRedeemableAmountSufficientStakeWrite(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _redeemAmount
    ) external override returns (bool) {
        uint256 _liquidityPoolTokenAmount = getLiquidityPoolTokenBalanceStake(_vault, _liquidityPool);
        uint256 _balanceInTokenStaked =
            _getAllAmountInTokenStakeWrite(_vault, _underlyingToken, _liquidityPool, _liquidityPoolTokenAmount);
        return _balanceInTokenStaked >= _redeemAmount;
    }

    /**
     * @inheritdoc IAdapter
     */
    function getPoolValue(address _liquidityPool, address) public view override returns (uint256) {
        uint256 _virtualPrice = ICurveSwap(_liquidityPool).get_virtual_price();
        uint256 _totalSupply = ERC20(getLiquidityPoolToken(address(0), _liquidityPool)).totalSupply();
        // the pool value will be in USD for US dollar stablecoin pools
        // the pool value will be in BTC for BTC pools
        return (_virtualPrice.mul(_totalSupply)).div(10**18);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getDepositAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool
    ) public view override returns (bytes[] memory) {
        uint256 _amount = ERC20(_underlyingToken).balanceOf(_vault);
        return _getDepositCode(_vault, _underlyingToken, _liquidityPool, _amount);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getWithdrawAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool
    ) public view override returns (bytes[] memory) {
        uint256 _amount = getLiquidityPoolTokenBalance(_vault, address(0), _liquidityPool);
        return getWithdrawSomeCodes(_vault, _underlyingToken, _liquidityPool, _amount);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getUnderlyingTokens(address _liquidityPool, address)
        public
        view
        override
        returns (address[] memory _underlyingTokens)
    {
        address _curveRegistry = _getCurveRegistry();
        address[8] memory _underlyingCoins = _getUnderlyingTokens(_liquidityPool, _curveRegistry);
        uint256 _nCoins = _getNCoins(_liquidityPool, _curveRegistry);
        _underlyingTokens = new address[](_nCoins);
        for (uint256 _i = 0; _i < _nCoins; _i++) {
            _underlyingTokens[_i] = _underlyingCoins[_i];
        }
    }

    /**
     * @inheritdoc IAdapter
     */
    function calculateAmountInLPToken(
        address _underlyingToken,
        address _liquidityPool,
        uint256 _underlyingTokenAmount
    ) public view override returns (uint256) {
        if (_underlyingTokenAmount > 0) {
            uint256 _nCoins = _getNCoins(_liquidityPool, _getCurveRegistry());
            address[8] memory _underlyingTokens = _getUnderlyingTokens(_liquidityPool, _getCurveRegistry());
            uint256[] memory _amounts = new uint256[](_nCoins);
            _underlyingToken = _underlyingToken == WETH ? ETH : _underlyingToken;
            for (uint256 _i; _i < _nCoins; _i++) {
                if (_underlyingTokens[_i] == _underlyingToken) {
                    _amounts[_i] = _underlyingTokenAmount;
                }
            }
            if (_nCoins == 2) {
                return ICurveSwap(_liquidityPool).calc_token_amount([_amounts[0], _amounts[1]], true);
            } else if (_nCoins == 3) {
                return ICurveSwap(_liquidityPool).calc_token_amount([_amounts[0], _amounts[1], _amounts[2]], true);
            } else if (_nCoins == 4) {
                return
                    ICurveSwap(_liquidityPool).calc_token_amount(
                        [_amounts[0], _amounts[1], _amounts[2], _amounts[3]],
                        true
                    );
            }
        }
        return uint256(0);
    }

    /**
     * @inheritdoc IAdapter
     */
    function calculateRedeemableLPTokenAmount(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _redeemAmount
    ) public view override returns (uint256) {
        uint256 _liquidityPoolTokenBalance = getLiquidityPoolTokenBalance(_vault, address(0), _liquidityPool);
        uint256 _balanceInToken = getAllAmountInToken(_vault, _underlyingToken, _liquidityPool);
        // can have unintentional rounding errors
        return (_liquidityPoolTokenBalance.mul(_redeemAmount)).div(_balanceInToken).add(1);
    }

    /**
     * @inheritdoc IAdapter
     */
    function isRedeemableAmountSufficient(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _redeemAmount
    ) public view override returns (bool) {
        uint256 _balanceInToken = getAllAmountInToken(_vault, _underlyingToken, _liquidityPool);
        return _balanceInToken >= _redeemAmount;
    }

    /**
     * @inheritdoc IAdapterHarvestReward
     */
    function getClaimRewardTokenCode(address payable, address _liquidityPool)
        public
        view
        override
        returns (bytes[] memory _codes)
    {
        address _curveRegistry = _getCurveRegistry();
        address _liquidityGauge = _getLiquidityGauge(_liquidityPool, _curveRegistry);
        if (_liquidityGauge != address(0)) {
            _codes = new bytes[](1);
            _codes[0] = abi.encode(
                _getMinter(_liquidityGauge),
                abi.encodeWithSignature("mint(address)", _liquidityGauge)
            );
        }
    }

    /**
     * @inheritdoc IAdapterHarvestReward
     */
    function getHarvestAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool
    ) public view override returns (bytes[] memory) {
        uint256 _rewardTokenAmount = ERC20(getRewardToken(_liquidityPool)).balanceOf(_vault);
        return getHarvestSomeCodes(_vault, _underlyingToken, _liquidityPool, _rewardTokenAmount);
    }

    /**
     * @inheritdoc IAdapter
     */
    function canStake(address _liquidityPool) public view override returns (bool) {
        address _curveRegistry = _getCurveRegistry();
        if (_getLiquidityGauge(_liquidityPool, _curveRegistry) != address(0)) {
            return true;
        }
        return false;
    }

    /**
     * @inheritdoc IAdapterStaking
     */
    function getStakeAllCodes(
        address payable _vault,
        address,
        address _liquidityPool
    ) public view override returns (bytes[] memory) {
        uint256 _stakeAmount = getLiquidityPoolTokenBalance(_vault, address(0), _liquidityPool);
        return getStakeSomeCodes(_liquidityPool, _stakeAmount);
    }

    /**
     * @inheritdoc IAdapterStaking
     */
    function getUnstakeAllCodes(address payable _vault, address _liquidityPool)
        public
        view
        override
        returns (bytes[] memory)
    {
        uint256 _unstakeAmount = getLiquidityPoolTokenBalanceStake(_vault, _liquidityPool);
        return getUnstakeSomeCodes(_liquidityPool, _unstakeAmount);
    }

    /**
     * @inheritdoc IAdapterStaking
     */
    function calculateRedeemableLPTokenAmountStake(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _redeemAmount
    ) public view override returns (uint256) {
        // Note : This function does not take into account unclaimed reward tokens
        uint256 _liquidityPoolTokenBalance = getLiquidityPoolTokenBalanceStake(_vault, _liquidityPool);
        uint256 _balanceInToken = getSomeAmountInToken(_underlyingToken, _liquidityPool, _liquidityPoolTokenBalance);
        // can have unintentional rounding errors
        return (_liquidityPoolTokenBalance.mul(_redeemAmount)).div(_balanceInToken).add(1);
    }

    /**
     * @inheritdoc IAdapterStaking
     */
    function isRedeemableAmountSufficientStake(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _redeemAmount
    ) public view override returns (bool) {
        // Note : This function does not take into account unclaimed reward tokens
        uint256 _liquidityPoolTokenBalance = getLiquidityPoolTokenBalanceStake(_vault, _liquidityPool);
        uint256 _balanceInToken = getSomeAmountInToken(_underlyingToken, _liquidityPool, _liquidityPoolTokenBalance);
        return _balanceInToken >= _redeemAmount;
    }

    /**
     * @inheritdoc IAdapterStaking
     */
    function getUnstakeAndWithdrawAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool
    ) public view override returns (bytes[] memory) {
        uint256 _redeemAmount = getLiquidityPoolTokenBalanceStake(_vault, _liquidityPool);
        return getUnstakeAndWithdrawSomeCodes(_vault, _underlyingToken, _liquidityPool, _redeemAmount);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getDepositSomeCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _amount
    ) public view override returns (bytes[] memory) {
        return _getDepositCode(_vault, _underlyingToken, _liquidityPool, _amount);
    }

    /**
     * @inheritdoc IAdapter
     * @dev Note : swap pools of compound,usdt,pax,y,susd and busd
     *             does not have remove_liquidity_one_coin function
     */
    function getWithdrawSomeCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _amount
    ) public view override returns (bytes[] memory _codes) {
        if (_amount > 0) {
            address _lendingPool = _underlyingToken == WETH ? curveSwapETHGatewayContract : _liquidityPool;
            address _liquidityPoolToken = getLiquidityPoolToken(address(0), _liquidityPool);
            _codes = new bytes[](3);
            _codes[0] = abi.encode(
                _liquidityPoolToken,
                abi.encodeWithSignature("approve(address,uint256)", _lendingPool, uint256(0))
            );
            _codes[1] = abi.encode(
                _liquidityPoolToken,
                abi.encodeWithSignature("approve(address,uint256)", _lendingPool, _amount)
            );

            _codes[2] = _underlyingToken == WETH
                ? abi.encode(
                    curveSwapETHGatewayContract,
                    // solhint-disable-next-line max-line-length
                    abi.encodeWithSignature(
                        "withdrawETH(address,address,address,uint256,int128)",
                        _vault,
                        _liquidityPool,
                        _liquidityPoolToken,
                        _amount,
                        _getTokenIndex(_liquidityPool, _underlyingToken)
                    )
                )
                : abi.encode(
                    _lendingPool,
                    // solhint-disable-next-line max-line-length
                    abi.encodeWithSignature(
                        "remove_liquidity_one_coin(uint256,int128,uint256)",
                        _amount,
                        _getTokenIndex(_liquidityPool, _underlyingToken),
                        getSomeAmountInToken(_underlyingToken, _liquidityPool, _amount).mul(95).div(100)
                    )
                );
        }
    }

    /**
     * @inheritdoc IAdapter
     */
    function getLiquidityPoolToken(address, address _liquidityPool) public view override returns (address) {
        return ICurveRegistry(_getCurveRegistry()).get_lp_token(_liquidityPool);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getAllAmountInToken(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool
    ) public view override returns (uint256) {
        uint256 _liquidityPoolTokenAmount = getLiquidityPoolTokenBalance(_vault, address(0), _liquidityPool);
        return getSomeAmountInToken(_underlyingToken, _liquidityPool, _liquidityPoolTokenAmount);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getLiquidityPoolTokenBalance(
        address payable _vault,
        address,
        address _liquidityPool
    ) public view override returns (uint256) {
        return ERC20(getLiquidityPoolToken(address(0), _liquidityPool)).balanceOf(_vault);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getSomeAmountInToken(
        address _underlyingToken,
        address _liquidityPool,
        uint256 _liquidityPoolTokenAmount
    ) public view override returns (uint256) {
        if (_liquidityPoolTokenAmount > 0) {
            return
                ICurveDeposit(_liquidityPool).calc_withdraw_one_coin(
                    _liquidityPoolTokenAmount,
                    _getTokenIndex(_liquidityPool, _underlyingToken)
                );
        }
        return 0;
    }

    /**
     * @inheritdoc IAdapter
     */
    function getRewardToken(address _liquidityPool) public view override returns (address) {
        address _curveRegistry = _getCurveRegistry();
        address _liquidityGauge = _getLiquidityGauge(_liquidityPool, _curveRegistry);
        if (_liquidityGauge != address(0)) {
            return ITokenMinter(_getMinter(_liquidityGauge)).token();
        }
        return address(0);
    }

    /* solhint-disable no-empty-blocks */
    /**
     * @inheritdoc IAdapterHarvestReward
     */
    function getUnclaimedRewardTokenAmount(
        address payable,
        address _liquidityPool,
        address
    ) public view override returns (uint256) {}

    /* solhint-enable no-empty-blocks */

    /**
     * @inheritdoc IAdapterHarvestReward
     */
    function getHarvestSomeCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _rewardTokenAmount
    ) public view override returns (bytes[] memory) {
        return
            IHarvestCodeProvider(registryContract.getHarvestCodeProvider()).getHarvestCodes(
                _vault,
                getRewardToken(_liquidityPool),
                _underlyingToken,
                _rewardTokenAmount
            );
    }

    /* solhint-disable no-empty-blocks */
    /**
     * @inheritdoc IAdapterHarvestReward
     */
    function getAddLiquidityCodes(address payable, address) public view override returns (bytes[] memory) {}

    /* solhint-enable no-empty-blocks */

    /**
     * @inheritdoc IAdapterStaking
     */
    function getStakeSomeCodes(address _liquidityPool, uint256 _stakeAmount)
        public
        view
        override
        returns (bytes[] memory _codes)
    {
        if (_stakeAmount > 0) {
            address _curveRegistry = _getCurveRegistry();
            address _liquidityGauge = _getLiquidityGauge(_liquidityPool, _curveRegistry);
            address _liquidityPoolToken = getLiquidityPoolToken(address(0), _liquidityPool);
            _codes = new bytes[](3);
            _codes[0] = abi.encode(
                _liquidityPoolToken,
                abi.encodeWithSignature("approve(address,uint256)", _liquidityGauge, uint256(0))
            );
            _codes[1] = abi.encode(
                _liquidityPoolToken,
                abi.encodeWithSignature("approve(address,uint256)", _liquidityGauge, _stakeAmount)
            );
            _codes[2] = abi.encode(_liquidityGauge, abi.encodeWithSignature("deposit(uint256)", _stakeAmount));
        }
    }

    /**
     * @inheritdoc IAdapterStaking
     */
    function getUnstakeSomeCodes(address _liquidityPool, uint256 _unstakeAmount)
        public
        view
        override
        returns (bytes[] memory _codes)
    {
        if (_unstakeAmount > 0) {
            address _curveRegistry = _getCurveRegistry();
            address _liquidityGauge = _getLiquidityGauge(_liquidityPool, _curveRegistry);
            _codes = new bytes[](1);
            _codes[0] = abi.encode(_liquidityGauge, abi.encodeWithSignature("withdraw(uint256)", _unstakeAmount));
        }
    }

    /**
     * @inheritdoc IAdapterStaking
     */
    function getAllAmountInTokenStake(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool
    ) public view override returns (uint256) {
        // Note : This function does not take into account unclaimed reward tokens
        uint256 _liquidityPoolTokenBalanceStake = getLiquidityPoolTokenBalanceStake(_vault, _liquidityPool);
        return getSomeAmountInToken(_underlyingToken, _liquidityPool, _liquidityPoolTokenBalanceStake);
    }

    /**
     * @inheritdoc IAdapterStaking
     */
    function getLiquidityPoolTokenBalanceStake(address payable _vault, address _liquidityPool)
        public
        view
        override
        returns (uint256)
    {
        return ICurveGauge(_getLiquidityGauge(_liquidityPool, _getCurveRegistry())).balanceOf(_vault);
    }

    /**
     * @inheritdoc IAdapterStaking
     */
    function getUnstakeAndWithdrawSomeCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _redeemAmount
    ) public view override returns (bytes[] memory _codes) {
        if (_redeemAmount > 0) {
            _codes = new bytes[](4);
            _codes[0] = getUnstakeSomeCodes(_liquidityPool, _redeemAmount)[0];
            bytes[] memory _withdrawCodes =
                getWithdrawSomeCodes(_vault, _underlyingToken, _liquidityPool, _redeemAmount);
            _codes[1] = _withdrawCodes[0];
            _codes[2] = _withdrawCodes[1];
            _codes[3] = _withdrawCodes[2];
        }
    }

    /**
     * @notice Returns the balance in underlying for staked liquidityPoolToken balance of holder
     * @dev It should only be implemented in Curve adapters
     * @param _vault Vault contract address
     * @param _underlyingToken Underlying token address for the given liquidity pool
     * @param _liquidityPool Liquidity pool's contract address where the vault has deposited and which is associated
     * to a staking pool where to stake all lpTokens
     * @return Returns the equivalent amount of underlying tokens to the staked amount of liquidityPoolToken
     */
    function _getAllAmountInTokenStakeWrite(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _liquidityPoolTokenAmount
    ) internal returns (uint256) {
        uint256 _b = getSomeAmountInToken(_underlyingToken, _liquidityPool, _liquidityPoolTokenAmount);
        _b = _b.add(
            IHarvestCodeProvider(registryContract.getHarvestCodeProvider()).rewardBalanceInUnderlyingTokens(
                getRewardToken(_liquidityPool),
                _underlyingToken,
                _getUnclaimedRewardTokenAmountWrite(_vault, _liquidityPool)
            )
        );
        return _b;
    }

    /**
     * @notice Get the Curve Minter's address
     */
    function _getMinter(address _gauge) internal view returns (address) {
        return ICurveGauge(_gauge).minter();
    }

    /**
     * @dev This function composes the configuration required to construct fuction calls
     * @param _underlyingToken address of the underlying asset
     * @param _swapPool swap pool address
     * @param _amount amount in underlying token
     * @return _underlyingTokenIndex index of _underlyingToken
     * @return _nCoins number of underlying tokens in swap pool
     * @return _underlyingTokens underlying tokens in a swap pool
     * @return _amounts value in an underlying token for each underlying token
     * @return _codeLength number of function call required for deposit
     */
    function _getDepositCodeConfig(
        address _underlyingToken,
        address _swapPool,
        uint256 _amount
    )
        internal
        view
        returns (
            int128 _underlyingTokenIndex,
            uint256 _nCoins,
            address[8] memory _underlyingTokens,
            uint256[] memory _amounts,
            uint256 _codeLength,
            uint256 _minMintAmount
        )
    {
        address _curveRegistry = _getCurveRegistry();
        _nCoins = _getNCoins(_swapPool, _curveRegistry);
        _underlyingTokens = _getUnderlyingTokens(_swapPool, _curveRegistry);
        address _curveishCoin = _underlyingToken == WETH ? ETH : _underlyingToken;
        _underlyingTokenIndex = _getTokenIndex(_swapPool, _curveishCoin);
        _amounts = new uint256[](_nCoins);
        _codeLength = 1;
        for (uint256 _i = 0; _i < _nCoins; _i++) {
            if (_underlyingTokens[_i] == _curveishCoin) {
                _amounts[_i] = _getDepositAmount(_swapPool, _underlyingToken, _amount);
                if (_amounts[_i] > 0) {
                    if (_underlyingTokens[_i] == HBTC) {
                        _codeLength++;
                    } else {
                        _codeLength += 2;
                    }
                }
            }
        }
        if (_nCoins == uint256(2)) {
            _minMintAmount = ICurveSwap(_swapPool).calc_token_amount([_amounts[0], _amounts[1]], true).mul(95).div(100);
        } else if (_nCoins == uint256(3)) {
            _minMintAmount = ICurveSwap(_swapPool)
                .calc_token_amount([_amounts[0], _amounts[1], _amounts[2]], true)
                .mul(95)
                .div(100);
        } else if (_nCoins == uint256(4)) {
            _minMintAmount = ICurveSwap(_swapPool)
                .calc_token_amount([_amounts[0], _amounts[1], _amounts[2], _amounts[3]], true)
                .mul(95)
                .div(100);
        }
    }

    /**
     * @dev This functions returns the token index for a underlying token
     * @param _underlyingToken address of the underlying asset
     * @param _swapPool swap pool address
     * @return _tokenIndex index of coin in swap pool
     */
    function _getTokenIndex(address _swapPool, address _underlyingToken) internal view returns (int128) {
        address _inputToken = _underlyingToken == WETH ? ETH : _underlyingToken;
        address[8] memory _underlyingTokens = _getUnderlyingTokens(_swapPool, _getCurveRegistry());
        for (uint256 _i = 0; _i < _underlyingTokens.length; _i++) {
            if (_underlyingTokens[_i] == _inputToken) {
                return int128(_i);
            }
        }
        return int128(0);
    }

    /**
     * @dev Returns the amount of accrued reward tokens for a specific OptyFi's vault
     * @param _vault Address of the OptyFi's vault contract
     * @param _swapPool Address of the swap pool contract
     * @return Returns the amount of accrued reward tokens
     */
    function _getUnclaimedRewardTokenAmountWrite(address payable _vault, address _swapPool) internal returns (uint256) {
        address _liquidityGauge = _getLiquidityGauge(_swapPool, _getCurveRegistry());
        if (_liquidityGauge != address(0)) {
            return ICurveGauge(_liquidityGauge).claimable_tokens(_vault);
        }
        return uint256(0);
    }

    /**
     * @dev This functions composes the function calls to deposit asset into deposit pool
     * @param _underlyingToken address of the underlying asset
     * @param _swapPool swap pool address
     * @param _amount the amount in underlying token
     * @return _codes bytes array of function calls to be executed from vault
     */
    function _getDepositCode(
        address payable _vault,
        address _underlyingToken,
        address _swapPool,
        uint256 _amount
    ) internal view returns (bytes[] memory _codes) {
        (
            int128 _underlyingTokenIndex,
            uint256 _nCoins,
            address[8] memory _underlyingTokens,
            uint256[] memory _amounts,
            uint256 _codeLength,
            uint256 _minAmount
        ) = _getDepositCodeConfig(_underlyingToken, _swapPool, _amount);
        address _lendingPool = _underlyingToken == WETH ? curveSwapETHGatewayContract : _swapPool;
        if (_codeLength > 1) {
            _codes = new bytes[](_codeLength);
            uint256 _j = 0;
            for (uint256 i = 0; i < _nCoins; i++) {
                address _inputToken = _underlyingTokens[i] == ETH ? WETH : _underlyingTokens[i];
                if (_amounts[i] > 0) {
                    if (_inputToken == HBTC) {
                        _codes[_j++] = abi.encode(
                            _inputToken,
                            abi.encodeWithSignature("approve(address,uint256)", _lendingPool, _amounts[i])
                        );
                    } else {
                        _codes[_j++] = abi.encode(
                            _inputToken,
                            abi.encodeWithSignature("approve(address,uint256)", _lendingPool, uint256(0))
                        );
                        _codes[_j++] = abi.encode(
                            _inputToken,
                            abi.encodeWithSignature("approve(address,uint256)", _lendingPool, _amounts[i])
                        );
                    }
                }
            }
            if (_nCoins == uint256(2)) {
                uint256[2] memory _depositAmounts = [_amounts[0], _amounts[1]];
                address _liquidityPoolToken = getLiquidityPoolToken(address(0), _swapPool);
                _codes[_j] = _underlyingToken == WETH
                    ? abi.encode(
                        curveSwapETHGatewayContract,
                        abi.encodeWithSignature(
                            "depositETH(address,address,address,uint256[2],int128)",
                            _vault,
                            _swapPool,
                            _liquidityPoolToken,
                            _depositAmounts,
                            _underlyingTokenIndex
                        )
                    )
                    : abi.encode(
                        _lendingPool,
                        abi.encodeWithSignature("add_liquidity(uint256[2],uint256)", _depositAmounts, _minAmount)
                    );
            } else if (_nCoins == uint256(3)) {
                uint256[3] memory _depositAmounts = [_amounts[0], _amounts[1], _amounts[2]];
                _codes[_j] = abi.encode(
                    _lendingPool,
                    abi.encodeWithSignature("add_liquidity(uint256[3],uint256)", _depositAmounts, _minAmount)
                );
            } else if (_nCoins == uint256(4)) {
                uint256[4] memory _depositAmounts = [_amounts[0], _amounts[1], _amounts[2], _amounts[3]];
                _codes[_j] = abi.encode(
                    _lendingPool,
                    abi.encodeWithSignature("add_liquidity(uint256[4],uint256)", _depositAmounts, _minAmount)
                );
            }
        }
    }

    /**
     * @dev Get the underlying tokens within a swap pool.
     *      Note: For pools using lending, these are the
     *            wrapped coin addresses
     * @param _swapPool the swap pool address
     * @param _curveRegistry the address of the Curve registry
     * @return list of coin addresses
     */
    function _getUnderlyingTokens(address _swapPool, address _curveRegistry) internal view returns (address[8] memory) {
        return ICurveRegistry(_curveRegistry).get_coins(_swapPool);
    }

    /**
     * @dev Get a liquidity gauge address associated with a swap pool
     * @param _swapPool the swap pool address
     * @param _curveRegistry the Curve registry's address
     * @return gauge address
     */
    function _getLiquidityGauge(address _swapPool, address _curveRegistry) internal view returns (address) {
        (address[10] memory _liquidityGauges, ) = ICurveRegistry(_curveRegistry).get_gauges(_swapPool);
        return _liquidityGauges[0];
    }

    /**
     * @dev Get the address of the main registry contract
     * @return Address of the main registry contract
     */
    function _getCurveRegistry() internal view returns (address) {
        return ICurveAddressProvider(ADDRESS_PROVIDER).get_registry();
    }

    /**
     * @dev Get number of underlying tokens in a liquidity pool
     * @param _swapPool swap pool address associated with liquidity pool
     * @param _curveRegistry address of the main registry contract
     * @return  Number of underlying tokens
     */
    function _getNCoins(address _swapPool, address _curveRegistry) internal view returns (uint256) {
        return ICurveRegistry(_curveRegistry).get_n_coins(_swapPool)[0];
    }

    /**
     * @dev Get the final value of amount in underlying token to be deposited
     * @param _swapPool swap pool address
     * @param _underlyingToken underlying token address
     * @param _amount amount in underlying token
     * @return amount in underlying token to be deposited affected by investment limitation
     */
    function _getDepositAmount(
        address _swapPool,
        address _underlyingToken,
        uint256 _amount
    ) internal view returns (uint256) {
        return
            maxDepositProtocolMode == MaxExposure.Pct
                ? _getMaxDepositAmountPct(_swapPool, _underlyingToken, _amount)
                : _getMaxDepositAmount(_swapPool, _underlyingToken, _amount);
    }

    /**
     * @dev Gets the maximum amount in underlying token limited by percentage
     * @param _swapPool swap pool address
     * @param _underlyingToken underlying token address
     * @param _amount amount in underlying token
     * @return  amount in underlying token to be deposited affected by
     *          investment limit in percentage
     */
    function _getMaxDepositAmountPct(
        address _swapPool,
        address _underlyingToken,
        uint256 _amount
    ) internal view returns (uint256) {
        uint256 _poolValue = getPoolValue(_swapPool, address(0));
        uint256 _poolPct = maxDepositPoolPct[_swapPool];
        uint256 _decimals = ERC20(_underlyingToken).decimals();
        uint256 _actualAmount = _amount.mul(10**(uint256(18).sub(_decimals)));
        uint256 _limit =
            _poolPct == 0 ? _poolValue.mul(maxDepositProtocolPct).div(10000) : _poolValue.mul(_poolPct).div(10000);
        return _actualAmount > _limit ? _limit.div(10**(uint256(18).sub(_decimals))) : _amount;
    }

    /**
     * @dev Gets the maximum amount in underlying token affected by investment
     *      limit set for swap pool in amount
     * @param _swapPool swap pool address
     * @param _underlyingToken underlying token address
     * @param _amount amount in underlying token
     * @return amount in underlying token to be deposited affected by
     *         investment limit set for swap pool in amount
     */
    function _getMaxDepositAmount(
        address _swapPool,
        address _underlyingToken,
        uint256 _amount
    ) internal view returns (uint256) {
        uint256 _decimals = ERC20(_underlyingToken).decimals();
        uint256 _maxAmount = maxDepositAmount[_swapPool].div(10**(uint256(18).sub(_decimals)));
        return _amount > _maxAmount ? _maxAmount : _amount;
    }
}