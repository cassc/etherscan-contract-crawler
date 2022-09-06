// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./NormalizingOracleAdapter.sol";
import "../../interfaces/ICurvePool.sol";

contract CurveLPMetaPoolAdapter is NormalizingOracleAdapter {
    ICurvePool public immutable curvePool;

    constructor(
        string memory _assetName,
        string memory _assetSymbol,
        address _asset,
        address _curvePool
    ) NormalizingOracleAdapter(_assetName, _assetSymbol, _asset, 18, 8) {
        require(address(_curvePool) != address(0), "invalid oracle");
        curvePool = ICurvePool(_curvePool);
    }

    function latestAnswer() external view override returns (int256) {
        uint256 price = _normalize(curvePool.get_virtual_price());
        return int256(price);
    }
}