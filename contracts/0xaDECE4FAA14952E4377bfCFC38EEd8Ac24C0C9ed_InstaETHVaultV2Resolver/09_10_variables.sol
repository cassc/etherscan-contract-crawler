// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;
import "./interface.sol";
import {
    ICompoundMarket,
    IMorphoAaveV2,
    IAavePoolProviderInterface
} from "../../vault/common/interfaces.sol";


contract Variables {
    VaultV2Interface public constant VAULT_V2 =
        VaultV2Interface(0xA0D3707c569ff8C87FA923d3823eC5D81c98Be78);

    address internal constant IETH_TOKEN_V1 =
        0xc383a3833A87009fD9597F8184979AF5eDFad019;

    uint256 public constant PROTOCOL_LENGTH = 5;

    uint256 internal constant RAY = 10 ** 27;

    /***********************************|
    |           STETH ADDRESSES         |
    |__________________________________*/
    address internal constant STETH_ADDRESS =
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address internal constant A_STETH_ADDRESS =
        0x1982b2F5814301d4e9a8b0201555376e62F82428;

    /***********************************|
    |           WSTETH ADDRESSES        |
    |__________________________________*/
    address internal constant WSTETH_ADDRESS =
        0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
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

    /***********************************|
    |         PROTOCOL ADDRESSES        |
    |__________________________________*/
    IWsteth internal constant WSTETH_CONTRACT = IWsteth(WSTETH_ADDRESS);
    
    IAaveV2AddressProvider internal constant aaveV2AddressProvider =
        IAaveV2AddressProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);

    IAaveV2DataProvider internal constant AAVE_V2_DATA =
        IAaveV2DataProvider(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);

    IAaveV3DataProvider internal constant AAVE_V3_DATA =
        IAaveV3DataProvider(0x7B4EB56E7CD4b454BA8ff71E4518426369a138a3);

    address internal constant COMP_ETH_MARKET_ADDRESS =
        0xA17581A9E3356d9A858b789D68B4d866e593aE94;

    IComet internal constant COMPOUND_V3_DATA =
        IComet(COMP_ETH_MARKET_ADDRESS);

    IEulerSimpleView internal constant EULER_SIMPLE_VIEW =
        IEulerSimpleView(0x5077B7642abF198b4a5b7C4BdCE4f03016C7089C);

    IMorphoAaveLens internal constant MORPHO_AAVE_LENS =
        IMorphoAaveLens(0x507fA343d0A90786d86C7cd885f5C49263A91FF4);

    IChainlink internal constant STETH_IN_ETH =
        IChainlink(0x86392dC19c0b719886221c78AB11eb8Cf5c52812);

    IChainlink internal constant ETH_IN_USD =
        IChainlink(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);   

    ICompoundMarket internal constant COMP_ETH_MARKET_CONTRACT =
        ICompoundMarket(COMP_ETH_MARKET_ADDRESS);

    IMorphoAaveV2 internal constant MORPHO_CONTRACT =
        IMorphoAaveV2(0x777777c9898D384F785Ee44Acfe945efDFf5f3E0);

    IAavePoolProviderInterface internal constant AAVE_POOL_PROVIDER =
        IAavePoolProviderInterface(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5); 
}