// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IUniswapV3SingleTwapOracle is IERC165 {
    event SetTwapDuration(uint256 oldTwapDuration, uint256 newTwapDuration);

    function UNISWAP_V3_TWAP_BASE_TOKEN() external view returns (address);

    function UNISWAP_V3_TWAP_QUOTE_TOKEN() external view returns (address);

    function TWAP_PRECISION() external view returns (uint128);

    function UNI_V3_PAIR_ADDRESS() external view returns (address);

    function getUniswapV3Twap() external view returns (uint256 _twap);

    function twapDuration() external view returns (uint32);
}