// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/[email protected]/utils/cryptography/MerkleProof.sol";
import "https://github.com/ProjectOpenSea/operator-filter-registry/blob/main/src/DefaultOperatorFilterer.sol";

contract LaLLamaPIC is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 10100;
    uint256 public constant MAX_WHITELIST_MINTS_WALLET = 2;
    uint256 public constant MAX_PUBLIC_MINTS_WALLET = 1;
    uint256 public PRICE_WHITELIST = 0.00 ether;
    uint256 public PRICE_PUBLIC = 0.00 ether;

    string private baseURI;
    string public notRevealedURI;
    bool public paused = false;
    bool public revealed = false;

    enum Stages {
        PreWhitelist,
        Whitelist,
        Public,
        SoldOut
    }

    Stages public llamaStages;

    mapping(address => uint256) public PublicMintClaimed;
    mapping(address => uint256) public WhitelistMintClaimed;

    bytes32 private merkleRoot;

    constructor(string memory _notRevealedURI) ERC721A("LaLLamaPIC", "LLAMA") {
        notRevealedURI = _notRevealedURI;
        llamaStages = Stages.PreWhitelist;
        _safeMint(msg.sender, 1);
    }

    function setWhitelistMint() external onlyOwner {
        llamaStages = Stages.Whitelist;
    }

    function setPublicMint() external onlyOwner {
        llamaStages = Stages.Public;
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

    function WhitelistMint(uint256 amount, bytes32[] calldata _proof)
        external
        payable
        nonReentrant
    {
        require(llamaStages == Stages.Whitelist, "Whitelist not started yet.");
        require(
            WhitelistMintClaimed[msg.sender] + amount <=
                MAX_WHITELIST_MINTS_WALLET,
            "You can't mint more with wallet"
        );
        require(isWhiteListed(msg.sender, _proof), "Address not whitelisted");
        require(totalSupply() + amount <= MAX_SUPPLY, "Max supply exceeded");

        require(msg.value == PRICE_WHITELIST, "Insufficient funds!");
        if (totalSupply() + amount == MAX_SUPPLY) {
            llamaStages = Stages.SoldOut;
        }
        WhitelistMintClaimed[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function PublicMint(uint256 amount) external payable nonReentrant {
        require(
            llamaStages == Stages.Public,
            "Public has not started yet."
        );
        require(msg.value >= PRICE_PUBLIC * amount, "Not enough funds.");

        require(
            PublicMintClaimed[msg.sender] + amount <= MAX_PUBLIC_MINTS_WALLET,
            "Can't mint more NFTs with this wallet."
        );
        require(totalSupply() + amount <= MAX_SUPPLY, "Max supply exceeded");
        PublicMintClaimed[msg.sender] += amount;

        if (totalSupply() + amount == MAX_SUPPLY) {
            llamaStages = Stages.SoldOut;
        }
        _safeMint(msg.sender, amount);
    }

    function AirdropTo(address[] memory to, uint256[] memory amounts)
        external
        onlyOwner
    {
        require(to.length == amounts.length, "Require same array length");
        for (uint256 i = 0; i < amounts.length; i++) {
            require(
                totalSupply() + amounts[i] <= MAX_SUPPLY,
                "Reached max supply"
            );
            _safeMint(to[i], amounts[i]);
        }
    }

    function InternalMint(uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "Reached max supply");
        _safeMint(msg.sender, amount);
    }

    function UpdateMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    function isWhiteListed(address account, bytes32[] calldata proof)
        public
        view
        returns (bool)
    {
        return _verify(_leaf(account), proof);
    }

    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseUri(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (!revealed) {
            return notRevealedURI;
        }
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}