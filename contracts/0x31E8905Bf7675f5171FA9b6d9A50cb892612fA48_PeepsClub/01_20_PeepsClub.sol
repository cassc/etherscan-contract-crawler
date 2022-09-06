// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title Peeps Club
/// @author MilkyTaste @ Ao Collaboration Ltd.
/// https://peeps.club
/// Peeps of the World.

import "./ERC721Enumerable.sol";
import "./IPeepsPassport.sol";
import "./Payable.sol";
import "./Signable.sol";

contract PeepsClub is ERC721Enumerable, Payable, Signable {
    using Strings for uint256;

    IPeepsPassport public passportAddr;

    string public baseURI = "https://api.peeps.club/peep/";

    mapping(address => uint32) public utilityNonce; // Prevent replay attacks

    constructor() ERC721Enumerable("Peeps Club", "PEEP") Payable(650) {}

    //
    // Modifiers
    //

    /**
     * Checks for a valid nonce against the account, and increments it after the call.
     * @param account The caller.
     * @param nonce The expected nonce.
     */
    modifier useNonce(address account, uint32 nonce) {
        require(utilityNonce[account] == nonce, "PeepsPassport: Nonce not valid");
        _;
        utilityNonce[account]++;
    }

    //
    // Mint
    //

    /**
     * Mint a Peep using a passport.
     * @param nonce A one time use number to prevent replay attacks.
     * @param signature A signed validation from the server.
     * @param uri The metadata location.
     */
    function passportMint(
        uint32 nonce,
        bytes calldata signature,
        uint64 uri
    ) external useNonce(msg.sender, nonce) signed(abi.encodePacked(msg.sender, nonce, uri), signature) {
        passportAddr.burn(msg.sender, 1);
        // Mint next available token
        _safeMint(msg.sender, _ownerInfo.length + 1, uri, "");
    }

    //
    // Admin
    //

    /**
     * Sets Peeps Passport address.
     * @param passportAddr_ The peeps passport address.
     */
    function setPassportAddr(address passportAddr_) external onlyOwner {
        passportAddr = IPeepsPassport(passportAddr_);
    }

    /**
     * Sets base URI.
     * @param baseURI_ The base URI.
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /**
     * Updates the metadata location for a peep.
     * @param tokenId The peep token ID.
     * @param uri The new metadata location.
     */
    function setPeepURI(uint256 tokenId, uint64 uri) external onlyOwner {
        _ownerInfo[tokenId].aux = uri;
    }

    //
    // Views
    //

    /**
     * Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     * @param tokenId The token id.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_ownerInfo[tokenId].aux), ".json"));
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return ERC721Enumerable.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}