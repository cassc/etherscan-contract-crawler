// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { LimitOrder } from "../libraries/LimitOrder.sol";

/// @title ICoordinatedTaker Interface
/// @author imToken Labs
interface ICoordinatedTaker {
    error ReusedPermission();
    error InvalidMsgValue();
    error InvalidSignature();
    error ExpiredPermission();
    error ZeroAddress();

    struct CoordinatorParams {
        bytes sig;
        uint256 salt;
        uint256 expiry;
    }

    event CoordinatorFill(address indexed user, bytes32 indexed orderHash, bytes32 indexed allowFillHash);

    /// @notice Emitted when coordinator address is updated
    /// @param newCoordinator The address of the new coordinator
    event SetCoordinator(address newCoordinator);

    function submitLimitOrderFill(
        LimitOrder calldata order,
        bytes calldata makerSignature,
        uint256 takerTokenAmount,
        uint256 makerTokenAmount,
        bytes calldata extraAction,
        bytes calldata userTokenPermit,
        CoordinatorParams calldata crdParams
    ) external payable;
}