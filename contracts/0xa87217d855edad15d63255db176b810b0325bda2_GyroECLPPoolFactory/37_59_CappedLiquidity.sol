// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/concentrated-lps>.
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

// import "@balancer-labs/v2-solidity-utils/contracts/math/FixedPoint.sol";
import "../libraries/GyroFixedPoint.sol";

import "../interfaces/ICappedLiquidity.sol";

import "@balancer-labs/v2-solidity-utils/contracts/helpers/IAuthentication.sol";

/** @dev Enables caps on i) per-LP and ii) total caps on the pool size. Caps are in terms of BPT tokens! Pool functions
 * have to call _ensureCap() to enforce the cap.
 */
abstract contract CappedLiquidity is ICappedLiquidity {
    using GyroFixedPoint for uint256;

    string internal constant _OVER_GLOBAL_CAP = "over global liquidity cap";
    string internal constant _OVER_ADDRESS_CAP = "over address liquidity cap";
    string internal constant _NOT_AUTHORIZED = "not authorized";
    string internal constant _UNCAPPED = "pool is uncapped";

    CapParams internal _capParams;

    address public override capManager;

    constructor(address _capManager, CapParams memory params) {
        require(_capManager != address(0), _NOT_AUTHORIZED);
        capManager = _capManager;
        _capParams.capEnabled = params.capEnabled;
        _capParams.perAddressCap = params.perAddressCap;
        _capParams.globalCap = params.globalCap;
    }

    function setCapManager(address _capManager) external {
        require(msg.sender == capManager, _NOT_AUTHORIZED);
        capManager = _capManager;
        emit CapManagerUpdated(_capManager);
    }

    function capParams() external view override returns (CapParams memory) {
        return _capParams;
    }

    function setCapParams(CapParams memory params) external override {
        require(msg.sender == capManager, _NOT_AUTHORIZED);
        require(_capParams.capEnabled, _UNCAPPED);

        _capParams.capEnabled = params.capEnabled;
        _capParams.perAddressCap = params.perAddressCap;
        _capParams.globalCap = params.globalCap;

        emit CapParamsUpdated(_capParams);
    }

    function _ensureCap(
        uint256 amountMinted,
        uint256 userBalance,
        uint256 currentSupply
    ) internal view {
        CapParams memory params = _capParams;
        require(amountMinted.add(userBalance) <= params.perAddressCap, _OVER_ADDRESS_CAP);
        require(amountMinted.add(currentSupply) <= params.globalCap, _OVER_GLOBAL_CAP);
    }
}