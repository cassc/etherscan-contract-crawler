// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

interface IBundleBuilder {
    /**
     * @notice data of a erc721 bundle element
     *
     * @param tokenContract - address of the token contract
     * @param id - id of the token
     * @param safeTransferable - wether the implementing token contract has a safeTransfer function or not
     */
    struct BundleElementERC721 {
        address tokenContract;
        uint256[] ids;
        bool safeTransferable;
    }

    /**
     * @notice used to build a bundle from the BundleElements struct,
     * returns the id of the created bundle
     *
     * @param _bundleElements - the lists of erc721 tokens that are to be bundled
     */
    function buildBundle(BundleElementERC721[] memory _bundleElements) external returns (uint256);

    /**
     * @notice Remove all the children from the bundle
     * @dev This method may run out of gas if the list of children is too big. In that case, children can be removed
     *      individually or in smaller batches.
     * @param _tokenId the id of the bundle
     * @param _receiver address of the receiver of the children
     */
    function decomposeBundle(uint256 _tokenId, address _receiver) external;

    event AddBundleElements(uint256 indexed _tokenId, BundleElementERC721[] _bundleElements);
    event RemoveBundleElements(uint256 indexed _tokenId, BundleElementERC721[] _bundleElements);
}