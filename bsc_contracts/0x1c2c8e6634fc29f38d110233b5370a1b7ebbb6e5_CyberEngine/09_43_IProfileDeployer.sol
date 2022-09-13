// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface IProfileDeployer {
    /**
     * @notice Parameters when constructing a ProfileNFT.
     *
     * @return engine The CyberEngine address.
     * @return subBeacon The Subscribe Beacon address.
     * @return essenceBeacon The Essence Beacon address.
     */
    function profileParams()
        external
        view
        returns (
            address engine,
            address subBeacon,
            address essenceBeacon
        );

    /**
     * @notice Deploy a new ProfileNFT.
     *
     * @param salt The salt used to generate contract address in a deterministic way.
     * @param engine The CyberEngine address.
     * @param subscribeBeacon The Subscribe Beacon address.
     * @param essenceBeacon The Essence Beacon address.
     *
     * @return addr The newly deployed ProfileNFT address.
     */
    function deployProfile(
        bytes32 salt,
        address engine,
        address subscribeBeacon,
        address essenceBeacon
    ) external returns (address addr);
}