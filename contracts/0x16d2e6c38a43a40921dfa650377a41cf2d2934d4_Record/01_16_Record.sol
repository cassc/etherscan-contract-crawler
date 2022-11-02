// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin/token/ERC721/ERC721.sol";
import "openzeppelin/interfaces/IERC2981.sol";
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/security/ReentrancyGuard.sol";
import { Counters } from "openzeppelin/utils/Counters.sol";
import { MerkleProof } from "openzeppelin/utils/cryptography/MerkleProof.sol";

contract Record is ERC721, IERC2981, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;

    /*** ===== Structs ===== ***/
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyAmount;
    }

    struct MintData {
        string metadataURI;
        address receiver;
        uint96 royaltyAmount;
    }

    /*** ===== Storage ===== ***/
    mapping (uint256 => RoyaltyInfo) public royalties_;
    mapping (uint256 => address) public creators_;
    mapping (uint256 => string) public metadatas_;

    Counters.Counter private tokenId_;

    /*** ===== Events ===== ***/
    event RecordPressed(address indexed creator, uint256 indexed tokenId);

    /*** ===== Constructor ===== ***/
    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol){}

    /*** ===== Interface Detection ===== ***/
    /**
     * @dev See {ERC165} 
     * @param interfaceId interface id to check compatibility for
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /*** ===== Metadata ===== ***/
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * @param tokenId reference token id
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        return metadatas_[tokenId];
    }

    /*** ===== Royalties ===== ***/
    /**
     * @dev See {EIP-2981}. TokenId not needed since royalties will be the same for each token
     * @param _salePrice sale price to calculate recipient shares
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        public
        view
        virtual
        override
        returns (address, uint256)
    {
        uint256 royaltyAmount = (_salePrice * royalties_[_tokenId].royaltyAmount) / 10000;

        return (royalties_[_tokenId].receiver, royaltyAmount);
    }


    /*** ===== Mint ===== ***/
    function mint(MintData calldata _mintData) public nonReentrant {
        tokenId_.increment();
        uint256 newTokenId = tokenId_.current();
        royalties_[newTokenId] = RoyaltyInfo(_mintData.receiver, _mintData.royaltyAmount);
        creators_[newTokenId] = msg.sender;
        metadatas_[newTokenId] = _mintData.metadataURI;

        emit RecordPressed(msg.sender, newTokenId);
        _safeMint(msg.sender, newTokenId);
    }

    /*** ===== Burn bb burn ===== ***/
    function burn(uint256 _tokenId) external {
        require(msg.sender == ownerOf(_tokenId), "Must be owner");
        _burn(_tokenId);
    }
}