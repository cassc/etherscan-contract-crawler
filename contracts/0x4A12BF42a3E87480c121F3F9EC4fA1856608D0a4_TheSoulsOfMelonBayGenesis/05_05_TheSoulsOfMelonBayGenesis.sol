// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ERC721A} from "./ERC721A.sol";
import {Ownable} from "./Ownable.sol";

// Errors
error SaleNotActive();
error InsufficientPayment();
error SupplyExceeded();
error WalletLimitExceeded();
error FirstDropSupplyExceeded();
error WithdrawFailed();
error ReservedNotReady();

contract TheSoulsOfMelonBayGenesis is Ownable, ERC721A {
    enum SaleStates {
        CLOSED,
        PUBLIC_FIRST_DROP,
        PUBLIC_SECOND_DROP
    }

    /**
     * Structure that holds the minting data of each address for each drop.
     */
    struct TokenData {
        uint8 firstDropMinted;
        uint8 secondDropMinted;
    }

    // Mapping associating each address to its respective TokenData.
    mapping(address => TokenData) private _tokenData;

    // Number of NFTs users can mint in the public sale
    uint256 public constant PUBLIC_MINTS_PER_WALLET = 3;

    // Price for the public mint
    uint256 public publicPrice = 0.04 ether;

    // Total supply of the collection
    uint256 public maxSupply = 100;

    // First drop supply
    uint256 public firstDropSupply = 76;

    // Current sale state
    SaleStates public saleState;

    // Base metadata uri
    string private _baseTokenURI;

    /**
     * Contract constructor. Set the name and symbol for the NFT and initialize the baseURI.
     * @param name Name of the NFT
     * @param symbol Symbol for the NFT
     * @param baseURI Base string that will be used to form the metadata URI of each token
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI
    ) ERC721A(name, symbol) {
        _baseTokenURI = baseURI;
    }

    /**
     * Function to mint one or more tokens.
     * @param qty The quantity of tokens to be minted
     */
    function mint(uint8 qty) external payable {
        if (saleState == SaleStates.CLOSED) revert SaleNotActive();
        if (qty > PUBLIC_MINTS_PER_WALLET) revert WalletLimitExceeded();
        if (msg.value < publicPrice * qty) revert InsufficientPayment();
        if (_totalMinted() + qty > maxSupply) revert SupplyExceeded();

        TokenData storage tokenData = _tokenData[msg.sender];

        if (saleState == SaleStates.PUBLIC_FIRST_DROP) {
            if (_totalMinted() + qty > firstDropSupply) revert FirstDropSupplyExceeded();
            if (tokenData.firstDropMinted + qty > PUBLIC_MINTS_PER_WALLET) revert WalletLimitExceeded();
            tokenData.firstDropMinted += qty;
        }

        if (saleState == SaleStates.PUBLIC_SECOND_DROP) {
            if (tokenData.secondDropMinted + qty > PUBLIC_MINTS_PER_WALLET) revert WalletLimitExceeded();
            tokenData.secondDropMinted += qty;
        }

        _mint(msg.sender, qty);
    }

    /**
     * Owner-only function to distribute a token after the first drop, reserved for specific use.
     * @param to Address where to send the token
     */
    function dropReserved(address to) external onlyOwner {
        if (_totalMinted() != firstDropSupply) revert ReservedNotReady();
        _mint(to, 1);
    }

    // =========================================================================
    //                             Mint Settings
    // =========================================================================

    /**
     * Owner-only function to set the current sale state.
     * @param _saleState New sale state
     */
    function setSaleState(SaleStates _saleState) external onlyOwner {
        saleState = _saleState;
    }

    /**
     * Owner-only function to withdraw funds in the contract to a destination address.
     * @param receiver Destination address to receive funds
     */
    function withdrawFunds(address receiver) external onlyOwner {
        (bool sent,) = receiver.call{value: address(this).balance}("");
        if (!sent) {
            revert WithdrawFailed();
        }
    }

    // =========================================================================
    //                                 Metadata
    // =========================================================================

    /**
     * Owner-only function to set the base uri used for metadata.
     * @param baseURI uri to use for metadata
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * Function to retrieve the metadata uri for a given token. Reverts for tokens that don't exist.
     * @param tokenId Token Id to get metadata for
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : "";
    }
}
