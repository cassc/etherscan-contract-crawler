// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IWhitelist.sol";
import "../interfaces/IRoyaltyAwareNFT.sol";

/// @title BaseEnigmaNFT721
///
/// @dev This contract is a ERC721 burnable and upgradable based in openZeppelin v3.4.0.
///         Be careful when upgrade, you must respect the same storage.

abstract contract BaseEnigmaNFT721 is IRoyaltyAwareNFT, ERC721BurnableUpgradeable, OwnableUpgradeable {
    /* Storage */
    //mapping for token royaltyFee
    mapping(uint256 => uint256) private _royaltyFee;

    //mapping for token creator
    mapping(uint256 => address) private _creator;

    //token id counter, increase by 1 for each new mint
    uint256 public tokenCounter;

    //whitelist with logic to allow token transfers
    IWhitelist public whitelist;

    /* events */
    event URI(string value, uint256 indexed id);
    event TokenBaseURI(string value);

    /* functions */

    /**
     * @notice Initialize NFT721 contract.
     *
     * @param name_ the token name
     * @param symbol_ the token symbol
     * @param tokenURIPrefix_ the toke base uri
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory tokenURIPrefix_
    ) external initializer {
        __ERC721_init(name_, symbol_);
        __ERC721Burnable_init();
        __Ownable_init();

        tokenCounter = 1;
        _setBaseURI(tokenURIPrefix_);
    }

    /// oz-upgrades-unsafe-allow constructor
    // solhint-disable-next-line
    constructor() initializer {}

    /**
     * @notice get the royalty fee of a token
     *
     * @param tokenId the token id
     * @return the royalty fee seted to the token
     */
    function royaltyFee(uint256 tokenId) external view virtual override returns (uint256) {
        return _royaltyFee[tokenId];
    }

    /**
     * @notice Get the creator of given tokenID.
     * @param tokenId ID of the Token.
     * @return creator of given ID.
     */
    function getCreator(uint256 tokenId) external view virtual override returns (address) {
        return _creator[tokenId];
    }

    /**
     * @notice Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     * @param baseURI_ the new base uri
     */
    function _setBaseURI(string memory baseURI_) internal virtual override {
        super._setBaseURI(baseURI_);
        emit TokenBaseURI(baseURI_);
    }

    /**
     * @notice Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to set its URI
     * @param _tokenURI string URI to assign
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual override {
        super._setTokenURI(tokenId, _tokenURI);
        emit URI(_tokenURI, tokenId);
    }

    /**
     * @notice call safe mint function and set token creator and royalty fee
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        uint256 fee
    ) internal virtual {
        _creator[tokenId] = msg.sender;
        _royaltyFee[tokenId] = fee;
        super._safeMint(to, tokenId, "");
    }

    /**
     * @notice call transfer fucntion after check whitelist allowance
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        if (from != _msgSender()) {
            // Check that the calling account has the transfer role
            require(whitelist.canTransfer(msg.sender), "Transfer not approved");
        }
        super._transfer(from, to, tokenId);
    }

    /**
     * @notice external function to set the base URI for all token IDs
     * @param baseURI_ the new base uri
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _setBaseURI(baseURI_);
    }

    /**
     * @notice Set a whitelist with the logic to allow transfer NFTs
     * @param _whitelist The whitelist contract address
     */
    function setWhitelist(IWhitelist _whitelist) external onlyOwner {
        whitelist = _whitelist;
    }
}