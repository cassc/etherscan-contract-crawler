// SPDX-License-Identifier: CC-BY-NC-ND-4.0

pragma solidity ^0.8.10;
pragma abicoder v2;

// @dev This should be used for drops where minting starts at 0/1 and the collector mints themselves.
interface INA721DropStandard {

    // ---
    // Events
    // ---

    event Mint(uint256 indexed tokenId, address indexed owner); // @todo(iolson): Add hash to the message for future on-chain generative stuff.
    event Payout(uint256 amount, address payee);

    // ---
    // Struct
    // ---

    // @dev DropOptions to make setup of contract a lot easier.
    struct DropOptions {
        string metadataBaseUri;
        uint256 mintPriceInWei;
        uint256 maxQuantityPerTransaction;
        bool autoPayout;
        bool active;
        bool presaleMint;
        bool presaleActive;
        address imnotArtPayoutAddress;
        address artistPayoutAddress;
        bool maxPerWalletEnabled;
        uint256 maxPerWalletQuantity;
    }

    // ---
    // Functions
    // ---

    function mint(uint256 quantity) external payable;

    function updateImNotArtPayoutAddress(address payoutAddress) external;

    function updateArtistPayoutAddress(address payoutAddress) external;

    function bulkAddPresaleWallets(address[] memory presaleWallets) external;

    function addPresaleWallet(address presaleWallet) external;

    function removePresaleWallet(address presaleWallet) external;
}