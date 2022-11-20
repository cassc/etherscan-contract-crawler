// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../access/GenArtAccess.sol";
import "../app/GenArtCurated.sol";
import "../interface/IGenArtMinter.sol";
import "../interface/IGenArtMintAllocator.sol";
import "../interface/IGenArtInterface.sol";
import "../interface/IGenArtERC721.sol";
import "../interface/IGenArtPaymentSplitterV4.sol";

/**
 * @dev GEN.ART Default Minter
 * Admin for collections deployed on {GenArtCurated}
 */

contract GenArtMinter is GenArtAccess, IGenArtMinter {
    struct Pricing {
        address artist;
        uint256 startTime;
        uint256 price;
        address mintAlloc;
    }

    address public genArtCurated;
    address public genartInterface;
    mapping(address => Pricing) public collections;

    event PricingSet(
        address collection,
        uint256 startTime,
        uint256 price,
        address mintAlloc
    );

    constructor(address genartInterface_, address genartCurated_)
        GenArtAccess()
    {
        genartInterface = genartInterface_;
        genArtCurated = genartCurated_;
    }

    /**
     * @dev Add pricing for collection and set artist
     */
    function addPricing(address collection, address artist)
        external
        override
        onlyAdmin
    {
        require(
            collections[collection].artist == address(0),
            "pricing already exists for collection"
        );

        collections[collection] = Pricing(artist, 0, 0, address(0));
    }

    /**
     * @dev Set pricing for collection
     * @param collection contract address of the collection
     * @param startTime start time for minting
     * @param price price per token
     * @param mintAllocContract contract address of {GenArtMintAllocator}
     * @param mintAlloc mint allocation initalization args
     */
    function setPricing(
        address collection,
        uint256 startTime,
        uint256 price,
        address mintAllocContract,
        uint8[3] memory mintAlloc
    ) external {
        address sender = _msgSender();
        require(
            collections[collection].artist == sender || admins[sender],
            "only artist or admin allowed"
        );
        require(
            collections[collection].startTime < block.timestamp,
            "mint already started for collection"
        );
        require(startTime > block.timestamp, "startTime too early");
        if (collections[collection].price > 0) {
            require(admins[sender], "only admin allowed");
        }
        collections[collection].startTime = startTime;
        collections[collection].price = price;
        collections[collection].mintAlloc = mintAllocContract;
        IGenArtMintAllocator(mintAllocContract).init(collection, mintAlloc);
        emit PricingSet(collection, startTime, price, mintAllocContract);
    }

    /**
     * @dev Get price for collection
     * @param collection contract address of the collection
     */
    function getPrice(address collection)
        public
        view
        override
        returns (uint256)
    {
        return collections[collection].price;
    }

    /**
     * @dev Helper function to check for mint price and start date
     */
    function _checkMint(address collection, uint256 amount) internal view {
        require(
            msg.value >= getPrice(collection) * amount,
            "wrong amount sent"
        );
        require(
            collections[collection].startTime != 0 &&
                collections[collection].startTime <= block.timestamp,
            "mint not started yet"
        );
    }

    /**
     * @dev Helper function to check for available mints for sender
     */
    function _checkAvailableMints(
        address collection,
        uint256 membershipId,
        uint256 amount
    ) internal view {
        uint256 availableMints = IGenArtMintAllocator(
            collections[collection].mintAlloc
        ).getAvailableMintsForMembership(collection, membershipId);
        require(availableMints >= amount, "no mints available");
        require(
            IGenArtInterface(genartInterface).ownerOfMembership(membershipId) ==
                msg.sender,
            "sender must be owner of membership"
        );
    }

    /**
     * @dev Mint a token
     * @param collection contract address of the collection
     * @param membershipId owned GEN.ART membershipId
     */
    function mintOne(address collection, uint256 membershipId)
        external
        payable
        override
    {
        _checkMint(collection, 1);
        _checkAvailableMints(collection, membershipId, 1);
        IGenArtMintAllocator(collections[collection].mintAlloc).update(
            collection,
            membershipId,
            1
        );
        IGenArtERC721(collection).mint(msg.sender, membershipId);
        _splitPayment(collection);
    }

    /**
     * @dev Mint a token
     * @param collection contract address of the collection
     * @param amount amount of tokens to mint
     */
    function mint(address collection, uint256 amount)
        external
        payable
        override
    {
        // get all available mints for sender
        _checkMint(collection, amount);

        // get all memberships for sender
        address minter = _msgSender();
        uint256[] memory memberships = IGenArtInterface(genartInterface)
            .getMembershipsOf(minter);
        uint256 minted;
        uint256 i;
        IGenArtMintAllocator mintAlloc = IGenArtMintAllocator(
            collections[collection].mintAlloc
        );
        // loop until the desired amount of tokens was minted
        while (minted < amount && i < memberships.length) {
            // get available mints for membership
            uint256 membershipId = memberships[i];
            uint256 mints = mintAlloc.getAvailableMintsForMembership(
                collection,
                membershipId
            );
            // mint tokens with membership and stop if desired amount reached
            uint256 j;
            for (j = 0; j < mints && minted < amount; j++) {
                IGenArtERC721(collection).mint(minter, membershipId);
                minted++;
            }
            // update mint state once membership minted tokens
            mintAlloc.update(collection, membershipId, j);
            i++;
        }
        require(minted > 0, "no mints available");
        _splitPayment(collection);
    }

    /**
     * @dev Internal function to forward funds to a {GenArtPaymentSplitter}
     */
    function _splitPayment(address collection) internal {
        address paymentSplitter = GenArtCurated(genArtCurated)
            .getPaymentSplitterForCollection(collection);
        IGenArtPaymentSplitterV4(paymentSplitter).splitPayment{
            value: msg.value
        }();
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
        override
        returns (uint256)
    {
        return
            IGenArtMintAllocator(collections[collection].mintAlloc)
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
    ) external view override returns (uint256) {
        return
            IGenArtMintAllocator(collections[collection].mintAlloc)
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
        override
        returns (uint256)
    {
        return
            IGenArtMintAllocator(collections[collection].mintAlloc)
                .getMembershipMints(collection, membershipId);
    }

    /**
     * @dev Get collection pricing object
     * @param collection contract address of the collection
     */
    function getCollectionPricing(address collection)
        external
        view
        returns (Pricing memory)
    {
        return collections[collection];
    }
}