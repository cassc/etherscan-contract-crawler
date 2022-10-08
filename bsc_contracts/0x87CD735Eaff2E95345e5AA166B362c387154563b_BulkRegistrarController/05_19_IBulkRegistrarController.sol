// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../libraries/Registration.sol";

interface IBulkRegistrarController {
    event NameRegisterFailed(
        address indexed registrar,
        bytes32 indexed labelId,
        string name
    );

    struct RentPrice {
        address currency;
        uint256 cost;
    }

    function nameRecords(
        address registrar,
        bytes32 node,
        string[] calldata keys
    ) external view returns (address payable, string[] memory);

    function available(address[] calldata registrars, string[] calldata names)
        external
        view
        returns (bool[] memory, uint256[] memory);

    function rentPrice(
        address[] calldata registrars,
        string[] calldata names,
        uint256[] calldata durations
    ) external view returns (RentPrice[] memory);

    function bulkRenew(
        address[] calldata registrars,
        string[] calldata names,
        uint256[] calldata durations
    ) external payable;
}