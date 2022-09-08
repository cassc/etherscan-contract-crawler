//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "./IExchangeLedger.sol";

/// @notice IExchangeHook allows to plug a custom handler in the ExchangeLedger.changePosition() execution flow,
/// for example, to grant incentives. This pattern allows us to keep the ExchangeLedger simple, and extend its
/// functionality with a plugin model.
interface IExchangeHook {
    /// `onChangePosition` is called by the ExchangeLedger when there's a position change.
    function onChangePosition(IExchangeLedger.ChangePositionData calldata cpd) external;
}