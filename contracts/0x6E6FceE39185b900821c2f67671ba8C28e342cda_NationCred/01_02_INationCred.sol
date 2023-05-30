//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

interface INationCred {
    /**
     * Returns `true` if the passport ID belongs to an active Nation3 Citizen; `false` otherwise.
     *
     * @param passportID The NFT passport ID
     */
    function isActive(uint16 passportID) external view returns (bool);
}