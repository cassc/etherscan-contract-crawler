// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface rIDFee {
   
    /// @dev Lets a module admin update the fees on primary sales.
    function setrIDFeeInfo(address _rIDFeeRecipient, uint256 _rIDFeeBps) external;

    /// @dev Emitted when fee on primary sales is updated.
    event rIDFeeInfoUpdated(address rIDRecipient, uint256 rIDFeeBps);
}