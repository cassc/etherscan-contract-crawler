// SPDX-License-Identifier:MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

// libraries
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

// helper contracts
import { Modifiers } from "../../earn-protocol-configuration/contracts/Modifiers.sol";

// interfaces
import { ISushiswapMasterChef } from "@optyfi/defi-legos/ethereum/sushiswap/contracts/ISushiswapMasterChef.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IHarvestCodeProvider } from "../interfaces/IHarvestCodeProvider.sol";
import { IAdapter } from "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapter.sol";
import { IAdapterHarvestReward } from "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapterHarvestReward.sol";
import "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapterInvestLimit.sol";

/**
 * @title Adapter for Sushiswap protocol
 * @author Opty.fi
 * @dev Abstraction layer to Sushiswap's MasterChef contract
 */

contract SushiswapMasterChefV1Adapter is IAdapter, IAdapterInvestLimit, IAdapterHarvestReward, Modifiers {
    using SafeMath for uint256;
    using Address for address;

    /** @notice max deposit value datatypes */
    MaxExposure public maxDepositProtocolMode;

    /** @notice Sushiswap router contract address */
    address public constant SUSHISWAP_ROUTER = address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    /** @notice max deposit's protocol value in percentage */
    uint256 public maxDepositProtocolPct; // basis points

    /** @notice Maps liquidityPool to max deposit value in percentage */
    mapping(address => uint256) public maxDepositPoolPct; // basis points

    /** @notice Maps liquidityPool to max deposit value in absolute value for a specific token */
    mapping(address => mapping(address => uint256)) public maxDepositAmount;

    /** @notice Maps underlyingToken to the ID of its pool */
    mapping(address => uint256) public underlyingTokenToPid;

    /** @notice List of Sushiswap pairs */
    address public constant USDC_WETH = address(0x397FF1542f962076d0BFE58eA045FfA2d347ACa0);
    address public constant DAI_WETH = address(0xC3D03e4F041Fd4cD388c549Ee2A29a9E5075882f);
    address public constant COMP_WETH = address(0x31503dcb60119A812feE820bb7042752019F2355);
    address public constant SNX_WETH = address(0xA1d7b2d891e3A1f9ef4bBC5be20630C2FEB1c470);
    address public constant LINK_WETH = address(0xC40D16476380e4037e6b1A2594cAF6a6cc8Da967);
    address public constant SUSHI_WETH = address(0x795065dCc9f64b5614C407a6EFDC400DA6221FB0);
    address public constant UNI_WETH = address(0xDafd66636E2561b0284EDdE37e42d192F2844D40);
    address public constant XSUSHI_WETH = address(0x36e2FCCCc59e5747Ff63a03ea2e5C0c2C14911e7);
    address public constant WBTC_WETH = address(0xCEfF51756c56CeFFCA006cD410B03FFC46dd3a58);
    address public constant AAVE_WETH = address(0xD75EA151a61d06868E31F8988D28DFE5E9df57B4);
    address public constant LDO_WETH = address(0xC558F600B34A5f69dD2f0D06Cb8A88d829B7420a);
    address public constant MANA_WETH = address(0x1bEC4db6c3Bc499F3DbF289F5499C30d541FEc97);
    address public constant ILV_WETH = address(0x6a091a3406E0073C3CD6340122143009aDac0EDa);

    constructor(address _registry) public Modifiers(_registry) {
        maxDepositProtocolPct = uint256(10000); // 100% (basis points)
        maxDepositProtocolMode = MaxExposure.Pct;
        underlyingTokenToPid[USDC_WETH] = uint256(1);
        underlyingTokenToPid[DAI_WETH] = uint256(2);
        underlyingTokenToPid[COMP_WETH] = uint256(4);
        underlyingTokenToPid[SNX_WETH] = uint256(6);
        underlyingTokenToPid[LINK_WETH] = uint256(8);
        underlyingTokenToPid[SUSHI_WETH] = uint256(12);
        underlyingTokenToPid[UNI_WETH] = uint256(18);
        underlyingTokenToPid[XSUSHI_WETH] = uint256(19);
        underlyingTokenToPid[WBTC_WETH] = uint256(21);
        underlyingTokenToPid[AAVE_WETH] = uint256(37);
        underlyingTokenToPid[LDO_WETH] = uint256(109);
        underlyingTokenToPid[MANA_WETH] = uint256(240);
        underlyingTokenToPid[ILV_WETH] = uint256(244);
    }

    /**
     * @inheritdoc IAdapterInvestLimit
     */
    function setMaxDepositPoolPct(address _underlyingToken, uint256 _maxDepositPoolPct)
        external
        override
        onlyRiskOperator
    {
        maxDepositPoolPct[_underlyingToken] = _maxDepositPoolPct;
        emit LogMaxDepositPoolPct(maxDepositPoolPct[_underlyingToken], msg.sender);
    }

    /**
     * @inheritdoc IAdapterInvestLimit
     */
    function setMaxDepositAmount(
        address _masterChef,
        address _underlyingToken,
        uint256 _maxDepositAmount
    ) external override onlyRiskOperator {
        maxDepositAmount[_masterChef][_underlyingToken] = _maxDepositAmount;
        emit LogMaxDepositAmount(maxDepositAmount[_masterChef][_underlyingToken], msg.sender);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getDepositAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _masterChef
    ) external view override returns (bytes[] memory) {
        return getDepositSomeCodes(_vault, _underlyingToken, _masterChef, IERC20(_underlyingToken).balanceOf(_vault));
    }

    /**
     * @inheritdoc IAdapter
     */
    function getWithdrawAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _masterChef
    ) external view override returns (bytes[] memory) {
        return
            getWithdrawSomeCodes(
                _vault,
                _underlyingToken,
                _masterChef,
                getLiquidityPoolTokenBalance(_vault, _underlyingToken, _masterChef)
            );
    }

    /**
     * @inheritdoc IAdapter
     */
    function getUnderlyingTokens(address, address) external view override returns (address[] memory) {
        revert("!empty");
    }

    /**
     * @inheritdoc IAdapter
     */
    function getSomeAmountInToken(
        address,
        address,
        uint256 _amount
    ) external view override returns (uint256) {
        return _amount;
    }

    /**
     * @inheritdoc IAdapter
     */
    function calculateAmountInLPToken(
        address,
        address,
        uint256 _amount
    ) external view override returns (uint256) {
        return _amount;
    }

    /**
     * @inheritdoc IAdapter
     */
    function calculateRedeemableLPTokenAmount(
        address payable _vault,
        address _underlyingToken,
        address _masterChef,
        uint256
    ) external view override returns (uint256) {
        return ISushiswapMasterChef(_masterChef).userInfo(underlyingTokenToPid[_underlyingToken], _vault).amount;
    }

    /**
     * @inheritdoc IAdapter
     */
    function isRedeemableAmountSufficient(
        address payable _vault,
        address _underlyingToken,
        address _masterChef,
        uint256 _redeemAmount
    ) external view override returns (bool) {
        return getAllAmountInToken(_vault, _underlyingToken, _masterChef) >= _redeemAmount;
    }

    /* solhint-disable no-empty-blocks */

    /**
     * @inheritdoc IAdapterHarvestReward
     */
    function getClaimRewardTokenCode(address payable, address) external view override returns (bytes[] memory) {}

    /* solhint-enable no-empty-blocks */

    /**
     * @inheritdoc IAdapterHarvestReward
     */
    function getHarvestAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _masterChef
    ) external view override returns (bytes[] memory) {
        return
            getHarvestSomeCodes(
                _vault,
                _underlyingToken,
                _masterChef,
                IERC20(getRewardToken(_masterChef)).balanceOf(_vault)
            );
    }

    /**
     * @inheritdoc IAdapter
     */
    function canStake(address) external view override returns (bool) {
        return false;
    }

    /**
     * @notice Map underlyingToken to its pool ID
     * @param _underlyingTokens pair contract addresses to be mapped with pool ID
     * @param _pids pool IDs to be linked with pair address
     */
    function setUnderlyingTokenToPid(address[] memory _underlyingTokens, uint256[] memory _pids) public onlyOperator {
        uint256 _underlyingTokensLen = _underlyingTokens.length;
        uint256 _pidsLen = _pids.length;
        require(_underlyingTokensLen == _pidsLen, "inequal length of underlyingtokens and pids");
        for (uint256 _i; _i < _underlyingTokensLen; _i++) {
            underlyingTokenToPid[_underlyingTokens[_i]] = _pids[_i];
        }
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

    /* solhint-disable no-unused-vars */

    /**
     * @inheritdoc IAdapter
     */
    function getDepositSomeCodes(
        address payable,
        address _underlyingToken,
        address _masterChef,
        uint256 _amount
    ) public view override returns (bytes[] memory _codes) {
        if (_amount > 0) {
            uint256 _depositAmount = _getDepositAmount(_masterChef, _underlyingToken, _amount);
            _codes = new bytes[](3);
            _codes[0] = abi.encode(
                _underlyingToken,
                abi.encodeWithSignature("approve(address,uint256)", _masterChef, uint256(0))
            );
            _codes[1] = abi.encode(
                _underlyingToken,
                abi.encodeWithSignature("approve(address,uint256)", _masterChef, _depositAmount)
            );
            _codes[2] = abi.encode(
                _masterChef,
                abi.encodeWithSignature(
                    "deposit(uint256,uint256)",
                    underlyingTokenToPid[_underlyingToken],
                    _depositAmount
                )
            );
        }
    }

    /**
     * @inheritdoc IAdapter
     */
    function getWithdrawSomeCodes(
        address payable,
        address _underlyingToken,
        address _masterChef,
        uint256 _redeemAmount
    ) public view override returns (bytes[] memory _codes) {
        if (_redeemAmount > 0) {
            _codes = new bytes[](1);
            _codes[0] = abi.encode(
                _masterChef,
                abi.encodeWithSignature(
                    "withdraw(uint256,uint256)",
                    underlyingTokenToPid[_underlyingToken],
                    _redeemAmount
                )
            );
        }
    }

    /**
     * @inheritdoc IAdapter
     */
    function getPoolValue(address _masterChef, address _underlyingToken) public view override returns (uint256) {
        return IERC20(_underlyingToken).balanceOf(_masterChef);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getLiquidityPoolToken(address _underlyingToken, address) public view override returns (address) {
        return _underlyingToken;
    }

    /**
     * @inheritdoc IAdapter
     */
    function getAllAmountInToken(
        address payable _vault,
        address _underlyingToken,
        address _masterChef
    ) public view override returns (uint256) {
        return ISushiswapMasterChef(_masterChef).userInfo(underlyingTokenToPid[_underlyingToken], _vault).amount;
    }

    /**
     * @inheritdoc IAdapter
     */
    function getLiquidityPoolTokenBalance(
        address payable _vault,
        address _underlyingToken,
        address _masterChef
    ) public view override returns (uint256) {
        return ISushiswapMasterChef(_masterChef).userInfo(underlyingTokenToPid[_underlyingToken], _vault).amount;
    }

    /**
     * @inheritdoc IAdapter
     */
    function getRewardToken(address _masterChef) public view override returns (address) {
        return ISushiswapMasterChef(_masterChef).sushi();
    }

    /**
     * @inheritdoc IAdapterHarvestReward
     */
    function getUnclaimedRewardTokenAmount(
        address payable _vault,
        address _masterChef,
        address _underlyingToken
    ) public view override returns (uint256) {
        return ISushiswapMasterChef(_masterChef).pendingSushi(underlyingTokenToPid[_underlyingToken], _vault);
    }

    /**
     * @inheritdoc IAdapterHarvestReward
     */
    function getHarvestSomeCodes(
        address payable _vault,
        address _underlyingToken,
        address _masterChef,
        uint256 _rewardTokenAmount
    ) public view override returns (bytes[] memory) {
        return
            IHarvestCodeProvider(registryContract.getHarvestCodeProvider()).getHarvestCodes(
                _vault,
                getRewardToken(_masterChef),
                _underlyingToken,
                _rewardTokenAmount
            );
    }

    /**
     * @inheritdoc IAdapterHarvestReward
     */
    function getAddLiquidityCodes(address payable _vault, address _underlyingToken)
        public
        view
        override
        returns (bytes[] memory)
    {
        return
            IHarvestCodeProvider(registryContract.getHarvestCodeProvider()).getAddLiquidityCodes(
                SUSHISWAP_ROUTER,
                _vault,
                _underlyingToken
            );
    }

    function _getDepositAmount(
        address _masterChef,
        address _underlyingToken,
        uint256 _amount
    ) internal view returns (uint256) {
        uint256 _limit =
            maxDepositProtocolMode == MaxExposure.Pct
                ? _getMaxDepositAmountByPct(_masterChef, _underlyingToken)
                : maxDepositAmount[_masterChef][_underlyingToken];
        return _amount > _limit ? _limit : _amount;
    }

    function _getMaxDepositAmountByPct(address _masterChef, address _underlyingToken) internal view returns (uint256) {
        uint256 _poolValue = getPoolValue(_masterChef, _underlyingToken);
        uint256 _poolPct = maxDepositPoolPct[_underlyingToken];
        uint256 _limit =
            _poolPct == 0
                ? _poolValue.mul(maxDepositProtocolPct).div(uint256(10000))
                : _poolValue.mul(_poolPct).div(uint256(10000));
        return _limit;
    }
}