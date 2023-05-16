// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IFraxUsdcUniswapV3SingleTwapOracle is IERC165 {
    event SetFraxUsdcTwapDuration(uint256 oldTwapDuration, uint256 newTwapDuration);

    function FRAX_USDC_TWAP_PRECISION() external view returns (uint128);

    function FRAX_USDC_UNISWAP_V3_TWAP_BASE_TOKEN() external view returns (address);

    function FRAX_USDC_UNISWAP_V3_TWAP_QUOTE_TOKEN() external view returns (address);

    function FRAX_USDC_UNI_V3_PAIR_ADDRESS() external view returns (address);

    function getFraxUsdcUniswapV3Twap() external view returns (uint256 _twap);

    function fraxUsdcTwapDuration() external view returns (uint32);

    function setFraxUsdcTwapDuration(uint32 _newTwapDuration) external;
}