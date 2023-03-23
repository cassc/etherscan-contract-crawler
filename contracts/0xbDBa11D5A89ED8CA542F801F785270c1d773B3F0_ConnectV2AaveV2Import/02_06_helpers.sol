//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Stores } from "../common/stores.sol";
import { AaveLendingPoolProviderInterface, AaveDataProviderInterface } from "./interfaces.sol";

abstract contract Helpers is Stores {
    /**
     * @dev Aave referal code
     */
    uint16 constant internal referalCode = 3228;

    /**
     * @dev Aave Provider
     */
    AaveLendingPoolProviderInterface constant internal aaveProvider = AaveLendingPoolProviderInterface(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);

    /**
     * @dev Aave Data Provider
     */
    AaveDataProviderInterface constant internal aaveData = AaveDataProviderInterface(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);

    function getIsColl(address token, address user) internal view returns (bool isCol) {
        (, , , , , , , , isCol) = aaveData.getUserReserveData(token, user);
    }
}