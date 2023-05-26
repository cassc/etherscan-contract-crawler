// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract FreeJoJo is ERC721AQueryable, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    using Strings for uint256;

    bytes32 public merkleRoot;
    mapping(address => bool) public mintClaimed;

    string public uriPrefix = "";
    string public uriSuffix = "";

    uint256 public maxSupply = 10000;
    uint256 public mintableSupply = 7777;

    bool public whitelistEnabled = false;
    bool public publicEnabled = false;

    constructor() ERC721A("Free JoJo", "JOJO") {}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
                : "";
    }

    function airdrop(uint256 _mintAmount, address _receiver) external onlyOwner {
        require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
        _safeMint(_receiver, _mintAmount);
    }

    function withdraw() external onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    /*
			"SET VARIABLE" FUNCTIONS
	*/

    // Metadata Prefix/Suffix
    function setUriPrefix(string memory _uriPrefix) external onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) external onlyOwner {
        uriSuffix = _uriSuffix;
    }

    // Merkle Root
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    // Whitelist/Public State
    function setWhitelistEnabled(bool _state) external onlyOwner {
        whitelistEnabled = _state;
    }

    function setPublicEnabled(bool _state) external onlyOwner {
        publicEnabled = _state;
    }

    // Total Supply
    function setMaxTotalSupply(uint256 _amount) external onlyOwner {
        maxSupply = _amount;
    }

    // Mintable Supply
    function setMaxMintableSupply(uint256 _amount) external onlyOwner {
        mintableSupply = _amount;
    }

    /*
			MINT FUNCTIONS
	*/

    // WHITELIST CLAIM (AMOUNT)
    function claimJoJos(uint256 _mintAmount, bytes32[] calldata _merkleProof) external payable {
        require(whitelistEnabled, "Whitelist claiming is not enabled!");
        require(totalSupply() + _mintAmount <= mintableSupply, "Max mintable supply exceeded!");

        require(!mintClaimed[_msgSender()], "Address already claimed!");

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender(), _mintAmount));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");

        mintClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), _mintAmount);
    }

    // PUBLIC MINT
    function mintJoJos() external payable {
        require(totalSupply() + 1 <= mintableSupply, "Max mintable supply exceeded!");

        require(publicEnabled, "Public claiming is not enabled!");
        require(!mintClaimed[_msgSender()], "Address already claimed!");

        mintClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), 1);
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