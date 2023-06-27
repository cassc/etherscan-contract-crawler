//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./IDnaProvider.sol";

/// @title NFT contract for storing ERC721 tokens.
contract NFT is ERC721URIStorage, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    string internal _defaultCardCID;
    address internal _controller;

    event URIUpdated(uint256 itemId, string cardCid);

    modifier onlyController() {
        require(msg.sender == _controller, "Only the controller can access this method!");
        _;
    }

    constructor(string memory defaultCardCID, address nftOwner) ERC721("SatoshiQuest", "SQG") Ownable() {
        _defaultCardCID = defaultCardCID;
        _controller = msg.sender;
        transferOwnership(nftOwner);
    }

    /// @notice Mint a batch of Erc721 tokens.
    /// @param amountToMint The number of tokens to mint.
    /// @param newTokenOwner The owner of newly minted tokens.
    function mintBatch(uint256 amountToMint, address newTokenOwner) external onlyController returns (uint256[] memory) {
        uint256[] memory result = new uint256[](amountToMint);

        for (uint256 i = 0; i < amountToMint; i++) {
            _tokenIdTracker.increment();
            uint256 newItemId = _tokenIdTracker.current();
            result[i] = newItemId;
            _safeMint(newTokenOwner, newItemId);
            // NOTE: Don't set the token URI here. Keep it empty.
            emit URIUpdated(newItemId, _defaultCardCID);
        }
        return result;
    }

    /// @notice Update the URI of any ERC721 token.
    /// @dev Only the CID (without the `ipfs://` prefix).
    /// @dev only owner can call this method.
    /// @param itemId The ID of the ERC721 token.
    /// @param cid The CID of the token on IPFS.
    function updateURI(uint256 itemId, string calldata cid) external onlyController {
        emit URIUpdated(itemId, cid);
        _setTokenURI(itemId, cid); // By default the card is non-revealed
    }

    /// @notice Get the default card back CID used for the NFT contract.
    /// @return Only the string CID.
    function getDefaultCID() external view returns (string memory) {
        return _defaultCardCID;
    }

    /// @notice Only the controller can set the new controller
    function transferController(address controller) external onlyController {
        _controller = controller;
    }

    /// @notice Retrieve the current controller
    function getController() external view returns (address) {
        return _controller;
    }

    // ----- Specific overrides -----//

    /// @notice Return the ERC721 URI.
    /// @dev Will use the `_defaultCardCID` while the card has not been revealed.
    /// @param tokenId The ID of the ERC721 token.
    /// @return URI of a token.
    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        string memory base = _baseURI();

        if (IERC165(_controller).supportsInterface(type(IDnaProvider).interfaceId)) {
            // Check if the card has been revealed (dna will not be 0)
            uint256 dna = IDnaProvider(_controller).getDna(tokenId);
            if (dna > 0) {
                // Explicitly declare which super-class to use.
                // The card CIDs will get updated once card gets revealed.
                return ERC721URIStorage.tokenURI(tokenId);
            }
        }
        // The card is not revealed, return the default cardback.
        return string(abi.encodePacked(base, _defaultCardCID));
    }

    /// @notice See {IERC165-supportsInterface}.
    /// For details see ERC721URIStorage.supportsInterface.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        // Explicitly declare which super-class to use
        return ERC721Enumerable.supportsInterface(interfaceId);
    }

    /// @dev Hook that is called before any token transfer. This includes minting and burning.
    /// For details see ERC721URIStorage._beforeTokenTransfer.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        // Explicitly declare which super-class to use
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
    }

    /// @notice For details see ERC721URIStorage._burn.
    /// @dev Cannot simply remove this method because we must specify an override
    function _burn(uint256 tokenId) internal virtual override(ERC721URIStorage, ERC721) {
        // Explicitly declare which super-class to use
        ERC721URIStorage._burn(tokenId);
    }

    /// @notice Base URI for the NFT URIs.
    /// @dev If we don't store this separately, we end up covering 3 slots per every token URI.
    function _baseURI() internal pure virtual override returns (string memory) {
        return "ipfs://";
    }
}