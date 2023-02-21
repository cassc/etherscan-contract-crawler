// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import {ERC4626Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "./interfaces.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";

/// @title      Variables
/// @notice     Contains common storage variables of all modules of Infinite proxy.
contract ConstantVariables {
    uint256 internal constant RAY = 10 ** 27;

    IInstaIndex internal constant INSTA_INDEX_CONTRACT =
        IInstaIndex(0x2971AdFa57b20E5a416aE5a708A8655A9c74f723);
    address internal constant IETH_TOKEN_V1 =
        0xc383a3833A87009fD9597F8184979AF5eDFad019;

    /***********************************|
    |           STETH ADDRESSES         |
    |__________________________________*/
    address internal constant STETH_ADDRESS =
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    // IERC20 internal constant STETH_CONTRACT = IERC20(STETH_ADDRESS);
    address internal constant A_STETH_ADDRESS =
        0x1982b2F5814301d4e9a8b0201555376e62F82428;

    /***********************************|
    |           WSTETH ADDRESSES        |
    |__________________________________*/
    address internal constant WSTETH_ADDRESS =
        0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    IWstETH internal constant WSTETH_CONTRACT = IWstETH(WSTETH_ADDRESS);
    address internal constant A_WSTETH_ADDRESS_AAVEV3 =
        0x0B925eD163218f6662a35e0f0371Ac234f9E9371;
    address internal constant E_WSTETH_ADDRESS =
        0xbd1bd5C956684f7EB79DA40f582cbE1373A1D593;

    /***********************************|
    |           ETH ADDRESSES           |
    |__________________________________*/
    address internal constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant WETH_ADDRESS =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant A_WETH_ADDRESS =
        0x030bA81f1c18d280636F32af80b9AAd02Cf0854e;
    address internal constant D_WETH_ADDRESS =
        0xF63B34710400CAd3e044cFfDcAb00a0f32E33eCf;
    address internal constant D_WETH_ADDRESS_AAVEV3 =
        0xeA51d7853EEFb32b6ee06b1C12E6dcCA88Be0fFE;
    address internal constant EULER_D_WETH_ADDRESS =
        0x62e28f054efc24b26A794F5C1249B6349454352C;

    address internal constant COMP_ETH_MARKET_ADDRESS =
        0xA17581A9E3356d9A858b789D68B4d866e593aE94;

    ILiteVaultV1 internal constant LITE_VAULT_V1 = ILiteVaultV1(IETH_TOKEN_V1);

    ICompoundMarket internal constant COMP_ETH_MARKET_CONTRACT =
        ICompoundMarket(COMP_ETH_MARKET_ADDRESS);

    IMorphoAaveV2 internal constant MORPHO_CONTRACT =
        IMorphoAaveV2(0x777777c9898D384F785Ee44Acfe945efDFf5f3E0);

    IAavePoolProviderInterface internal constant AAVE_POOL_PROVIDER =
        IAavePoolProviderInterface(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
}

contract Variables is ERC4626Upgradeable, ConstantVariables {
    /****************************************************************************|
    |   @notice Ids associated with protocols at the time of deployment.         |
    |   New protocols might have been added or removed at the time of viewing.   |
    |                          AAVE_V2 => 1                                      |
    |                          AAVE_V3 => 2                                      |
    |                          COMPOUND_V3 => 3                                  |
    |                          EULER => 4                                        |
    |                          MORPHO_AAVE_V2 => 5                               |
    |___________________________________________________________________________*/

    /***********************************|
    |           STATE VARIABLES         |
    |__________________________________*/
    /*
     * Includes variables from ERC4626Upgradeable
     */

    /// @notice variables.sol is imported in all the files. Adding _disableInitializers() so the implementation can't be manipulated
    constructor() {
        _disableInitializers();
    }

    // 1: open; 2: closed
    uint8 internal _status;

    IDSA public vaultDSA;

    /// @notice Max limit (in wei) allowed for wsteth per eth unit amount.
    uint256 public leverageMaxUnitAmountLimit;

    /// @notice Secondary auth that only has the power to reduce max risk ratio.
    address public secondaryAuth;

    // Current exchange price.
    uint256 public exchangePrice;

    // Revenue exchange price (helps in calculating revenue).
    // Exchange price when revenue got updated last. It'll only increase overtime.
    uint256 public revenueExchangePrice;

    /// @notice mapping to store allowed rebalancers
    ///         modifiable by auth
    mapping(address => bool) public isRebalancer;

    // Mapping of protocol id => max risk ratio, scaled to factor 4.
    // i.e. 1% would equal 10,000; 10% would be 100,000 etc.
    // 1 = Aave v2
    // 2 = Aave v3
    // 3 = Compound v3 (ETH market)
    // 4 = Euler
    // 5 = Morpho Aave v2
    mapping(uint8 => uint256) public maxRiskRatio;

    // Max aggregated risk ratio of the vault that can be reached, scaled to factor 4.
    // i.e. 1% would equal 10,000; 10% would be 100,000 etc.
    uint256 public aggrMaxVaultRatio;

    /// @notice withdraw fee is either amount in percentage or absolute minimum. This var defines the percentage in 1e6
    /// this number is given in 1e4, i.e. 1% would equal 10,000; 10% would be 100,000 etc.
    /// modifiable by owner
    uint256 public withdrawalFeePercentage;

    /// @notice withdraw fee is either amount in percentage or absolute minimum. This var defines the absolute minimum
    /// this number is given in decimals for the respective asset of the vault.
    /// modifiable by owner
    uint256 public withdrawFeeAbsoluteMin; // in underlying base asset, i.e. stEth

    // charge from the profits, scaled to factor 4.
    // 100,000 would be 10% cut from profit
    uint256 public revenueFeePercentage;

    /// @notice Stores profit revenue and withdrawal fees collected.
    uint256 public revenue;

    /// @notice Revenue will be transffered to this address upon collection.
    address public treasury;
}