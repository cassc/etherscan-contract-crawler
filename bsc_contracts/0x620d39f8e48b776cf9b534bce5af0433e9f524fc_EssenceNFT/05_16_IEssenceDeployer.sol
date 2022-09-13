// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface IEssenceDeployer {
    /**
     * @notice Parameters when constructing a EssenceNFT.
     *
     * @return profileProxy The ProfileNFT proxy address.
     */
    function essParams() external view returns (address profileProxy);

    /**
     * @notice Deploy a new EssenceNFT.
     *
     * @param salt The salt used to generate contract address in a deterministic way.
     * @param profileProxy The CyberEngine address.
     *
     * @return addr The newly deployed EssenceNFT address.
     */
    function deployEssence(bytes32 salt, address profileProxy)
        external
        returns (address addr);
}