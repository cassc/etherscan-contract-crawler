// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Idol is ERC721A, ERC2981, DefaultOperatorFilterer, Ownable {
    error Locked();

    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
    event TokenLocked(
        uint256 indexed tokenId,
        address indexed approvedContract
    );
    event TokenUnlocked(
        uint256 indexed tokenId,
        address indexed approvedContract
    );

    uint256 public immutable MAX_SUPPLY;
    string private baseTokenURI;
    mapping(uint256 => bool) public lockedTokens;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply
    ) ERC721A(_name, _symbol) {
        MAX_SUPPLY = _maxSupply;
    }

    function setDefaultRoyalty(
        address _receiver,
        uint96 _feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function lock(uint256[] calldata ids) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            lockedTokens[ids[i]] = true;
            emit TokenLocked(ids[i], address(this));
        }
    }

    function unlock(uint256[] calldata ids) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            lockedTokens[ids[i]] = false;
            emit TokenUnlocked(ids[i], address(this));
        }
    }

    function refreshWholeCollectionMetadata() external onlyOwner {
        emit BatchMetadataUpdate(0, MAX_SUPPLY - 1);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        if (lockedTokens[startTokenId]) {
            revert Locked();
        }
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string memory _baseTokenURI) public {
        baseTokenURI = _baseTokenURI;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}