//SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.21;

/**
 * @title RMRK ERC721 Wrapper Deployer Interface
 * @notice This is interface is for an intermediary contract whose only purpose is to deploy Wrapped Collections.
 * @dev This contract does not have any validation, it is kept the minimal possible to avoid breaking the size limit.
 */
interface IRMRKERC721WrapperDeployer {
    /**
     * @notice Deploys a new Wrapped Collection.
     * @dev The basis points (bPt) are integer representation of percentage up to the second decimal space. Meaning that
     *  1 bPt equals 0.01% and 500 bPt equal 5%.
     * @param originalCollection The address of the original collection
     * @param maxSupply The maximum supply of the wrapped collection
     * @param royaltiesRecipient The address of the royalties recipient
     * @param royaltyPercentageBps The royalty percentage in basis points
     * @param collectionMetadataURI The metadata URI of the wrapped collection
     * @return wrappedCollection The address of the newly deployed wrapped collection
     */
    function wrapCollection(
        address originalCollection,
        uint256 maxSupply,
        address royaltiesRecipient,
        uint256 royaltyPercentageBps,
        string memory collectionMetadataURI
    ) external returns (address wrappedCollection);
}