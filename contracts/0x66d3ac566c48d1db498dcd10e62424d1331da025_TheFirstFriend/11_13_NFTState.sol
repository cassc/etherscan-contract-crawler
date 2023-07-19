// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

abstract contract NFTState {
    // Custom Errors
    error WalletAlreadyMinted();
    error MintDisabled();
    error MaxQuantity();
    error OverLimit();
    error MaxSupply();
    error URIFrozen();
    error NoBots();

    // Constants
    /// @notice Max Supply for collection
    uint256 public constant TOTAL_SUPPLY = 100;
    /// @notice Wallet for ERC2981 royalties
    address public constant ADMIN_WALLET = 0xE644dDD529DeC81dc4A025161c41695bbd4Fa5D1;

    /// @notice Token name and symbol used in ERC721A constructor
    string internal constant NAME = "The First Friend";
    string internal constant SYMBOL = "FFF";

    // Bools
    bool internal baseURIFrozen;
    bool public mintEnabled;
    // Strings
    string public baseURI;
    // Mappings
    /// @dev Tracks mints per wallet
    mapping(address account => bool minted) internal claimed;
    // 07/06/23 12 PM EDT
    uint256 allowStart = 1688659200;
    // 07/06/23 2PM EDT
    uint256 openStart = 1688666400; 
}