// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AdventureERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/// @title DigiDaigakuSpirits contract
/// @dev Extends ERC721 Non-Fungible Token Standard basic implementation and includes adventure/quest staking behaviors
contract DigiDaigakuSpirits is AdventureERC721, ERC2981 {
    using Strings for uint256;

    string public baseTokenURI;
    string public suffixURI = ".json";
    uint256 private nextTokenId = 1;

    uint96 public constant MAX_ROYALTY_FEE_NUMERATOR = 1000;
    uint256 public constant MAX_SUPPLY = 2022;

    /// @dev Emitted when base URI is set.
    event BaseURISet(string baseTokenURI);

    /// @dev Emitted when suffix URI is set.
    event SuffixURISet(string suffixURI);

    /// @dev Emitted when royalty is set.
    event RoyaltySet(address receiver, uint96 feeNumerator);

    constructor() ERC721("DigiDaigakuSpirits", "DISP") {}

    /// @notice Owner bulk mint to airdrop
    function airdropMint(address[] calldata to) external onlyOwner {
        uint256 batchSize = to.length;
        uint256 tokenIdToMint = nextTokenId;
        require(tokenIdToMint + batchSize - 1 <= MAX_SUPPLY, "Supply cannot exceed 2022");
        nextTokenId = nextTokenId + batchSize;

        unchecked {
            for (uint256 i = 0; i < batchSize; ++i) {
                _mint(to[i], tokenIdToMint + i);
            }
        }
    }

    /// @dev Required to return baseTokenURI for tokenURI
    function _baseURI()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return baseTokenURI;
    }

    /// @notice Sets base URI
    function setBaseURI(string memory baseTokenURI_) external onlyOwner {
        baseTokenURI = baseTokenURI_;

        emit BaseURISet(baseTokenURI_);
    }

    /// @notice Sets suffix URI
    function setSuffixURI(string memory suffixURI_) external onlyOwner {
        suffixURI = suffixURI_;

        emit SuffixURISet(suffixURI_);
    }

    /// @notice Sets royalty information
    function setRoyaltyInfo(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        require(feeNumerator <= MAX_ROYALTY_FEE_NUMERATOR, "Exceeds max royalty fee");
        _setDefaultRoyalty(receiver, feeNumerator);

        emit RoyaltySet(receiver, feeNumerator);
    }

    /// @notice Returns tokenURI if baseURI is set
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), suffixURI))
            : "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (AdventureERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}