//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./interfaces/IRiver.1.sol";
import "./interfaces/IELFeeRecipient.1.sol";

import "./libraries/LibUint256.sol";

import "./Initializable.sol";

import "./state/shared/RiverAddress.sol";

/// @title Execution Layer Fee Recipient (v1)
/// @author Kiln
/// @notice This contract receives all the execution layer fees from the proposed blocks + bribes
contract ELFeeRecipientV1 is Initializable, IELFeeRecipientV1 {
    /// @inheritdoc IELFeeRecipientV1
    function initELFeeRecipientV1(address _riverAddress) external init(0) {
        RiverAddress.set(_riverAddress);
        emit SetRiver(_riverAddress);
    }

    /// @inheritdoc IELFeeRecipientV1
    function pullELFees(uint256 _maxAmount) external {
        address river = RiverAddress.get();
        if (msg.sender != river) {
            revert LibErrors.Unauthorized(msg.sender);
        }
        uint256 amount = LibUint256.min(_maxAmount, address(this).balance);

        IRiverV1(payable(river)).sendELFees{value: amount}();
    }

    /// @inheritdoc IELFeeRecipientV1
    receive() external payable {
        this;
    }

    /// @inheritdoc IELFeeRecipientV1
    fallback() external payable {
        revert InvalidCall();
    }
}