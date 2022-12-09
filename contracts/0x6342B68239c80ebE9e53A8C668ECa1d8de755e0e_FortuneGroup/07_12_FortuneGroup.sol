/**  
 SPDX-License-Identifier: GPL-3.0
 Written by: Lacuna Strategies
*/

// Solidity Version
pragma solidity ^0.8.13;

// !==== Imports ==== //
import {DefaultOperatorFilterer} from "./operator-filter-registry/DefaultOperatorFilterer.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721A} from "erc721a/contracts/ERC721A.sol";

contract FortuneGroup is ERC721A, Ownable, ERC2981, DefaultOperatorFilterer {
        
    string  public              customBaseURI; // Variable to override Base URI

    uint256 public              maxSupply = 70; // Mximum tokens available
    uint256 public              publicSupply = 50; // Maximum tokens available to public
    uint256 public              publicMints; // Variable to track number of public mints
    uint256 public              mintPrice = 4 ether; // Price of each NFT in Ethereum

    bool    public              mintActive; // Variable to control whether mint is active
    
    constructor() ERC721A("Fortune Group", "FG") {}

    // !====== Overrides ====== ** //

    /**
     * @dev Add onlyAllowedOperatorApproval() to setApprovalForAll
     */
    function setApprovalForAll(address operator_, bool approved_) public override onlyAllowedOperatorApproval(operator_) {
        ERC721A.setApprovalForAll(operator_, approved_);
    }

    /**
     * @dev Add onlyAllowedOperatorApproval() to approve
     */
    function approve(address operator_, uint256 tokenId_) payable public override onlyAllowedOperatorApproval(operator_) {
        ERC721A.approve(operator_, tokenId_);
    }

    /**
     * @dev Add onlyAllowedOperator() to transferFrom
     */
    function transferFrom(address from_, address to_, uint256 tokenId_) payable public override onlyAllowedOperator(from_) {
        ERC721A.transferFrom(from_, to_, tokenId_);
    }

    /**
     * @dev Add onlyAllowedOperator() to safeTransferFrom
     */
    function safeTransferFrom(address from_, address to_, uint256 tokenId_) payable public override onlyAllowedOperator(from_) {
        ERC721A.safeTransferFrom(from_, to_, tokenId_);
    }

    /**
     * @dev Add onlyAllowedOperator() to safeTransferFrom w/ data parameter
     */
    function safeTransferFrom(address from_, address to_, uint256 tokenId_, bytes memory data_) payable public override onlyAllowedOperator(from_) {
        ERC721A.safeTransferFrom(from_, to_, tokenId_, data_);
    }

    /**
     * * Change Starting Token ID
     * @dev Set starting token ID to 1
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * * Override Base URI
     * @dev Overrides default base URI
     * @notice Default base URI is ""
     */     
    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }

    /**
     * * Interface Support Override
     * @dev Adds support for ERC2981 Royalty Contract
     */
    function supportsInterface(bytes4 interfaceId_) public view virtual override(ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return 
            ERC721A.supportsInterface(interfaceId_) || 
            ERC2981.supportsInterface(interfaceId_);
    }

    // !====== Admin Functions ====== //
    /**
     * * Toggle Active
     * @dev Toggle the active mint status
     */
    function toggleActive() external onlyOwner {
        mintActive = !mintActive;
    }

    /**
     * * Set Mint Price
     * @dev Set the mint price (ETH)
     * @param price_ The new mint price
     */
    function setMintPrice(uint256 price_) external onlyOwner {
        mintPrice = price_;
    }

    /**
     * * Set Maximum Supply
     * @dev Set the maximum supply
     * @param maxSupply_ The new maximum supply
     */
    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    /**
     * * Set Public Supply
     * @dev Set the public supply
     * @param publicSupply_ The new public supply
     */
    function setPublicSupply(uint256 publicSupply_) external onlyOwner {
        publicSupply = publicSupply_;
    }

    /**
     * * Set Base URI
     * @dev Set a custom Base URI for token metadata
     * @param newBaseURI_ The new URI to set as the base URI for token metadata
     */
    function setBaseURI(string calldata newBaseURI_) external onlyOwner {
        customBaseURI = newBaseURI_;
    }

    /**
     * * Withdraw Funds
     * @dev Allow owner to withdraw funds
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * * Set Default Royalty
     * @dev Sets the royalty information that all ids in this contract will default to.
     * @param receiver_ The address to receive royalty payments
     * @param feeNumerator_ The number of basis points to pay as royalty
     *
     * Requirements:
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function setDefaultRoyalty(address receiver_, uint96 feeNumerator_) external onlyOwner {
        _setDefaultRoyalty(receiver_, feeNumerator_);
    }

    /**
     * * Delete Default Royalty
     * @dev Removes default royalty information.
     */
    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    /**
     * * Set Token Royalty
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     * @param tokenId_ The token ID being assigned royalty information
     * @param receiver_ The address to receive royalty payments
     * @param feeNumerator_ The number of basis points to pay as royalty
     *
     * Requirements:
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function setTokenRoyalty(uint256 tokenId_, address receiver_, uint96 feeNumerator_) external onlyOwner {
        _setTokenRoyalty(tokenId_, receiver_, feeNumerator_);
    }

    /**
     * * Reset Token Royalty
     * @dev Resets royalty information for the token id back to the global default.
     * @param tokenId_ the token id being unassigned royalty information
     */
    function resetTokenRoyalty(uint256 tokenId_) external onlyOwner {
        _resetTokenRoyalty(tokenId_);
    }

    // !====== Minting Functions ====== //

    /**
     * * Mint Public Sale Tokens
     * @dev Minting function for tokens available during the Public Sale phase
     */
    function mint() external payable {
        // Verify minting is active
        require(mintActive, "Minting Not Active!");
        // Verify origin
        require(tx.origin == msg.sender, "Caller is Contract!");
        // Verify quantity minted has not exceeded max allowed per wallet
        require(_numberMinted(msg.sender) < 1, "Exceeded Max Per Wallet!");
        // Verify public supply has not been exceeded
        require(publicMints < publicSupply, "Exceeded Public Supply!");
        // Verify payment
        require(msg.value == mintPrice, "Incorrect Payment!");

        publicMints += 1;

        // Mint tokens
        _mint(msg.sender, 1);
    }

    /**
     * * Owner Mint to Address (Airdrop)
     * @dev Allow owner to mint up to Max Supply to specific address(es)
     * @param to_ Address to receive the tokens
     * @param qty_ The number of tokens being minted
     */
    function airdrop(address to_, uint256 qty_) external onlyOwner {
        // Owner can mint up to Max Supply at any time
        require(_totalMinted() + qty_ < maxSupply + 1, "Exceeded Max Supply!");

        // Mint tokens
        _mint(to_, qty_);
    }

}