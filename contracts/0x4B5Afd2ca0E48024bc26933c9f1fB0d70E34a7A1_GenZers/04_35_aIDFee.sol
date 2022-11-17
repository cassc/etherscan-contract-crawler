// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface aIDFee {
   
    /// @dev Lets a module admin update the fees on primary sales.
    function setaIDFeeInfo(address _aIDFeeRecipient, uint256 _aIDFeeBps) external;

    /// @dev Emitted when fee on primary sales is updated.
    event aIDFeeInfoUpdated(address aIDRecipient, uint256 aIDFeeBps);
}