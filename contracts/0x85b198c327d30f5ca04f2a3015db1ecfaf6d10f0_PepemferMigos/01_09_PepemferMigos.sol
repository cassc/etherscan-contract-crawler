// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "erc721a/ERC721A.sol";
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/utils/Strings.sol";
import "openzeppelin/utils/Context.sol";
import "openzeppelin/utils/Address.sol";
import "openzeppelin/security/ReentrancyGuard.sol";

contract PepemferMigos is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public maxSupply = 4200;
    uint256 public publicPrice = 0.003 ether;

    uint256 public maxPerWallet = 10;

    uint256 public maxFree = 2;

    bool public isPublicMint = false;
    bool public isMetadataFinal;

    string public _baseURL = "ipfs://bafybeib6wxzp7eqvonfjrvksrawyeejd3exkj5uugosi655457nhh3yk5y/json/";
    string public prerevealURL = "";

    mapping(address => uint256) private _walletMintedCount;

    constructor() ERC721A("Pepemfer Nakamigos", "PEPEMFERMIGOS") {}

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

    function devMint(address to, uint256 count) external onlyOwner {
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
                    abi.encodePacked(_baseURI(), tokenId.toString(), "")
                )
                : prerevealURL;
    }

    /*
        "SET VARIABLE" FUNCTIONS
    */

    function setPublicPrice(uint256 _price) external onlyOwner {
        publicPrice = _price;
    }

    function togglePublicState() external onlyOwner {
        isPublicMint = !isPublicMint;
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
    }

    function setFree(uint256 newFree) external onlyOwner {
        maxFree = newFree;
    }

    /*
        MINT FUNCTIONS
    */

    function mint(uint256 count) external payable {
        uint256 minted = _walletMintedCount[msg.sender];
        require(count > 0, "Mint at least 1");
        require(minted < maxPerWallet, "Too many mints for wallet");

        uint256 payForCount = count;
        if (minted < maxFree) {
            if (maxFree - minted > count) {
                payForCount = 0;
            } else {
                payForCount = count - (maxFree - minted);
            }
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