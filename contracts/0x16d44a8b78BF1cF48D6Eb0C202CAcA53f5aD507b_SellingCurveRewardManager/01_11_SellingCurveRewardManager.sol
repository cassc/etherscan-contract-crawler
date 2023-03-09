//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '../../utils/Constants.sol';
import '../interfaces/IRewardManager.sol';
import '../interfaces/IStableConverter.sol';
import '../interfaces/ICurveWethPool.sol';
import '../interfaces/AggregatorV2V3Interface.sol';
import "../../interfaces/IElasticRigidVault.sol";

//import "hardhat/console.sol";

contract SellingCurveRewardManager is IRewardManager {
    using SafeERC20 for IERC20Metadata;

    uint256 public constant SLIPPAGE_DENOMINATOR = 10_000;

    uint256 public constant CURVE_WETH_REWARD_POOL_WETH_ID = 0;
    uint256 public constant CURVE_WETH_REWARD_POOL_REWARD_ID = 1;

    uint256 public constant CURVE_TRICRYPTO2_POOL_WETH_ID = 2;
    uint256 public constant CURVE_TRICRYPTO2_POOL_USDT_ID = 0;

    uint256 public constant defaultSlippage = 300; // 3%

    ICurveWethPool public immutable tricrypto2;

    mapping(address => address) public rewardEthCurvePools;

    mapping(address => address) public rewardUsdChainlinkOracles;

    IStableConverter public immutable stableConverter;

    IERC20Metadata public immutable zlp;
    IElasticRigidVault public immutable uzd;
    address immutable feeCollector;

    constructor(address stableConverterAddr, address uzdAddr, address feeCollectorAddr) {
        zlp = IERC20Metadata(0x2ffCC661011beC72e1A9524E12060983E74D14ce);

        require(stableConverterAddr != address(0), "StableConverter");
        stableConverter = IStableConverter(stableConverterAddr);

        require(uzdAddr != address(0), "Uzd");
        uzd = IElasticRigidVault(uzdAddr);

        require(feeCollectorAddr != address(0), "FeeCollector");
        feeCollector = feeCollectorAddr;

        tricrypto2 = ICurveWethPool(Constants.CRV_TRICRYPTO2_ADDRESS);

        rewardEthCurvePools[Constants.CVX_ADDRESS] = 0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4; // https://curve.fi/#/ethereum/pools/cvxeth
        rewardEthCurvePools[Constants.CRV_ADDRESS] = 0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511; // https://curve.fi/#/ethereum/pools/crveth
        rewardEthCurvePools[Constants.FXS_ADDRESS] = 0x941Eb6F616114e4Ecaa85377945EA306002612FE; // https://curve.fi/#/ethereum/pools/fxseth
        rewardEthCurvePools[Constants.SPELL_ADDRESS] = 0x98638FAcf9a3865cd033F36548713183f6996122; // https://curve.fi/#/ethereum/pools/spelleth

        rewardUsdChainlinkOracles[
            Constants.CVX_ADDRESS
        ] = 0xd962fC30A72A84cE50161031391756Bf2876Af5D; // https://data.chain.link/ethereum/mainnet/crypto-usd/cvx-usd
        rewardUsdChainlinkOracles[
            Constants.CRV_ADDRESS
        ] = 0xCd627aA160A6fA45Eb793D19Ef54f5062F20f33f; // https://data.chain.link/ethereum/mainnet/crypto-usd/crv-usd
        rewardUsdChainlinkOracles[
            Constants.FXS_ADDRESS
        ] = 0x6Ebc52C8C1089be9eB3945C4350B68B8E4C2233f; // https://data.chain.link/ethereum/mainnet/crypto-usd/fxs-usd
        rewardUsdChainlinkOracles[
            Constants.SPELL_ADDRESS
        ] = 0x8c110B94C5f1d347fAcF5E1E938AB2db60E3c9a8; // https://data.chain.link/ethereum/mainnet/crypto-usd/spell-usd
    }

    function handle(
        address reward,
        uint256 amount,
        address feeToken
    ) public {
        if (amount == 0) return;

        amount = extractRigidPart(reward, amount);

        ICurveWethPool rewardEthPool = ICurveWethPool(rewardEthCurvePools[reward]);

        IERC20Metadata(reward).safeIncreaseAllowance(address(rewardEthPool), amount);

        rewardEthPool.exchange(
            CURVE_WETH_REWARD_POOL_REWARD_ID,
            CURVE_WETH_REWARD_POOL_WETH_ID,
            amount,
            0
        );

        IERC20Metadata weth = IERC20Metadata(Constants.WETH_ADDRESS);
        uint256 wethAmount = weth.balanceOf(address(this));

        weth.safeIncreaseAllowance(address(tricrypto2), wethAmount);

        tricrypto2.exchange(
            CURVE_TRICRYPTO2_POOL_WETH_ID,
            CURVE_TRICRYPTO2_POOL_USDT_ID,
            wethAmount,
            0
        );

        if (feeToken != Constants.USDT_ADDRESS) {
            IERC20Metadata usdt = IERC20Metadata(Constants.USDT_ADDRESS);
            uint256 usdtAmount = usdt.balanceOf(address(this));

            usdt.safeTransfer(address(address(stableConverter)), usdtAmount);
            stableConverter.handle(Constants.USDT_ADDRESS, feeToken, usdtAmount, 0);
        }

        uint256 feeTokenAmount = IERC20Metadata(feeToken).balanceOf(address(this));

        checkSlippage(reward, amount, feeTokenAmount);

        IERC20Metadata(feeToken).safeTransfer(address(msg.sender), feeTokenAmount);
    }

    function valuate(
        address reward,
        uint256 amount,
        address feeToken
    ) public view returns (uint256) {
        if (amount == 0) return 0;

        ICurveWethPool rewardEthPool = ICurveWethPool(rewardEthCurvePools[reward]);

        uint256 wethAmount = rewardEthPool.get_dy(
            CURVE_WETH_REWARD_POOL_REWARD_ID,
            CURVE_WETH_REWARD_POOL_WETH_ID,
            amount
        );

        uint256 usdtAmount = tricrypto2.get_dy(
            CURVE_TRICRYPTO2_POOL_WETH_ID,
            CURVE_TRICRYPTO2_POOL_USDT_ID,
            wethAmount
        );

        if (feeToken == Constants.USDT_ADDRESS) return usdtAmount;

        return stableConverter.valuate(Constants.USDT_ADDRESS, feeToken, usdtAmount);
    }

    function checkSlippage(
        address reward,
        uint256 amount,
        uint256 feeTokenAmount
    ) internal view {
        AggregatorV2V3Interface oracle = AggregatorV2V3Interface(rewardUsdChainlinkOracles[reward]);
        (, int256 answer, , , ) = oracle.latestRoundData();

        uint256 feeTokenAmountByOracle = (uint256(answer) * amount) / 1e20; // reward decimals 18 + oracle decimals 2 (8 - 6)
        uint256 feeTokenAmountByOracleWithSlippage = (feeTokenAmountByOracle *
            (SLIPPAGE_DENOMINATOR - defaultSlippage)) / SLIPPAGE_DENOMINATOR;

        require(feeTokenAmount >= feeTokenAmountByOracleWithSlippage, 'Wrong slippage');
    }

    function extractRigidPart(address reward, uint256 amount) internal returns(uint256){
        uint256 zlpSupply = zlp.totalSupply();
        uint256 zlpLocked = uzd.lockedNominalRigid();

        uint256 rewardLocked = amount * zlpLocked / zlpSupply;
        if(rewardLocked > 0) {
            IERC20Metadata(reward).safeTransfer(feeCollector, rewardLocked);
        }

        return amount - rewardLocked;
    }
}