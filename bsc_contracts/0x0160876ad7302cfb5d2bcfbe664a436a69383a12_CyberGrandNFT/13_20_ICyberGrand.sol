// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ICyberGrandEvents } from "../interfaces/ICyberGrandEvents.sol";

interface ICyberGrand is ICyberGrandEvents {
    /**
     * @notice Gets the signer for the CyberGrand NFT.
     *
     * @return address The signer of CyberGrand NFT.
     */
    function getSigner() external view returns (address);
}