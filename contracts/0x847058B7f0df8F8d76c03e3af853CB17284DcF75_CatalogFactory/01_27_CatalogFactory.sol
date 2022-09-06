// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./Catalog.sol";
import "./Platform.sol";

contract CatalogFactory is Platform {
    /// Catalog Curation Seed
    address public implementation;
    /// Zora Asks V1.1 Module Address
    address public zoraAsksV1_1;
    /// Zora Transfer Helper Address
    address public zoraTransferHelper;
    /// Zora Module Manager Address
    address public zoraModuleManager;

    constructor(
        address _implementation,
        address _platformFeeRecipient,
        uint256 _platformFee,
        address _zoraAsksV1_1,
        address _zoraTransferHelper,
        address _zoraModuleManager
    ) {
        implementation = _implementation;
        platformFeeRecipient = _platformFeeRecipient;
        platformFee = _platformFee;
        zoraAsksV1_1 = _zoraAsksV1_1;
        zoraTransferHelper = _zoraTransferHelper;
        zoraModuleManager = _zoraModuleManager;
    }

    /// Event fired when Catalog is created
    event CatalogCreated(address creator, address indexed contractAddress);

    /// @notice Creates a new Catalog contract.
    /// @param _curatorName of curation platform
    /// @param _ipfs URI of the music metadata (ipfs://bafkreidfgdtzedh27qpqh2phb2r72ccffxnyoyx4fibls5t4jbcd4iwp6q)
    /// @param _askPrice The sale price (wei)
    /// @param _sellerFundsRecipient The address to send funds to once the NFT is sold
    /// @param _findersFeeBps The bps of the sale amount to be sent to the referrer of the sale
    function createCatalog(
        string memory _curatorName,
        string memory _ipfs,
        uint256 _askPrice,
        address _sellerFundsRecipient,
        uint16 _findersFeeBps
    ) public payable hasPlatformFee returns (address) {
        address clone = Clones.clone(implementation);
        emit CatalogCreated(msg.sender, address(clone));
        Catalog(address(clone)).initialize(
            _curatorName,
            "MUSIC",
            zoraAsksV1_1,
            zoraTransferHelper,
            zoraModuleManager
        );
        Catalog(address(clone)).simpleMint(
            msg.sender,
            _ipfs,
            _askPrice,
            _sellerFundsRecipient,
            _findersFeeBps
        );
        Catalog(address(clone)).transferOwnership(msg.sender);
        return address(clone);
    }
}