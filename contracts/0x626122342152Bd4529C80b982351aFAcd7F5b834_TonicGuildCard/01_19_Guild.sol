// ╔════╗╔═══╗╔═╗ ╔╗╔══╗╔═══╗
// ║╔╗╔╗║║╔═╗║║║╚╗║║╚╣╠╝║╔═╗║
// ╚╝║║╚╝║║ ║║║╔╗╚╝║ ║║ ║║ ╚╝
//   ║║  ║║ ║║║║╚╗║║ ║║ ║║ ╔╗
//  ╔╝╚╗ ║╚═╝║║║ ║║║╔╣╠╗║╚═╝║
//  ╚══╝ ╚═══╝╚╝ ╚═╝╚══╝╚═══╝
// SPDX-License-Identifier: MIT
// Copyright (c) TONIC LABS, INC.

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";

contract TonicGuildCard is
    Initializable,
    ERC721Upgradeable,
    ERC721RoyaltyUpgradeable,
    ERC721EnumerableUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;
    bool private _publicMintActive;

    uint256 public maxSupply;
    uint256 public price;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC721_init("Tonic Community Card", "TCC");
        __ERC721Enumerable_init();
        __Pausable_init();
        __Ownable_init();

        // Set initial variables;
        maxSupply = 2000;
        price = 0 ether;
        _publicMintActive = false;
    }

    /*
     * Token Metadata Base URI
     * Token URIs are created as _baseURI()+tokenID
     */
    function _baseURI() internal pure override returns (string memory) {
        return "https://meta.tonic.xyz/community/";
    }

    /*
     * Contract Metadata Information URI
     */
    function contractURI() external pure returns (string memory) {
        return "https://meta.tonic.xyz/community/collection";
    }

    /*
     * Pause Transfers and Minting
     */
    function pause() external onlyOwner {
        _pause();
    }

    /*
     * Unpause Transfers and Minting
     */
    function unpause() external onlyOwner {
        _unpause();
    }


    /*
     * Pause Public (Ungated) Minting
     */
    function pausePublicMint() external onlyOwner {
        _publicMintActive = false;
    }

    /*
     * Unpause Public (Ungated) Minting
     */
    function activatePublicMint() external onlyOwner {
        _publicMintActive = true;
    }

    /*
     * Internal Minting Function
     */
    function _mintAndIncrement(address to) private whenNotPaused {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    /*
     * Mint an NFT to `destination` using the owner address
     */
    function adminMint(address destination) external onlyOwner {
        require(totalSupply() + 1 <= maxSupply, "Mint exceeds max supply");
        _mintAndIncrement(destination);
    }

    function adminMintBulk(address[] calldata addresses)
        external
        onlyOwner
    {
        require(
            totalSupply() + addresses.length <= maxSupply,
            "Mint exceeds max supply"
        );
        for (uint8 i = 0; i < addresses.length; i++) {
            address destination = addresses[i];
            _mintAndIncrement(destination);
        }
    }

    /*
     * Set secondary market royalties using the EIP2981 standard
     * Royalties will be sent to the supplied `reciever` address
     * The royalty is calcuated feeNumerator / 10000
     * A 5% royalty, would use a feeNumerator of 500 (500/10000=.05)
     */
    function setRoyalties(address reciever, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(reciever, feeNumerator);
    }

    /*
     * Increase the maximum supply of tokens
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(_maxSupply >= totalSupply(), "max is less than totalSupply");
        maxSupply = _maxSupply;
    }

    /*
     * Set the price of one NFT for public and allowList minting
     * Price is specified as a bignumber gwei value
     * This value can be derived using standard tools (eg. using ethers.utils.parseEther)
     */
    function setPrice(uint256 _price) external onlyOwner {
        require(_price > 0, "Price cannot be 0");
        price = _price;
    }

    /*
     * Mint 1 NFT
     * msg.value must be at least price * quantity
     */
    function publicMint() external payable {
        require(_publicMintActive, "Public mint is not active");
        require(
            totalSupply() + 1 <= maxSupply,
            "Purchase would exceed max tokens"
        );
        require(price <= msg.value, "Ether value sent is not correct");

        _mintAndIncrement(msg.sender);
    }

    /*
     * Withdraw to owner address
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            ERC721RoyaltyUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721RoyaltyUpgradeable)
    {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}