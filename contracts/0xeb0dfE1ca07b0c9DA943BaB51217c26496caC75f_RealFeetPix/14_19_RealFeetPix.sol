// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./TinyERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract RealFeetPix is TinyERC721, ERC2981, Ownable, DefaultOperatorFilterer {
    uint public constant MAX_SUPPLY = 333;
    bytes32 public merkleRoot = 0x0852b5fcaffb05202059162b853cf0f15a188a65b417724f6d31858116e961e5;
    string private baseURI;

    uint public ALLOWLIST_MINT_TIME = 1674777600;
    uint public PUBLIC_MINT_TIME = 1674781200;

    mapping(address => bool) private minters;
    
    constructor() TinyERC721("realfeetpix", "REALFEET", 1) {
        _setDefaultRoyalty(0x34539510AED86068ae398304459453F907b855dc, 750);
    }
    
    modifier validateMint() {
        require(tx.origin == msg.sender, "Contract calls not allowed");
        require(totalSupply() + 1 <= MAX_SUPPLY, "Maximum number of tokens have been minted");
        require(!minters[msg.sender], "Maximum 1 mint per wallet");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(TinyERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Mint Methods

    function allowlistMint(bytes32[] calldata proof) external payable validateMint {
        require(ALLOWLIST_MINT_TIME == 0 || ALLOWLIST_MINT_TIME <= block.timestamp, "Allowlist mint has not started yet");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid merkle proof");
        minters[msg.sender] = true;
        _mint(msg.sender, 1);
    }

    function mint() external payable validateMint {
        require(PUBLIC_MINT_TIME == 0 || PUBLIC_MINT_TIME <= block.timestamp, "Public mint has not started yet");
        minters[msg.sender] = true;
        _mint(msg.sender, 1);
    }

    // Owner Methods

    function setAllowlistMintTime(uint timestamp) external onlyOwner {
        ALLOWLIST_MINT_TIME = timestamp;
    }

    function setPublicMintTime(uint timestamp) external onlyOwner {
        PUBLIC_MINT_TIME = timestamp;
    }

    function setRoyalty(address receiver, uint96 value) external onlyOwner {
        _setDefaultRoyalty(receiver, value);
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function withdraw(address receiver) external onlyOwner {
        (bool success, ) = receiver.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    // Opensea Operator Filterer

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}