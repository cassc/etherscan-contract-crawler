// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

abstract contract DHVessel is ERC721, ERC721Burnable {
    function tokenToTokenType(uint256 tokenId)
        public
        view
        virtual
        returns (uint256);
}

contract DHHaloHeads is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    Ownable
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    mapping(uint256 => uint256) public tokenToTokenType;

    Counters.Counter private _tokenIdCounter;

    DHVessel _dhVessels = DHVessel(0x5DdB2Ca013EbE1C0f2f9aB8ad3D3d4BccdB66b35);

    string baseURI;

    string _contractUri;

    bool metadataLocked = false;

    bool mintIsActive = false;

    event Evolve(uint256 dhVesselsTokenId, uint256 newTokenId, address owner);

    constructor() ERC721("HaloHeads", "HaloHead") {
        _contractUri = "ipfs://QmXWqNK2VMAMKirgJkULacPJZtAekGzBVaBKyU6STaeHnT";
    }

    function safeMint(address to) internal returns (uint256) {
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(to, newTokenId);
        _tokenIdCounter.increment();
        return newTokenId;
    }

    function toggleSale() external onlyOwner {
        mintIsActive = !mintIsActive;
    }
    
    function evolve(uint256 dhVesselTokenId) external {
        require(mintIsActive, "mint is not active");

        _evolve(dhVesselTokenId);
    }

    function _evolve(uint256 dhVesselTokenId) internal {
        require(
            _dhVessels.ownerOf(dhVesselTokenId) == msg.sender,
            "sender does not own the token"
        );

        _dhVessels.burn(dhVesselTokenId);

        uint256 newTokenId = safeMint(msg.sender);

        tokenToTokenType[newTokenId] = _dhVessels.tokenToTokenType(
            dhVesselTokenId
        );

        emit Evolve(dhVesselTokenId, newTokenId, msg.sender);
    }

    function batchEvolve(uint256[] calldata dhVesselTokenIds) external {
        require(mintIsActive, "mint is not active");

        for (uint256 i = 0; i < dhVesselTokenIds.length; i++) {
            _evolve(dhVesselTokenIds[i]);
        }
    }

    function lockMetadata() external onlyOwner {
        metadataLocked = true;
    }

    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        require(!metadataLocked, "metadata is frozen");

        baseURI = baseURI_;
    }

    function setContractURI(string memory newContractURI) external onlyOwner {
        _contractUri = newContractURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "query for non existent token");

        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}