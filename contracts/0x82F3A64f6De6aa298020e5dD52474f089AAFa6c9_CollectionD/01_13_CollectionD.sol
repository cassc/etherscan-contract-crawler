// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./libs/ERC721A.sol";

contract CollectionD is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;

    bool initialized;

    mapping(uint256 => bool) public claimed;

    address collectionAddr;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 collectionSize_
    ) ERC721A(name_, symbol_, 100, collectionSize_) {}

    function initialize(address collectionC, string calldata baseTokenURI)
        external
        onlyOwner
    {
        require(!initialized, "only initialized once");
        initialized = true;
        collectionAddr = collectionC;
        _baseTokenURI = baseTokenURI;
    }

    function mint(uint[] calldata ids) external payable {
        mintFor(msg.sender, ids);
    }

    function mintFor(address account, uint[] calldata ids) public payable nonReentrant{
        uint amount = ids.length;
        require(
            totalSupply() + ids.length <= collectionSize,
            "Reached max supply"
        );

        for (uint i = 0; i < amount; ) {
            require(IERC721(collectionAddr).ownerOf(ids[i]) == account, "only claim your holding collectionC");
            require(!claimed[ids[i]], "id already claimed");
            claimed[ids[i]] = true;
            unchecked {++i;}
        }

		_safeMint(account, amount);
    }

    function withdraw() external {
        bool sent;
        bytes memory data;
        uint256 balance = address(this).balance;
        (sent, data) = owner().call{value: balance}("");
        require(sent, "Failed to send Ether");
    }

    // // metadata URI
    string private _baseTokenURI;
    string private _unrevealedURI;
    bool public isRevealed;

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseTokenURI;

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setOwnersExplicit(uint256 quantity)
        external
        onlyOwner
        nonReentrant
    {
        _setOwnersExplicit(quantity);
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

    fallback() external payable {}

    receive() external payable {}
}