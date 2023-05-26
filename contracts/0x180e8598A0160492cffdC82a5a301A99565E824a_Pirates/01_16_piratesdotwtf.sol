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
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Pirates is
    ERC721AQueryable,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    using Strings for uint256;

    bytes32 public merkleRoot;
    uint256 public maxSupply = 5000;
    uint256 public publicPrice = 0.009 ether;

    uint256 public maxPerWallet = 10;
    uint256 public maxFreeClaim = 1;

    bool public isPublicMint = false;
    bool public isFreeClaim = false;
    bool public gateEnabled = true;
    bool public isMetadataFinal;

    string public _baseURL = "";
    string public prerevealURL = "";

    mapping(address => uint256) private _walletMintedCount;
    mapping(address => uint256) private _walletClaimCount;

    constructor() ERC721A("Pirates", "ARRG") {}

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

    function airdrop(address to, uint256 count) external onlyOwner {
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

	function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, leaf);
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

    // Merkle Root
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function toggleFreeClaim() external onlyOwner {
        isFreeClaim = !isFreeClaim;
    }

    function toggleGate() external onlyOwner {
        gateEnabled = !gateEnabled;
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
    }

    function setMaxPerWallet(uint256 newMax) external onlyOwner {
        maxPerWallet = newMax;
    }

    function setMaxFreeClaim(uint256 newMax) external onlyOwner {
        maxFreeClaim = newMax;
    }

    /*
        MINT FUNCTIONS
    */

    function freeClaim(uint256 count, bytes32[] memory proof)
        external
    {
        require(isFreeClaim, "Free claiming has not started");
        require(_totalMinted() + count <= maxSupply, "Exceeds max supply");

        if (gateEnabled) {
            require(
                isValid(proof, keccak256(abi.encodePacked(msg.sender))),
                "Wallet not on the allowlist"
            );
        }

        require(
            _walletClaimCount[msg.sender] + count <= maxFreeClaim,
            "You can not claim this many tokens!"
        );

        _walletClaimCount[msg.sender] += count;
        _safeMint(msg.sender, count);
    }

    function mint(uint256 count) external payable {
        require(count > 0, "Mint at least one token");

        require(isPublicMint, "Public mint has not started");
        require(_totalMinted() + count <= maxSupply, "Exceeds max supply");
        require(
            _walletMintedCount[msg.sender] + count <= maxPerWallet,
            "Exceeds max per wallet"
        );

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