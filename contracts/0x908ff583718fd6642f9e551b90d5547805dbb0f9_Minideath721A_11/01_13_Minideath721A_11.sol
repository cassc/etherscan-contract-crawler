// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Minideath721A_11 is Ownable, ERC721A, ReentrancyGuard {
    uint256 public collectionSize;
    uint256 public batchSize;

    constructor(uint256 collectionSize_, uint256 batchSize_)
        ERC721A("Minideath", "DEADLY")
    {
        require(
            collectionSize_ > 0,
            "ERC721A: collection must have a nonzero supply"
        );
        require(
            batchSize_ > 0 && batchSize_ < collectionSize_ && collectionSize_ % batchSize_ == 0,
            "batch size needs to be more than 0 and less than collectionSize"
        );
        collectionSize = collectionSize_;
        batchSize = batchSize_;
    }

    function mint(uint256 batches, string calldata baseURI) external onlyOwner {
        uint256 quantity = batches * batchSize;
        require(totalSupply() + quantity <= collectionSize, "reached max supply");
        uint256 currentBatch = totalSupply() / batchSize;
        for (uint256 i = currentBatch; i < currentBatch + batches; i++) {
            _baseTokenURIs[i] = baseURI;
        }
        _safeMint(msg.sender, quantity);
    }

    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, bytes calldata _data) public {
        // MUST Throw on errors
        require(_to != address(0x0), "destination address must be non-zero.");
        require(_from == msg.sender || isApprovedForAll(_from, msg.sender), "Need operator approval for 3rd party transfers.");

        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 id = _ids[i];

            safeTransferFrom(_from, _to, id, _data);
        }
    }

    // // metadata URI
    // string private _baseTokenURI;
    // Allow to have different token uris accross batches of tokens
    mapping(uint256 => string) private _baseTokenURIs;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURIs[0];
    }

    function _baseURI(uint batch) internal view virtual returns (string memory) {
        return _baseTokenURIs[batch];
    }

    function setBaseURI(string calldata baseURI, uint256 batch) external onlyOwner {
        _baseTokenURIs[batch] = baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

        uint batch = tokenId / batchSize;
        string memory baseURI = _baseURI(batch);
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId))) : '';
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function getCollectionSize() public view returns (uint256) {
        return collectionSize;
    }
}