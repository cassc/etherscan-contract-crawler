// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

interface IDynasetTvlOracle {
    function dynasetTvlUsdc() external view returns (uint256 total_usd);

    function tokenUsdcValue(address _tokenIn, uint256 _amount) external view returns (uint256);

    function dynasetUsdcValuePerShare() external view returns (uint256);

    function dynasetTokenUsdcRatios() external view returns (address[] memory, uint256[] memory, uint256);
    
}