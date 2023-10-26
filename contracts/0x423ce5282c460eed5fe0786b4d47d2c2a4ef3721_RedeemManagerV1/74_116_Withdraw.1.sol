//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./Initializable.sol";
import "./interfaces/IRiver.1.sol";
import "./interfaces/IWithdraw.1.sol";
import "./libraries/LibErrors.sol";
import "./libraries/LibUint256.sol";

import "./state/shared/RiverAddress.sol";

/// @title Withdraw (v1)
/// @author Kiln
/// @notice This contract is in charge of holding the exit and skimming funds and allow river to pull these funds
contract WithdrawV1 is IWithdrawV1, Initializable {
    modifier onlyRiver() {
        if (msg.sender != RiverAddress.get()) {
            revert LibErrors.Unauthorized(msg.sender);
        }
        _;
    }

    /// @inheritdoc IWithdrawV1
    function initializeWithdrawV1(address _river) external init(0) {
        _setRiver(_river);
    }

    /// @inheritdoc IWithdrawV1
    function getCredentials() external view returns (bytes32) {
        return bytes32(
            uint256(uint160(address(this))) + 0x0100000000000000000000000000000000000000000000000000000000000000
        );
    }

    /// @inheritdoc IWithdrawV1
    function getRiver() external view returns (address) {
        return RiverAddress.get();
    }

    /// @inheritdoc IWithdrawV1
    function pullEth(uint256 _max) external onlyRiver {
        uint256 amountToPull = LibUint256.min(address(this).balance, _max);
        if (amountToPull > 0) {
            IRiverV1(payable(RiverAddress.get())).sendCLFunds{value: amountToPull}();
        }
    }

    /// @notice Internal utility to set the river address
    /// @param _river The new river address
    function _setRiver(address _river) internal {
        RiverAddress.set(_river);
        emit SetRiver(_river);
    }
}