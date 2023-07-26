// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/concentrated-lps>.

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-vault/contracts/interfaces/IVault.sol";

import "@balancer-labs/v2-pool-utils/contracts/factories/BasePoolSplitCodeFactory.sol";
import "@balancer-labs/v2-pool-utils/contracts/factories/FactoryWidePauseWindow.sol";

import "../../interfaces/IGyroECLPPoolFactory.sol";
import "../../interfaces/ICappedLiquidity.sol";
import "./GyroECLPPool.sol";

contract GyroECLPPoolFactory is IGyroECLPPoolFactory, BasePoolSplitCodeFactory, FactoryWidePauseWindow {
    address public immutable gyroConfigAddress;

    uint256 public constant PAUSE_WINDOW_DURATION = 90 days;
    uint256 public constant BUFFER_PERIOD_DURATION = 30 days;

    constructor(IVault vault, address _gyroConfigAddress) BasePoolSplitCodeFactory(vault, type(GyroECLPPool).creationCode) {
        _grequire(_gyroConfigAddress != address(0), GyroErrors.ZERO_ADDRESS);
        _grequire(address(vault) != address(0), GyroErrors.ZERO_ADDRESS);
        gyroConfigAddress = _gyroConfigAddress;
    }

    /**
     * @dev Deploys a new `GyroECLPPool`.
     */
    function create(
        string memory name,
        string memory symbol,
        IERC20[] memory tokens,
        GyroECLPMath.Params memory eclpParams,
        GyroECLPMath.DerivedParams memory derivedECLPParams,
        address[] memory rateProviders,
        uint256 swapFeePercentage,
        address owner,
        address capManager,
        ICappedLiquidity.CapParams memory capParams,
        address pauseManager,
        ILocallyPausable.PauseParams memory pauseParams
    ) external override returns (address) {
        ExtensibleWeightedPool2Tokens.NewPoolParams memory baseParams = _makePoolParams(name, symbol, tokens, swapFeePercentage, owner, pauseParams);

        GyroECLPPool.GyroParams memory params = GyroECLPPool.GyroParams({
            baseParams: baseParams,
            eclpParams: eclpParams,
            derivedEclpParams: derivedECLPParams,
            rateProvider0: rateProviders[0],
            rateProvider1: rateProviders[1],
            capManager: capManager,
            capParams: capParams,
            pauseManager: pauseManager
        });

        return _create(abi.encode(params, gyroConfigAddress));
    }

    function _makePoolParams(
        string memory name,
        string memory symbol,
        IERC20[] memory tokens,
        uint256 swapFeePercentage,
        address owner,
        ILocallyPausable.PauseParams memory pauseParams
    ) internal view returns (ExtensibleWeightedPool2Tokens.NewPoolParams memory) {
        return
            ExtensibleWeightedPool2Tokens.NewPoolParams({
                vault: getVault(),
                name: name,
                symbol: symbol,
                token0: tokens[0],
                token1: tokens[1],
                swapFeePercentage: swapFeePercentage,
                pauseWindowDuration: pauseParams.pauseWindowDuration,
                bufferPeriodDuration: pauseParams.bufferPeriodDuration,
                owner: owner
            });
    }
}