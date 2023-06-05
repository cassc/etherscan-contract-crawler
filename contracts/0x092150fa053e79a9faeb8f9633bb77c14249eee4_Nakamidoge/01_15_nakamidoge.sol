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

contract Nakamidoge is ERC721AQueryable, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    using Strings for uint256;

    uint256 public maxSupply = 10000;
    uint256 public publicPrice = 0.004 ether;

    uint256 public maxPerWallet = 10;

    bool public isPublicMint = false;
    bool public isFreeClaim = false;
    bool public isMetadataFinal;

    string public _baseURL = "";
    string public prerevealURL = "";

    address public _nakamigas = 0x65800bAeA6D0B06C031c384598AA782bF9e5209a;
    address public _nakamigos = 0xd774557b647330C91Bf44cfEAB205095f7E6c367;

    IERC721A nakamigasContract = IERC721A(_nakamigas);
    IERC721A nakamigosContract = IERC721A(_nakamigos);

    mapping(uint256 => bool) private _claimedNakamigas;
    mapping(uint256 => bool) private _claimedNakamigos;
    mapping(address => uint256) private _walletMintedCount;

    constructor() ERC721A("Nakamidoge", "NDOGE") {}

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
        uint256 balance = address(this).balance;
        uint256 amount1 = (balance * 85) / 100;
        uint256 amount2 = (balance * 15) / 100;
        address address2 = 0xAF8EF4F240596733F6Dc3BC37FA7E65348Ec95D9;

        // Pay Address 1 (owner)
        (bool os, ) = payable(owner()).call{value: amount1}("");
        require(os);

        // Pay Address 2
        (bool aa, ) = payable(address2).call{value: amount2}("");
        require(aa);
    }


    function communityMint(address to, uint256 count) external onlyOwner {
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

    function toggleFreeClaim() external onlyOwner {
        isFreeClaim = !isFreeClaim;
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
    }

    function setMaxPerWallet(uint256 newMax) external onlyOwner {
        maxPerWallet = newMax;
    }

    /*
        MINT FUNCTIONS
    */

    function freeClaimForNakamigo(uint256[] memory tokens) external {
        uint256 count = tokens.length;

        require(isFreeClaim, "Free claiming has not started");
        require(_totalMinted() + count <= maxSupply, "Exceeds max supply");

        for (uint256 i = 0; i < count; i++) {
            require(
                nakamigosContract.ownerOf(tokens[i]) == msg.sender,
                "That is not your Nakamigo ser"
            );
            require(
                _claimedNakamigos[tokens[i]] == false,
                "Your Nakamigo has already claimed ser"
            );
            _claimedNakamigos[tokens[i]] = true;
        }

        _walletMintedCount[msg.sender] += count;
        _safeMint(msg.sender, count);
    }

    function freeClaimForNakamiga(uint256[] memory tokens) external {
        uint256 count = tokens.length;

        require(isFreeClaim, "Free claiming has not started");
        require(_totalMinted() + count <= maxSupply, "Exceeds max supply");

        for (uint256 i = 0; i < count; i++) {
            require(
                nakamigasContract.ownerOf(tokens[i]) == msg.sender,
                "That is not your Nakamiga ser"
            );
            require(
                _claimedNakamigas[tokens[i]] == false,
                "Your Nakamiga has already claimed ser"
            );
            _claimedNakamigas[tokens[i]] = true;
        }

        _walletMintedCount[msg.sender] += count;
        _safeMint(msg.sender, count);
    }

    function mint(uint256 count) external payable {
        require(count > 0, "Mint at least 1 Nakamidoge");

        require(isPublicMint, "Public mint has not started");
        require(_totalMinted() + count <= maxSupply, "Exceeds max supply");
        require(_walletMintedCount[msg.sender] + count <= maxPerWallet, "Exceeds max per wallet");

        require(
            msg.value >= count * publicPrice,
            "Ether value sent is not sufficient"
        );

        _walletMintedCount[msg.sender] += count;
        _safeMint(msg.sender, count);
    }

    /*
			OPENSEA OPERATOR OVERRIDES (ROYALTIES)
	*/

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}