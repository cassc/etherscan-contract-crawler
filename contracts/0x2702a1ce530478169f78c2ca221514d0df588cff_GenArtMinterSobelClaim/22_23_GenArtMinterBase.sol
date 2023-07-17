// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../access/GenArtAccess.sol";
import "../interface/IGenArtMinter.sol";
import "../interface/IGenArtMintAllocator.sol";

/**
 * @dev GEN.ART Default Minter
 * Admin for collections deployed on {GenArtCurated}
 */

abstract contract GenArtMinterBase is GenArtAccess, IGenArtMinter {
    struct MintParams {
        uint256 startTime;
        address mintAllocContract;
    }
    address public genArtCurated;
    address public genartInterface;
    mapping(address => MintParams) public mintParams;

    constructor(address genartInterface_, address genartCurated_)
        GenArtAccess()
    {
        genartInterface = genartInterface_;
        genArtCurated = genartCurated_;
    }

    /**
     * @dev Set pricing for collection
     * @param collection contract address of the collection
     * @param startTime start time for minting
     * @param mintAllocContract contract address of {GenArtMintAllocator}
     */
    function _setMintParams(
        address collection,
        uint256 startTime,
        address mintAllocContract
    ) internal {
        require(
            mintParams[collection].startTime == 0,
            "pricing already exists for collection"
        );
        require(
            mintParams[collection].startTime < block.timestamp,
            "mint already started for collection"
        );
        require(startTime > block.timestamp, "startTime too early");

        mintParams[collection] = MintParams(startTime, mintAllocContract);
    }

    /**
     * @dev Set the {GenArtInferface} contract address
     */
    function setInterface(address genartInterface_) external onlyAdmin {
        genartInterface = genartInterface_;
    }

    /**
     * @dev Set the {GenArtCurated} contract address
     */
    function setCurated(address genartCurated_) external onlyAdmin {
        genArtCurated = genartCurated_;
    }

    /**
     * @dev Get all available mints for account
     * @param collection contract address of the collection
     * @param account address of account
     */
    function getAvailableMintsForAccount(address collection, address account)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return
            IGenArtMintAllocator(mintParams[collection].mintAllocContract)
                .getAvailableMintsForAccount(collection, account);
    }

    /**
     * @dev Get available mints for a GEN.ART membership
     * @param collection contract address of the collection
     * @param membershipId owned GEN.ART membershipId
     */
    function getAvailableMintsForMembership(
        address collection,
        uint256 membershipId
    ) external view virtual override returns (uint256) {
        return
            IGenArtMintAllocator(mintParams[collection].mintAllocContract)
                .getAvailableMintsForMembership(collection, membershipId);
    }

    /**
     * @dev Get amount of minted tokens for a GEN.ART membership
     * @param collection contract address of the collection
     * @param membershipId owned GEN.ART membershipId
     */
    function getMembershipMints(address collection, uint256 membershipId)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return
            IGenArtMintAllocator(mintParams[collection].mintAllocContract)
                .getMembershipMints(collection, membershipId);
    }

    /**
     * @dev Get collection {MintParams} object
     * @param collection contract address of the collection
     */
    function getMintParams(address collection)
        external
        view
        returns (MintParams memory)
    {
        return mintParams[collection];
    }
}