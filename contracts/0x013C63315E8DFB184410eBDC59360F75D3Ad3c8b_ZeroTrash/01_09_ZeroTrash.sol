// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ZeroTrash is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public maxSupply = 3333;
    uint256 public publicPrice = 0.003 ether;

    bool public isPublicMint = false;
    bool public isMetadataFinal;

    string public _baseURL = "https://ipfs.io/ipfs/QmPcK1Zhr6h5K5fX5k5X8TPqLMa1pspyteKpnM4KosP5gL/";
    string public prerevealURL = "";

    mapping(address => uint256) private _walletMintedCount;

    constructor() ERC721A("ZeroTrash", "TRASH") {
    }

    function mintedCount(address owner) external view returns (uint256) {
        return _walletMintedCount[owner];
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURL;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function contractURI() public pure returns (string memory) {
        return "";
    }

    function finalizeMetadata() external onlyOwner {
        isMetadataFinal = true;
    }

    function reveal(string memory url) external onlyOwner {
        require(!isMetadataFinal, "Metadata is finalized");
        _baseURL = url;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function devMintTrash(address to, uint256 count) external onlyOwner {
        require(_totalMinted() + count <= maxSupply, "Exceeds max supply");
        _safeMint(to, count);
    }

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

        return
            bytes(_baseURI()).length > 0
                ? string(
                    abi.encodePacked(_baseURI(), tokenId.toString(), ".json")
                )
                : prerevealURL;
    }

    /*
			"SET VARIABLE" FUNCTIONS
	  */

    function setPublicPrice(uint256 _price) external onlyOwner {
        publicPrice = _price;
    }

    function setPublicState(bool value) external onlyOwner {
        isPublicMint = value;
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
    }

    /*
			MINT FUNCTIONS
	  */

    function mintTrash(uint256 count) external payable {
        require(count > 0, "Mint at least 1 bruh");

        // 1 Free Mint
        uint256 payForCount = count;
        if (_walletMintedCount[msg.sender] == 0) {
            payForCount--;
        }

        require(isPublicMint, "Public mint has not started");
        require(_totalMinted() + count <= maxSupply, "Exceeds max supply");
        require(
            msg.value >= payForCount * publicPrice,
            "Ether value sent is not sufficient"
        );

        _walletMintedCount[msg.sender] += count;
        _safeMint(msg.sender, count);
    }
}