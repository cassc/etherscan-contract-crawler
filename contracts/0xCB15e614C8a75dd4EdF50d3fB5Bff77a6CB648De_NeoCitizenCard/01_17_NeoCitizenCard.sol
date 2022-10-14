//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract NeoCitizenCard is ERC721, ERC721Enumerable, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    address private _signer;
    string private _metadataURI;

    constructor(
        address owner,
        address signer,
        string memory metadataURI
    ) ERC721("Neo Citizen Card", "NEOCITY") Ownable() {
        _transferOwnership(owner);
        _signer = signer;
        _metadataURI = metadataURI;
        _safeMint(msg.sender, 1);
    }

    function setSigner(address signer) public onlyOwner {
        _signer = signer;
    }

    function setMetadataURI(string calldata metadataURI) public onlyOwner {
        _metadataURI = metadataURI;
    }

    function mint(bytes memory signature) external {
        // validate signature
        bytes32 messageHash = keccak256(abi.encode(msg.sender));
        address signer = messageHash.toEthSignedMessageHash().recover(
            signature
        );
        require(_signer == signer, "NeoCitizenCard: invalid signer");

        // mint
        _safeMint(msg.sender, totalSupply() + 1);
    }

    function _baseURI() internal view override returns (string memory) {
        return _metadataURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert("NeoCitizenCard: unexist token");

        string memory baseURI = _baseURI();
        string memory ownerAddress = uint256(uint160(ownerOf(tokenId)))
            .toHexString(20);
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, ownerAddress, ".json"))
                : "";
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        require(
            balanceOf(to) == 0,
            "NeoCitizenCard: A wallet can't have multiple NFT"
        );

        if (from != address(0)) {
            revert("NeoCitizenCard: transfer disabled");
        }

        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == type(Ownable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}