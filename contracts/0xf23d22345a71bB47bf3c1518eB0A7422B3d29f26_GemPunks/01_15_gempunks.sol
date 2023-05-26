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

contract GemPunks is ERC721AQueryable, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    using Strings for uint256;

    uint256 public maxSupply = 4423;
    uint256 public publicPrice = 0.005 ether;

    uint256 public maxPerWallet = 10;

    bool public isPublicMint = false;
    bool public isFreeClaim = false;
    bool public isMetadataFinal;

    string public _baseURL = "";
    string public prerevealURL = "";

    address public _gemesis = 0xbe9371326F91345777b04394448c23E2BFEaa826;

    IERC721A gemesisContract = IERC721A(_gemesis);

    mapping(uint256 => bool) private _claimedGemesis;
    mapping(address => uint256) private _walletMintedCount;

    constructor() ERC721A("Gem Punks", "GEMPUNK") {}

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

        (bool os, ) = payable(owner()).call{value: balance}("");
        require(os);
    }

    function teamMint(address to, uint256 count) external onlyOwner {
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

    function gemesisClaim(uint256[] memory tokens) external {
        uint256 count = tokens.length;

        require(isFreeClaim, "Free claiming has not started");
        require(_totalMinted() + count <= maxSupply, "Exceeds max supply");

        for (uint256 i = 0; i < count; i++) {
            require(
                gemesisContract.ownerOf(tokens[i]) == msg.sender,
                "That is not your Gemesis NFT"
            );
            require(
                _claimedGemesis[tokens[i]] == false,
                "Your Gemesis has already claimed"
            );
            _claimedGemesis[tokens[i]] = true;
        }

        _walletMintedCount[msg.sender] += count;
        _safeMint(msg.sender, count);
    }

    function mint(uint256 count) external payable {
        require(count > 0, "Mint at least 1 Gem Punk");

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