pragma solidity ^0.8.0;

import "./IRateProvider.sol";

interface ISLPCore {
    function calculateTokenAmount(uint256 vTokenAmount) external view returns (uint256 tokenAmount);
}

/**
 * @title vETH Rate Provider
 * @notice Returns the value of ETH in terms of vETH
 */
contract vETHRateProvider is IRateProvider {
    ISLPCore public immutable slpCore;

    constructor(ISLPCore _SLPCore) {
        slpCore = _SLPCore;
    }

    /**
     * @return  the value of ETH in terms of vETH
     */
    function getRate() external view override returns (uint256) {
        return slpCore.calculateTokenAmount(1e18);
    }
}