// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "../../auction/interfaces/IAuctionManager.sol";
import "../../royaltyManager/interfaces/IRoyaltyManager.sol";

/**
 * @notice Instance of MultipleEditions contract (multiple fixed size editions)
 * @author highlight.xyz
 */
contract MultipleEditions is Proxy {
    /**
     * @notice Initialize MultipleEditions instance with first edition, and potentially auction
     * @param implementation_ ERC721Editions implementation
     * @param initializeData Data to initialize instance
     * @ param creator Creator/owner of contract
     * @ param _contractURI Contract metadata
     * @ param _name Name of token edition
     * @ param _symbol Symbol of the token edition
     * @ param metadataRendererAddress Contract returning metadata for each edition
     * @ param trustedForwarder Trusted minimal forwarder
     * @ param initialMinters Initial minters to register
     * @ param useMarketplaceFiltererRegistry Denotes whether to use marketplace filterer registry
     * @ param _observability Observability contract address
     * @param _editionInfo Edition metadata info
     * @ param IEditionsMetadataRenderer.TokenEditionInfo
     * @param editionSize Edition size
     * @param _editionTokenManager Edition's token manager
     * @param editionRoyalty Edition's royalty
     * @param auctionData Data to create auction
     * @ param auctionManagerAddress AuctionManager address. Auction not created if this is the null address
     * @ param auctionId Auction ID
     * @ param auctionCurrency Auction currency
     * @ param auctionPaymentRecipient Auction payment recipient
     * @ param auctionEndTime Auction end time
     */
    constructor(
        address implementation_,
        bytes memory initializeData,
        bytes memory _editionInfo,
        uint256 editionSize,
        address _editionTokenManager,
        IRoyaltyManager.Royalty memory editionRoyalty,
        bytes memory auctionData
    ) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = implementation_;
        Address.functionDelegateCall(implementation_, abi.encodeWithSignature("initialize(bytes)", initializeData));

        if (_editionInfo.length > 0) {
            // create edition
            Address.functionDelegateCall(
                implementation_,
                abi.encodeWithSignature(
                    "createEdition(bytes,uint256,address,(address,uint16))",
                    _editionInfo,
                    editionSize,
                    _editionTokenManager,
                    editionRoyalty
                )
            );
        }

        if (auctionData.length > 0) {
            // if creating auction for this edition, validate that edition size was 1
            require(editionSize == 1, "Invalid edition size for auction");

            (
                address auctionManagerAddress,
                bytes32 auctionId,
                address auctionCurrency,
                address payable auctionPaymentRecipient,
                uint256 auctionEndTime
            ) = abi.decode(auctionData, (address, bytes32, address, address, uint256));

            IAuctionManager.EnglishAuction memory auction = IAuctionManager.EnglishAuction(
                address(this),
                auctionCurrency,
                msg.sender,
                auctionPaymentRecipient,
                auctionEndTime,
                0,
                true,
                IAuctionManager.AuctionState.LIVE_ON_CHAIN
            );

            // edition id guaranteed to be = 0
            IAuctionManager(auctionManagerAddress).createAuctionForNewEdition(auctionId, auction, 0);
        }
    }

    /**
     * @notice Return the contract type
     */
    function contractType() external view returns (string memory) {
        return "MultipleEditions";
    }

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal view override returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }
}