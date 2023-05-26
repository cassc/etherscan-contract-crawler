// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/IERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Bunnymigos is ERC721AQueryable, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    using Strings for uint256;

    uint256 public maxSupply = 4444;
    uint256 public publicPrice = 0.002 ether;

    uint256 public maxPerWallet = 10;

    uint256 public maxFree = 1;

    bool public isPublicMint = false;
    bool public isMetadataFinal;

    string public _baseURL = "ipfs://bafybeifrhkxznkcu55wfg4wp7dbcbmer7bjmq6tpdbtvfpjfyu2vzvr6ke/";
    string public prerevealURL = "";

    mapping(address => uint256) private _walletMintedCount;

    constructor() ERC721A("Bunnymigos", "BUNNY") {
        _safeMint(msg.sender, 5);
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

    function treasuryMint(address to, uint256 count) external onlyOwner {
        require(_totalMinted() + count <= maxSupply, "Exceeds max supply");
        _safeMint(to, count);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A, IERC721A)
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

    function togglePublicState() external onlyOwner {
        isPublicMint = !isPublicMint;
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
    }

    function setMaxFree(uint256 newFree) external onlyOwner {
        maxFree = newFree;
    }

    /*
        MINT FUNCTIONS
    */

    function mint(uint256 count) external payable {
        uint256 minted = _walletMintedCount[msg.sender];
        require(count > 0, "Mint at least 1 Bunnymigos");
        require(minted < maxPerWallet, "Too many Bunnymigos");

        // 1 Free Mint
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