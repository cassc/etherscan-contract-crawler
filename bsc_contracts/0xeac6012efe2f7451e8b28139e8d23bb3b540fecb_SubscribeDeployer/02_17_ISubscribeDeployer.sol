// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface ISubscribeDeployer {
    /**
     * @notice Parameters when constructing a SubscribeNFT.
     *
     * @return profileProxy The ProfileNFT proxy address.
     */
    function subParams() external view returns (address profileProxy);

    /**
     * @notice Deploy a new SubscribeNFT.
     *
     * @param salt The salt used to generate contract address in a deterministic way.
     * @param profileProxy The ProfileNFT proxy address.
     *
     * @return addr The newly deployed SubscribeNFT address.
     */
    function deploySubscribe(bytes32 salt, address profileProxy)
        external
        returns (address addr);
}