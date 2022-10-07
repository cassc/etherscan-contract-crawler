// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../Common.sol";

interface IWGoldManager {
    function mintGold(TaskInfo memory _mintInfo, bytes memory _signature)
        external;

    function burnGold(TaskInfo memory _burnInfo, bytes memory _signature)
        external;
}