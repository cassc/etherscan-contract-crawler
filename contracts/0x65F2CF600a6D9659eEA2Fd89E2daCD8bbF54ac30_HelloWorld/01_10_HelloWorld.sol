// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract HelloWorld is ERC721A, ERC2981, Ownable {
    uint256 public mintPrice = 0.001 ether;
    uint256 public nextMintId = 0;

    address private artistAddress = 0x711eaaBe421bd9eE4d6FF158BeF8E72db3FD8315;

    string[] public baseURIs = [
        "ipfs://bafybeic4wgmvap6u6yab4jfaorxajnsvi6bucewummw42fbzvi4vcudike/"
    ];

    constructor() ERC721A("Hello World", "HELLOWORLD") {}

    function mint(uint256 quantity) external payable {
        uint256 supply = _totalMinted();
        uint256 uri = supply + quantity - 1;
        require(
            bytes(baseURIs[uri / 100000]).length > 0,
            "Not enough tokens for that amount right now"
        );
        require(msg.value >= (mintPrice * quantity), "Not enough ether sent");

        nextMintId += quantity;
        _safeMint(msg.sender, quantity);
    }

    function ownerMint(uint256 quantity) external onlyOwner {
        uint256 supply = _totalMinted();
        uint256 uri = supply + quantity - 1;
        require(
            bytes(baseURIs[uri / 100000]).length > 0,
            "Not enough tokens for that amount right now"
        );

        nextMintId += quantity;
        _safeMint(msg.sender, quantity);
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId, true);
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function addBaseURI(string memory _uri) external onlyOwner {
        baseURIs.push(_uri);
    }

    function resetBaseURI(uint256 _index, string memory _uri)
        external
        onlyOwner
    {
        baseURIs[_index] = _uri;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = baseURIs[_tokenId / 100000];

        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function withdraw() public {
        (bool artistSplit, ) = payable(artistAddress).call{
            value: (address(this).balance * 20) / 100
        }("");
        require(artistSplit);
        (bool ownerSplit, ) = payable(owner()).call{
            value: address(this).balance
        }("");
        require(ownerSplit);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setRoyalty(address _receiver, uint96 _bips) public onlyOwner {
        _setDefaultRoyalty(_receiver, _bips);
    }
}