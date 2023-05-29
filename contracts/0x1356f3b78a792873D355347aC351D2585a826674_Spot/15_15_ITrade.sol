//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ISpotStorage} from "src/spot/interfaces/ISpotStorage.sol";

interface ITrade is ISpotStorage {
    event OpenSpot(
        bytes32 indexed salt,
        uint96 amount,
        uint256 swapAmount,
        uint96 received,
        bytes commands,
        bytes[] inputs,
        uint256 deadline
    );

    event CloseSpot(
        bytes32 indexed salt,
        uint96 remainingAfterClose,
        uint96 managerFee,
        uint96 protocolFee,
        bytes commands,
        bytes[] inputs,
        uint256 deadline
    );

    function openSpot(uint96 amount, bytes calldata commands, bytes[] calldata inputs, uint256 deadline)
        external
        returns (uint96 received);

    function closeSpot(bytes calldata commands, bytes[] calldata inputs, uint256 deadline)
        external
        returns (uint96 remaining);

    function closeSpotByAdmin(bytes calldata commands, bytes[] calldata inputs, bytes32 salt)
        external
        returns (uint96 remaining);
}