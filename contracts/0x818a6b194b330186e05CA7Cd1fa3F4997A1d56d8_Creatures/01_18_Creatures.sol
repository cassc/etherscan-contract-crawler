// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Creatures is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    Ownable,
    DefaultOperatorFilterer
{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => bool) claimedMoonwalker; // records if moonwalkers have been claimed
    address public tosContract;
    string public baseURI;
    uint256 public MAX_SUPPLY = 8888;
    bool public isMintActive;

    constructor() ERC721("Creatures", "CRT") {}

    // ==== MINT FUNCTIONS ====

    function _mintInternal() internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    function teamMint(uint256 _quantity)
        public
        onlyOwner
        withinQuantity(_quantity)
    {
        for (uint256 i = 0; i < _quantity; i++) {
            _mintInternal();
        }
    }

    function publicMint(uint256[] calldata _tokenIds)
        external
        withinQuantity(_tokenIds.length)
        mintActive
    {
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            require(
                !claimedMoonwalker[_tokenIds[i]],
                "Moonwalker already claimed"
            );
            require(
                TOSContract(tosContract).ownerOf(_tokenIds[i]) == msg.sender,
                "You do not own the moon walker"
            );
            _mintInternal();
            claimedMoonwalker[_tokenIds[i]] = true;
        }
    }

    // ==== BURN ====

    function batchBurn(uint256[] calldata _tokenIds) external {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _burn(_tokenIds[i]);
        }
    }

    // ==== SETTERS ====

    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setIsMintActive(bool _isActive) external onlyOwner {
        isMintActive = _isActive;
    }

    function setTosContract(address _address) external onlyOwner {
        tosContract = _address;
    }

    function setMaxSupply(uint256 _supply) external onlyOwner {
        MAX_SUPPLY = _supply;
    }

    // ==== GETTERS ====

    function getHasMinted(uint256[] calldata _tokens)
        external
        view
        returns (bool[] memory)
    {
        bool[] memory hasMinted = new bool[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            hasMinted[i] = claimedMoonwalker[_tokens[i]];
        }
        return hasMinted;
    }

    // ==== MODIFIER ====

    modifier withinQuantity(uint256 _qty) {
        require(totalSupply() + _qty <= MAX_SUPPLY, "Exceed max supply");
        _;
    }

    modifier mintActive() {
        require(isMintActive, "Mint not active");
        _;
    }

    // ==== OVERRIDES ====

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokenURI(uint256 _id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_id), "Token does not exist");
        return
            string(abi.encodePacked(baseURI, Strings.toString(_id), ".json"));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}

interface TOSContract {
    function ownerOf(uint256) external view returns (address);
}