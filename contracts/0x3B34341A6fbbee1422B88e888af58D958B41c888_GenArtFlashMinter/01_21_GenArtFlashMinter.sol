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
 * @dev GEN.ART Flash Minter
 * Admin for collections deployed on {GenArtCurated}
 */

contract GenArtFlashMinter is IGenArtMinter, GenArtAccess {
    struct Pricing {
        uint256 startTime;
        uint256 price;
        uint256[] pooledMemberships;
        address mintAlloc;
    }

    address public genArtCurated;
    address public genartInterface;
    address public payoutAddress;
    address public membershipLendingPool;
    uint256 public lendingFeePercentage = 0;

    mapping(address => Pricing) public collections;

    event PricingSet(
        address collection,
        uint256 startTime,
        uint256 price,
        address mintAlloc
    );

    constructor(
        address genartInterface_,
        address genartCurated_,
        address membershipLendingPool_,
        address payoutAddress_
    ) GenArtAccess() {
        genartInterface = genartInterface_;
        genArtCurated = genartCurated_;
        membershipLendingPool = membershipLendingPool_;
        payoutAddress = payoutAddress_;
    }

    /**
     * @dev Not need
     * Note DO NOT USE
     */
    function addPricing(address, address) external override onlyAdmin {
        revert("not impelmented");
    }

    /**
     * @dev Set pricing for collection
     * @param collection contract address of the collection
     * @param startTime start time for minting
     * @param price price per token
     * @param mintAllocContract contract address of {GenArtMintAllocator}
     */
    function setPricing(
        address collection,
        uint256 startTime,
        uint256 price,
        address mintAllocContract
    ) external onlyAdmin {
        require(
            collections[collection].startTime < block.timestamp,
            "mint already started for collection"
        );
        require(startTime > block.timestamp, "startTime too early");
        collections[collection].startTime = startTime;
        collections[collection].price = price;
        collections[collection].mintAlloc = mintAllocContract;
        collections[collection].pooledMemberships = IGenArtInterface(
            genartInterface
        ).getMembershipsOf(membershipLendingPool);

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
        return
            (collections[collection].price * (1000 + lendingFeePercentage)) /
            1000;
    }

    /**
     * @dev Helper function to check for mint price and start date
     */
    function _checkMint(address collection) internal view {
        require(msg.value >= getPrice(collection), "wrong amount sent");

        require(
            collections[collection].pooledMemberships.length > 0,
            "no memberships available"
        );

        require(
            collections[collection].startTime != 0,
            "falsh loan mint not started yet"
        );
        require(
            collections[collection].startTime <= block.timestamp,
            "mint not started yet"
        );
    }

    /**
     * @dev Helper function to check for available mints for sender
     */
    function _checkAvailableMints(address collection, uint256 membershipId)
        internal
        view
    {
        require(
            IGenArtInterface(genartInterface).ownerOfMembership(membershipId) ==
                membershipLendingPool,
            "not a vaulted membership"
        );

        uint256 availableMints = IGenArtMintAllocator(
            collections[collection].mintAlloc
        ).getAvailableMintsForMembership(collection, membershipId);

        require(availableMints >= 1, "no mints available");
    }

    /**
     * @dev Mint a token
     * @param collection contract address of the collection
     * @param "" any uint256
     */
    function mintOne(address collection, uint256) external payable override {
        _checkMint(collection);
        uint256 membershipId = collections[collection].pooledMemberships[
            collections[collection].pooledMemberships.length - 1
        ];
        collections[collection].pooledMemberships.pop();
        _checkAvailableMints(collection, membershipId);
        _mint(collection, membershipId);
        _splitPayment(collection);
    }

    /**
     * @dev Internal function to mint tokens on {IGenArtERC721} contracts
     */
    function _mint(address collection, uint256 membershipId) internal {
        IGenArtMintAllocator(collections[collection].mintAlloc).update(
            collection,
            membershipId,
            1
        );
        IGenArtERC721(collection).mint(msg.sender, membershipId);
    }

    /**
     * @dev Only one token possible to mint
     * Note DO NOT USE
     */
    function mint(address, uint256) external payable override {
        revert("Not implemented");
    }

    /**
     * @dev Internal function to forward funds to a {GenArtPaymentSplitter}
     */
    function _splitPayment(address collection) internal {
        address paymentSplitter = GenArtCurated(genArtCurated)
            .getPaymentSplitterForCollection(collection);
        uint256 amount = (msg.value / (1000 + lendingFeePercentage)) * 1000;
        IGenArtPaymentSplitterV4(paymentSplitter).splitPayment{value: amount}();
    }

    /**
     * @dev Set the flash lending fee
     */
    function setMembershipLendingFee(uint256 lendingFeePercentage_)
        external
        onlyAdmin
    {
        lendingFeePercentage = lendingFeePercentage_;
    }

    /**
     * @dev Set membership pool address
     */
    function setMembershipLendingPool(address membershipLendingPool_)
        external
        onlyAdmin
    {
        membershipLendingPool = membershipLendingPool_;
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
     * @dev Set the payout address for the flash lending fees
     */
    function setPayoutAddress(address payoutAddress_) external onlyGenArtAdmin {
        payoutAddress = payoutAddress_;
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

    /**
     * @dev Widthdraw contract balance
     */
    function withdraw() external onlyAdmin {
        payable(payoutAddress).transfer(address(this).balance);
    }
}