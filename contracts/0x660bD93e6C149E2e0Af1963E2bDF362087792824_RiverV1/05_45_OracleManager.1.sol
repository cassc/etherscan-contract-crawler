//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../interfaces/components/IOracleManager.1.sol";

import "../state/river/OracleAddress.sol";
import "../state/river/LastOracleRoundId.sol";
import "../state/river/CLValidatorTotalBalance.sol";
import "../state/river/CLValidatorCount.sol";
import "../state/river/DepositedValidatorCount.sol";

/// @title Oracle Manager (v1)
/// @author Kiln
/// @notice This contract handles the inputs provided by the oracle
/// @notice The Oracle contract is plugged to this contract and is in charge of pushing
/// @notice data whenever a new report has been deemed valid. The report consists in two
/// @notice values: the sum of all balances of all deposited validators and the count of
/// @notice validators that have been activated on the consensus layer.
abstract contract OracleManagerV1 is IOracleManagerV1 {
    /// @notice Handler called if the delta between the last and new validator balance sum is positive
    /// @dev Must be overridden
    /// @param _profits The positive increase in the validator balance sum (staking rewards)
    function _onEarnings(uint256 _profits) internal virtual;

    /// @notice Handler called to pull the Execution layer fees from the recipient
    /// @dev Must be overridden
    /// @param _max The maximum amount to pull inside the system
    /// @return The amount pulled inside the system
    function _pullELFees(uint256 _max) internal virtual returns (uint256);

    /// @notice Handler called to retrieve the system administrator address
    /// @dev Must be overridden
    /// @return The system administrator address
    function _getRiverAdmin() internal view virtual returns (address);

    /// @notice Prevents unauthorized calls
    modifier onlyAdmin_OMV1() {
        if (msg.sender != _getRiverAdmin()) {
            revert LibErrors.Unauthorized(msg.sender);
        }
        _;
    }

    /// @notice Set the initial oracle address
    /// @param _oracle Address of the oracle
    function initOracleManagerV1(address _oracle) internal {
        OracleAddress.set(_oracle);
        emit SetOracle(_oracle);
    }

    /// @inheritdoc IOracleManagerV1
    function getOracle() external view returns (address) {
        return OracleAddress.get();
    }

    /// @inheritdoc IOracleManagerV1
    function getCLValidatorTotalBalance() external view returns (uint256) {
        return CLValidatorTotalBalance.get();
    }

    /// @inheritdoc IOracleManagerV1
    function getCLValidatorCount() external view returns (uint256) {
        return CLValidatorCount.get();
    }

    /// @inheritdoc IOracleManagerV1
    function setOracle(address _oracleAddress) external onlyAdmin_OMV1 {
        OracleAddress.set(_oracleAddress);
        emit SetOracle(_oracleAddress);
    }

    /// @inheritdoc IOracleManagerV1
    function setConsensusLayerData(
        uint256 _validatorCount,
        uint256 _validatorTotalBalance,
        bytes32 _roundId,
        uint256 _maxIncrease
    ) external {
        if (msg.sender != OracleAddress.get()) {
            revert LibErrors.Unauthorized(msg.sender);
        }

        if (_validatorCount > DepositedValidatorCount.get()) {
            revert InvalidValidatorCountReport(_validatorCount, DepositedValidatorCount.get());
        }

        uint256 newValidators = _validatorCount - CLValidatorCount.get();
        uint256 previousValidatorTotalBalance = CLValidatorTotalBalance.get() + (newValidators * 32 ether);

        CLValidatorTotalBalance.set(_validatorTotalBalance);
        CLValidatorCount.set(_validatorCount);
        LastOracleRoundId.set(_roundId);

        uint256 executionLayerFees;

        // if there's a margin left for pulling the execution layer fees that would leave our delta under the allowed maxIncrease value, do it
        if ((_maxIncrease + previousValidatorTotalBalance) > _validatorTotalBalance) {
            executionLayerFees = _pullELFees((_maxIncrease + previousValidatorTotalBalance) - _validatorTotalBalance);
        }

        if (previousValidatorTotalBalance < _validatorTotalBalance + executionLayerFees) {
            _onEarnings((_validatorTotalBalance + executionLayerFees) - previousValidatorTotalBalance);
        }

        emit ConsensusLayerDataUpdate(_validatorCount, _validatorTotalBalance, _roundId);
    }
}