// solhint-disable no-unused-vars
// SPDX-License-Identifier:MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

//  libraries
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

//  helper contracts
import { Modifiers } from "../../earn-protocol-configuration/contracts/Modifiers.sol";

//  interfaces
import { IHarvestDeposit } from "@optyfi/defi-legos/ethereum/harvest.finance/contracts/IHarvestDeposit.sol";
import { IHarvestFarm } from "@optyfi/defi-legos/ethereum/harvest.finance/contracts/IHarvestFarm.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IHarvestCodeProvider } from "../interfaces/IHarvestCodeProvider.sol";
import { IAdapter } from "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapter.sol";
import { IAdapterHarvestReward } from "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapterHarvestReward.sol";
import "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapterInvestLimit.sol";
import { IAdapterStaking } from "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapterStaking.sol";

/**
 * @title Adapter for Harvest.finance protocol
 * @author Opty.fi
 * @dev Abstraction layer to harvest finance's pools
 */

contract HarvestV1Adapter is IAdapter, IAdapterHarvestReward, IAdapterStaking, IAdapterInvestLimit, Modifiers {
    using SafeMath for uint256;
    using Address for address;

    /** @notice max deposit value datatypes */
    MaxExposure public maxDepositProtocolMode;

    // deposit pools
    address public constant TBTC_SBTC_CRV_DEPOSIT = address(0x640704D106E79e105FDA424f05467F005418F1B5);
    address public constant THREE_CRV_DEPOSIT = address(0x71B9eC42bB3CB40F017D8AD8011BE8e384a95fa5);
    address public constant Y_CRV_DEPOSIT = address(0x0FE4283e0216F94f5f9750a7a11AC54D3c9C38F3);
    address public constant DAI_DEPOSIT = address(0xab7FA2B2985BCcfC13c6D86b1D5A17486ab1e04C);
    address public constant USDC_DEPOSIT = address(0xf0358e8c3CD5Fa238a29301d0bEa3D63A17bEdBE);
    address public constant USDT_DEPOSIT = address(0x053c80eA73Dc6941F518a68E2FC52Ac45BDE7c9C);
    address public constant TUSD_DEPOSIT = address(0x7674622c63Bee7F46E86a4A5A18976693D54441b);
    address public constant REN_WBTC_CRV_DEPOSIT = address(0x9aA8F427A17d6B0d91B6262989EdC7D45d6aEdf8);
    address public constant WBTC_DEPOSIT = address(0x5d9d25c7C457dD82fc8668FFC6B9746b674d4EcB);
    address public constant RENBTC_DEPOSIT = address(0xC391d1b08c1403313B0c28D47202DFDA015633C4);
    address public constant WETH_DEPOSIT = address(0xFE09e53A81Fe2808bc493ea64319109B5bAa573e);
    address public constant COMPOUND_CRV_DEPOSIT = address(0x998cEb152A42a3EaC1f555B1E911642BeBf00faD);
    address public constant USDN_3CRV_DEPOSIT = address(0x683E683fBE6Cf9b635539712c999f3B3EdCB8664);
    address public constant BUSD_CRV_DEPOSIT = address(0x4b1cBD6F6D8676AcE5E412C78B7a59b4A1bbb68a);
    address public constant HCRV_DEPOSIT = address(0xCC775989e76ab386E9253df5B0c0b473E22102E2);
    address public constant OBTC_SBTC_CRV_DEPOSIT = address(0x966A70A4d3719A6De6a94236532A0167d5246c72);
    address public constant STE_CRV_DEPOSIT = address(0xc27bfE32E0a934a12681C1b35acf0DBA0e7460Ba);
    address public constant UNI_ETH_DPI_DEPOSIT = address(0x2a32dcBB121D48C106F6d94cf2B4714c0b4Dfe48);
    address public constant SUSHI_ETH_SUSHI_DEPOSIT = address(0x5aDe382F38A09A1F8759D06fFE2067992ab5c78e);
    address public constant SUSHI_ETH_DAI_DEPOSIT = address(0x203E97aa6eB65A1A02d9E80083414058303f241E);
    address public constant SUSHI_ETH_USDC_DEPOSIT = address(0x01bd09A1124960d9bE04b638b142Df9DF942b04a);
    address public constant SUSHI_ETH_USDT_DEPOSIT = address(0x64035b583c8c694627A199243E863Bb33be60745);
    address public constant SUSHI_ETH_WBTC_DEPOSIT = address(0x5C0A3F55AAC52AA320Ff5F280E77517cbAF85524);
    address public constant HUSD_3CRV_DEPOSIT = address(0x29780C39164Ebbd62e9DDDE50c151810070140f2);
    address public constant EURS_CRV_DEPOSIT = address(0x6eb941BD065b8a5bd699C5405A928c1f561e2e5a);
    address public constant GUSD_3CRV_DEPOSIT = address(0xB8671E33fcFC7FEA2F7a3Ea4a117F065ec4b009E);
    address public constant UST_3CRV_DEPOSIT = address(0x84A1DfAdd698886A614fD70407936816183C0A02);
    address public constant UNI_UST_MAAPLE_DEPOSIT = address(0x11804D69AcaC6Ae9466798325fA7DE023f63Ab53);
    address public constant UNI_UST_MAMZN_DEPOSIT = address(0x8334A61012A779169725FcC43ADcff1F581350B7);
    address public constant UNI_UST_MGOOGL_DEPOSIT = address(0x07DBe6aA35EF70DaD124f4e2b748fFA6C9E1963a);
    address public constant UNI_UST_MTSLA_DEPOSIT = address(0xC800982d906671637E23E031e907d2e3487291Bc);

    // staking vaults
    address public constant TBTC_SBTC_CRV_STAKE = address(0x017eC1772A45d2cf68c429A820eF374f0662C57c);
    address public constant THREE_CRV_STAKE = address(0x27F12d1a08454402175b9F0b53769783578Be7d9);
    address public constant Y_CRV_STAKE = address(0x6D1b6Ea108AA03c6993d8010690264BA96D349A8);
    address public constant DAI_STAKE = address(0x15d3A64B2d5ab9E152F16593Cdebc4bB165B5B4A);
    address public constant USDC_STAKE = address(0x4F7c28cCb0F1Dbd1388209C67eEc234273C878Bd);
    address public constant USDT_STAKE = address(0x6ac4a7AB91E6fD098E13B7d347c6d4d1494994a2);
    address public constant TUSD_STAKE = address(0xeC56a21CF0D7FeB93C25587C12bFfe094aa0eCdA);
    address public constant REN_WBTC_CRV_STAKE = address(0xA3Cf8D1CEe996253FAD1F8e3d68BDCba7B3A3Db5);
    address public constant WBTC_STAKE = address(0x917d6480Ec60cBddd6CbD0C8EA317Bcc709EA77B);
    address public constant RENBTC_STAKE = address(0x7b8Ff8884590f44e10Ea8105730fe637Ce0cb4F6);
    address public constant WETH_STAKE = address(0x3DA9D911301f8144bdF5c3c67886e5373DCdff8e);
    address public constant COMPOUND_CRV_STAKE = address(0xC0f51a979e762202e9BeF0f62b07F600d0697DE1);
    address public constant USDN_3CRV_STAKE = address(0xef4Da1CE3f487DA2Ed0BE23173F76274E0D47579);
    address public constant BUSD_CRV_STAKE = address(0x093C2ae5E6F3D2A897459aa24551289D462449AD);
    address public constant HCRV_STAKE = address(0x01f9CAaD0f9255b0C0Aa2fBD1c1aA06ad8Af7254);
    address public constant OBTC_SBTC_CRV_STAKE = address(0x91B5cD52fDE8dbAC37C95ECafEF0a70bA4c182fC);
    address public constant STE_CRV_STAKE = address(0x2E25800957742C52b4d69b65F9C67aBc5ccbffe6);
    address public constant UNI_ETH_DPI_STAKE = address(0xAd91695b4BeC2798829ac7a4797E226C78f22Abd);
    address public constant SUSHI_ETH_SUSHI_STAKE = address(0x16fBb193f99827C92A4CC22EFe8eD7390465BFa3);
    address public constant SUSHI_ETH_DAI_STAKE = address(0x76Aef359a33C02338902aCA543f37de4b01BA1FA);
    address public constant SUSHI_ETH_USDC_STAKE = address(0x6B4e1E0656Dd38F36c318b077134487B9b0cf7a6);
    address public constant SUSHI_ETH_USDT_STAKE = address(0xA56522BCA0A09f57B85C52c0Cc8Ba1B5eDbc64ef);
    address public constant SUSHI_ETH_WBTC_STAKE = address(0xE2D9FAe95f1e68afca7907dFb36143781f917194);
    address public constant HUSD_3CRV_STAKE = address(0x72C50e6FD8cC5506E166c273b6E814342Aa0a3c1);
    address public constant EURS_CRV_STAKE = address(0xf4d50f60D53a230abc8268c6697972CB255Cd940);
    address public constant GUSD_3CRV_STAKE = address(0x538613A19Eb84D86a4CcfcB63548244A52Ab0B68);
    address public constant UST_3CRV_STAKE = address(0xDdb5D3CCd968Df64Ce48b577776BdC29ebD3120e);
    address public constant UNI_UST_MAAPLE_STAKE = address(0xc02d1Da469d68Adc651Dd135d1A7f6b42F4d1A57);
    address public constant UNI_UST_MAMZN_STAKE = address(0x8Dc427Cbcc75cAe58dD4f386979Eba6662f5C158);
    address public constant UNI_UST_MGOOGL_STAKE = address(0xfE83a00DF3A98dE218c08719FAF7e3741b220D0D);
    address public constant UNI_UST_MTSLA_STAKE = address(0x40C34B0E1bb6984810E17474c6B0Bcc6A6B46614);

    /** @notice max deposit's default value in percentage */
    uint256 public maxDepositProtocolPct; // basis points

    /** @notice Maps liquidityPool to staking vault */
    mapping(address => address) public liquidityPoolToStakingVault;

    /** @notice  Maps liquidityPool to max deposit value in percentage */
    mapping(address => uint256) public maxDepositPoolPct; // basis points

    /** @notice  Maps liquidityPool to max deposit value in absolute value for a specific token */
    mapping(address => mapping(address => uint256)) public maxDepositAmount;

    constructor(address _registry) public Modifiers(_registry) {
        liquidityPoolToStakingVault[TBTC_SBTC_CRV_DEPOSIT] = TBTC_SBTC_CRV_STAKE;
        liquidityPoolToStakingVault[THREE_CRV_DEPOSIT] = THREE_CRV_STAKE;
        liquidityPoolToStakingVault[Y_CRV_DEPOSIT] = Y_CRV_STAKE;
        liquidityPoolToStakingVault[DAI_DEPOSIT] = DAI_STAKE;
        liquidityPoolToStakingVault[USDC_DEPOSIT] = USDC_STAKE;
        liquidityPoolToStakingVault[USDT_DEPOSIT] = USDT_STAKE;
        liquidityPoolToStakingVault[TUSD_DEPOSIT] = TUSD_STAKE;
        liquidityPoolToStakingVault[REN_WBTC_CRV_DEPOSIT] = REN_WBTC_CRV_STAKE;
        liquidityPoolToStakingVault[WBTC_DEPOSIT] = WBTC_STAKE;
        liquidityPoolToStakingVault[RENBTC_DEPOSIT] = RENBTC_STAKE;
        liquidityPoolToStakingVault[WETH_DEPOSIT] = WETH_STAKE;
        liquidityPoolToStakingVault[COMPOUND_CRV_DEPOSIT] = COMPOUND_CRV_STAKE;
        liquidityPoolToStakingVault[USDN_3CRV_DEPOSIT] = USDN_3CRV_STAKE;
        liquidityPoolToStakingVault[BUSD_CRV_DEPOSIT] = BUSD_CRV_STAKE;
        liquidityPoolToStakingVault[HCRV_DEPOSIT] = HCRV_STAKE;
        liquidityPoolToStakingVault[OBTC_SBTC_CRV_DEPOSIT] = OBTC_SBTC_CRV_STAKE;
        liquidityPoolToStakingVault[STE_CRV_DEPOSIT] = STE_CRV_STAKE;
        liquidityPoolToStakingVault[UNI_ETH_DPI_DEPOSIT] = UNI_ETH_DPI_STAKE;
        liquidityPoolToStakingVault[SUSHI_ETH_SUSHI_DEPOSIT] = SUSHI_ETH_SUSHI_STAKE;
        liquidityPoolToStakingVault[SUSHI_ETH_DAI_DEPOSIT] = SUSHI_ETH_DAI_STAKE;
        liquidityPoolToStakingVault[SUSHI_ETH_USDC_DEPOSIT] = SUSHI_ETH_USDC_STAKE;
        liquidityPoolToStakingVault[SUSHI_ETH_USDT_DEPOSIT] = SUSHI_ETH_USDT_STAKE;
        liquidityPoolToStakingVault[SUSHI_ETH_WBTC_DEPOSIT] = SUSHI_ETH_WBTC_STAKE;
        liquidityPoolToStakingVault[HUSD_3CRV_DEPOSIT] = HUSD_3CRV_STAKE;
        liquidityPoolToStakingVault[EURS_CRV_DEPOSIT] = EURS_CRV_STAKE;
        liquidityPoolToStakingVault[GUSD_3CRV_DEPOSIT] = GUSD_3CRV_STAKE;
        liquidityPoolToStakingVault[UST_3CRV_DEPOSIT] = UST_3CRV_STAKE;
        liquidityPoolToStakingVault[UNI_UST_MAAPLE_DEPOSIT] = UNI_UST_MAAPLE_STAKE;
        liquidityPoolToStakingVault[UNI_UST_MAMZN_DEPOSIT] = UNI_UST_MAMZN_STAKE;
        liquidityPoolToStakingVault[UNI_UST_MGOOGL_DEPOSIT] = UNI_UST_MGOOGL_STAKE;
        liquidityPoolToStakingVault[UNI_UST_MTSLA_DEPOSIT] = UNI_UST_MTSLA_STAKE;

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
        address _underlyingToken,
        uint256 _maxDepositAmount
    ) external override onlyRiskOperator {
        maxDepositAmount[_liquidityPool][_underlyingToken] = _maxDepositAmount;
        emit LogMaxDepositAmount(maxDepositAmount[_liquidityPool][_underlyingToken], msg.sender);
    }

    /**
     * @notice Map the liquidity pool to its Staking vault address
     * @param _liquidityPool liquidity pool address to be mapped with staking vault
     * @param _stakingVault staking vault address to be linked with liquidity pool
     */
    function setLiquidityPoolToStakingVault(address _liquidityPool, address _stakingVault) public onlyOperator {
        liquidityPoolToStakingVault[_liquidityPool] = _stakingVault;
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
     * @inheritdoc IAdapter
     */
    function getDepositAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool
    ) public view override returns (bytes[] memory) {
        uint256 _amount = IERC20(_underlyingToken).balanceOf(_vault);
        return getDepositSomeCodes(_vault, _underlyingToken, _liquidityPool, _amount);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getWithdrawAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool
    ) public view override returns (bytes[] memory) {
        uint256 _redeemAmount = getLiquidityPoolTokenBalance(_vault, _underlyingToken, _liquidityPool);
        return getWithdrawSomeCodes(_vault, _underlyingToken, _liquidityPool, _redeemAmount);
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
        _underlyingTokens = new address[](1);
        _underlyingTokens[0] = IHarvestDeposit(_liquidityPool).underlying();
    }

    /**
     * @inheritdoc IAdapter
     */
    function calculateAmountInLPToken(
        address,
        address _liquidityPool,
        uint256 _depositAmount
    ) public view override returns (uint256) {
        return
            _depositAmount.mul(10**IHarvestDeposit(_liquidityPool).decimals()).div(
                IHarvestDeposit(_liquidityPool).getPricePerFullShare()
            );
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
        uint256 _liquidityPoolTokenBalance = getLiquidityPoolTokenBalance(_vault, _underlyingToken, _liquidityPool);
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
        address _stakingVault = liquidityPoolToStakingVault[_liquidityPool];
        _codes = new bytes[](1);
        _codes[0] = abi.encode(_stakingVault, abi.encodeWithSignature("getReward()"));
    }

    /**
     * @inheritdoc IAdapterHarvestReward
     */
    function getHarvestAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool
    ) public view override returns (bytes[] memory) {
        uint256 _rewardTokenAmount = IERC20(getRewardToken(_liquidityPool)).balanceOf(_vault);
        return getHarvestSomeCodes(_vault, _underlyingToken, _liquidityPool, _rewardTokenAmount);
    }

    /**
     * @inheritdoc IAdapter
     */
    function canStake(address) public view override returns (bool) {
        return true;
    }

    /**
     * @inheritdoc IAdapterStaking
     */
    function getStakeAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool
    ) public view override returns (bytes[] memory) {
        uint256 _depositAmount = getLiquidityPoolTokenBalance(_vault, _underlyingToken, _liquidityPool);
        return getStakeSomeCodes(_liquidityPool, _depositAmount);
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
        uint256 _redeemAmount = getLiquidityPoolTokenBalanceStake(_vault, _liquidityPool);
        return getUnstakeSomeCodes(_liquidityPool, _redeemAmount);
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
        address _stakingVault = liquidityPoolToStakingVault[_liquidityPool];
        uint256 _liquidityPoolTokenBalance = IHarvestFarm(_stakingVault).balanceOf(_vault);
        uint256 _balanceInToken = getAllAmountInTokenStake(_vault, _underlyingToken, _liquidityPool);
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
        uint256 _balanceInTokenStake = getAllAmountInTokenStake(_vault, _underlyingToken, _liquidityPool);
        return _balanceInTokenStake >= _redeemAmount;
    }

    /**
     * @inheritdoc IAdapterStaking
     */
    function getUnstakeAndWithdrawAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool
    ) public view override returns (bytes[] memory) {
        uint256 _unstakeAmount = getLiquidityPoolTokenBalanceStake(_vault, _liquidityPool);
        return getUnstakeAndWithdrawSomeCodes(_vault, _underlyingToken, _liquidityPool, _unstakeAmount);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getDepositSomeCodes(
        address payable,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _amount
    ) public view override returns (bytes[] memory _codes) {
        uint256 _depositAmount = _getDepositAmount(_liquidityPool, _underlyingToken, _amount);
        if (_depositAmount > 0) {
            _codes = new bytes[](3);
            _codes[0] = abi.encode(
                _underlyingToken,
                abi.encodeWithSignature("approve(address,uint256)", _liquidityPool, uint256(0))
            );
            _codes[1] = abi.encode(
                _underlyingToken,
                abi.encodeWithSignature("approve(address,uint256)", _liquidityPool, _depositAmount)
            );
            _codes[2] = abi.encode(_liquidityPool, abi.encodeWithSignature("deposit(uint256)", _depositAmount));
        }
    }

    /**
     * @inheritdoc IAdapter
     */
    function getWithdrawSomeCodes(
        address payable,
        address _underlyingToken,
        address _liquidityPool,
        uint256 _shares
    ) public view override returns (bytes[] memory _codes) {
        if (_shares > 0) {
            _codes = new bytes[](1);
            _codes[0] = abi.encode(
                getLiquidityPoolToken(_underlyingToken, _liquidityPool),
                abi.encodeWithSignature("withdraw(uint256)", _shares)
            );
        }
    }

    /**
     * @inheritdoc IAdapter
     */
    function getPoolValue(address _liquidityPool, address) public view override returns (uint256) {
        return IHarvestDeposit(_liquidityPool).underlyingBalanceWithInvestment();
    }

    /**
     * @inheritdoc IAdapter
     */
    function getLiquidityPoolToken(address, address _liquidityPool) public view override returns (address) {
        return _liquidityPool;
    }

    /**
     * @inheritdoc IAdapter
     */
    function getAllAmountInToken(
        address payable _vault,
        address _underlyingToken,
        address _liquidityPool
    ) public view override returns (uint256) {
        uint256 b =
            getSomeAmountInToken(
                _underlyingToken,
                _liquidityPool,
                getLiquidityPoolTokenBalance(_vault, _underlyingToken, _liquidityPool)
            );
        uint256 _unclaimedReward = getUnclaimedRewardTokenAmount(_vault, _liquidityPool, _underlyingToken);
        if (_unclaimedReward > 0) {
            b = b.add(
                IHarvestCodeProvider(registryContract.getHarvestCodeProvider()).rewardBalanceInUnderlyingTokens(
                    getRewardToken(_liquidityPool),
                    _underlyingToken,
                    _unclaimedReward
                )
            );
        }
        return b;
    }

    /**
     * @inheritdoc IAdapter
     */
    function getLiquidityPoolTokenBalance(
        address payable _vault,
        address,
        address _liquidityPool
    ) public view override returns (uint256) {
        return IERC20(_liquidityPool).balanceOf(_vault);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getSomeAmountInToken(
        address,
        address _liquidityPool,
        uint256 _liquidityPoolTokenAmount
    ) public view override returns (uint256) {
        if (_liquidityPoolTokenAmount > 0) {
            _liquidityPoolTokenAmount = _liquidityPoolTokenAmount
                .mul(IHarvestDeposit(_liquidityPool).getPricePerFullShare())
                .div(10**IHarvestDeposit(_liquidityPool).decimals());
        }
        return _liquidityPoolTokenAmount;
    }

    /**
     * @inheritdoc IAdapter
     */
    function getRewardToken(address _liquidityPool) public view override returns (address) {
        return IHarvestFarm(liquidityPoolToStakingVault[_liquidityPool]).rewardToken();
    }

    /**
     * @inheritdoc IAdapterHarvestReward
     */
    function getUnclaimedRewardTokenAmount(
        address payable _vault,
        address _liquidityPool,
        address
    ) public view override returns (uint256) {
        return IHarvestFarm(liquidityPoolToStakingVault[_liquidityPool]).earned(_vault);
    }

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
    function getStakeSomeCodes(address _liquidityPool, uint256 _shares)
        public
        view
        override
        returns (bytes[] memory _codes)
    {
        if (_shares > 0) {
            address _stakingVault = liquidityPoolToStakingVault[_liquidityPool];
            address _liquidityPoolToken = getLiquidityPoolToken(address(0), _liquidityPool);
            _codes = new bytes[](3);
            _codes[0] = abi.encode(
                _liquidityPoolToken,
                abi.encodeWithSignature("approve(address,uint256)", _stakingVault, uint256(0))
            );
            _codes[1] = abi.encode(
                _liquidityPoolToken,
                abi.encodeWithSignature("approve(address,uint256)", _stakingVault, _shares)
            );
            _codes[2] = abi.encode(_stakingVault, abi.encodeWithSignature("stake(uint256)", _shares));
        }
    }

    /**
     * @inheritdoc IAdapterStaking
     */
    function getUnstakeSomeCodes(address _liquidityPool, uint256 _shares)
        public
        view
        override
        returns (bytes[] memory _codes)
    {
        if (_shares > 0) {
            address _stakingVault = liquidityPoolToStakingVault[_liquidityPool];
            _codes = new bytes[](1);
            _codes[0] = abi.encode(_stakingVault, abi.encodeWithSignature("withdraw(uint256)", _shares));
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
        address _stakingVault = liquidityPoolToStakingVault[_liquidityPool];
        uint256 b = IHarvestFarm(_stakingVault).balanceOf(_vault);
        if (b > 0) {
            b = b.mul(IHarvestDeposit(_liquidityPool).getPricePerFullShare()).div(
                10**IHarvestDeposit(_liquidityPool).decimals()
            );
        }
        uint256 _unclaimedReward = getUnclaimedRewardTokenAmount(_vault, _liquidityPool, _underlyingToken);
        if (_unclaimedReward > 0) {
            b = b.add(
                IHarvestCodeProvider(registryContract.getHarvestCodeProvider()).rewardBalanceInUnderlyingTokens(
                    getRewardToken(_liquidityPool),
                    _underlyingToken,
                    _unclaimedReward
                )
            );
        }
        return b;
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
        address _stakingVault = liquidityPoolToStakingVault[_liquidityPool];
        return IHarvestFarm(_stakingVault).balanceOf(_vault);
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
            _codes = new bytes[](2);
            _codes[0] = getUnstakeSomeCodes(_liquidityPool, _redeemAmount)[0];
            _codes[1] = getWithdrawSomeCodes(_vault, _underlyingToken, _liquidityPool, _redeemAmount)[0];
        }
    }

    function _getDepositAmount(
        address _liquidityPool,
        address _underlyingToken,
        uint256 _amount
    ) internal view returns (uint256) {
        uint256 _limit =
            maxDepositProtocolMode == MaxExposure.Pct
                ? _getMaxDepositAmountByPct(_liquidityPool)
                : maxDepositAmount[_liquidityPool][_underlyingToken];
        return _amount > _limit ? _limit : _amount;
    }

    function _getMaxDepositAmountByPct(address _liquidityPool) internal view returns (uint256) {
        uint256 _poolValue = getPoolValue(_liquidityPool, address(0));
        uint256 _poolPct = maxDepositPoolPct[_liquidityPool];
        uint256 _limit =
            _poolPct == 0
                ? _poolValue.mul(maxDepositProtocolPct).div(uint256(10000))
                : _poolValue.mul(_poolPct).div(uint256(10000));
        return _limit;
    }

    function _getUnderlyingToken(address _liquidityPoolToken) internal view returns (address) {
        return IHarvestDeposit(_liquidityPoolToken).underlying();
    }
}