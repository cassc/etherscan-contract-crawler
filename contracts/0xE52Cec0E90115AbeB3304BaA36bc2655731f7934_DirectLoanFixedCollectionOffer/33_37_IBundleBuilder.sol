// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

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
        uint256 id;
        bool safeTransferable;
    }

    /**
     * @notice data of a erc20 bundle element
     *
     * @param tokenContract - address of the token contract
     * @param amount - amount of the token
     */
    struct BundleElementERC20 {
        address tokenContract;
        uint256 amount;
    }

    /**
     * @notice data of a erc20 bundle element
     *
     * @param tokenContract - address of the token contract
     * @param ids - list of ids of the tokens
     * @param amounts - list amounts of the tokens
     */
    struct BundleElementERC1155 {
        address tokenContract;
        uint256[] ids;
        uint256[] amounts;
    }

    /**
     * @notice the lists of erc721-20-1155 tokens that are to be bundled
     *
     * @param erc721s list of erc721 tokens
     * @param erc20s list of erc20 tokens
     * @param erc1155s list of erc1155 tokens
     */
    struct BundleElements {
        BundleElementERC721[] erc721s;
        BundleElementERC20[] erc20s;
        BundleElementERC1155[] erc1155s;
    }

    /**
     * @notice used by the loan contract to build a bundle from the BundleElements struct at the beginning of a loan,
     * returns the id of the created bundle
     *
     * @param _bundleElements - the lists of erc721-20-1155 tokens that are to be bundled
     * @param _sender sender of the tokens in the bundle - the borrower
     * @param _receiver receiver of the created bundle, normally the loan contract
     */
    function buildBundle(
        BundleElements memory _bundleElements,
        address _sender,
        address _receiver
    ) external returns (uint256);

    /**
     * @notice Remove all the children from the bundle
     * @dev This method may run out of gas if the list of children is too big. In that case, children can be removed
     *      individually.
     * @param _tokenId the id of the bundle
     * @param _receiver address of the receiver of the children
     */
    function decomposeBundle(uint256 _tokenId, address _receiver) external;
}