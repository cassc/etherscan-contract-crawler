// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Puckers is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public MAX_SUPPLY = 4444;
    uint256 public MAX_PUBLIC_SUPPLY = 3444;
    uint256 public MAX_PUBLIC_MINT = 3;
    uint256 public MAX_WHITELIST_MINT = 1;
    uint256 public PUBLIC_SALE_PRICE = .005 ether;
    uint256 public WHITELIST_SALE_PRICE = 0 ether;

    string private baseTokenUri;

    enum MintStage {
        PAUSED,
        PUBLIC,
        WHITELIST
    }

    MintStage public stage = MintStage.PAUSED;

    bytes32 private merkleRoot;

    mapping(address => uint256) public totalPublicMint;
    mapping(address => uint256) public totalWhitelistMint;

    constructor(string memory baseTokenUri_) ERC721A("Puckers", "PCKR") {
        baseTokenUri = baseTokenUri_;
    }

    function mint(uint256 amount) external payable {
        require(stage == MintStage.PUBLIC, "Public sale is not active yet.");
        require(
            (totalSupply() + amount) <= MAX_PUBLIC_SUPPLY,
            "Beyond max public supply."
        );
        require(
            (totalPublicMint[msg.sender] + amount) <= MAX_PUBLIC_MINT,
            "You can not mint more than max public mint."
        );
        require(msg.value >= (PUBLIC_SALE_PRICE * amount), "Wrong mint price.");

        totalPublicMint[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function whitelistMint(bytes32[] memory _merkleProof, uint256 amount)
        external
        payable
    {
        require(
            stage == MintStage.WHITELIST,
            "Whitelist sale is not active yet."
        );
        require((totalSupply() + amount) <= MAX_SUPPLY, "Beyond max supply.");
        require(
            (totalWhitelistMint[msg.sender] + amount) <= MAX_WHITELIST_MINT,
            "You can not mint more than max whitelist mint."
        );
        require(
            msg.value >= (WHITELIST_SALE_PRICE * amount),
            "Wrong mint price."
        );

        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, sender),
            "You are not whitelisted."
        );

        totalWhitelistMint[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function ownerMint(address receiver, uint256 mintAmount)
        external
        onlyOwner
    {
        _safeMint(receiver, mintAmount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
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
        return
            string(abi.encodePacked(baseTokenUri, tokenId.toString(), ".json"));
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function getMerkleRoot() external view returns (bytes32) {
        return merkleRoot;
    }

    function setMintStage(MintStage _stage) public onlyOwner {
        stage = _stage;
    }

    function setPublicSupply(uint256 newSupply) external onlyOwner {
        MAX_PUBLIC_SUPPLY = newSupply;
    }

    function setPublicPrice(uint256 newPrice) external onlyOwner {
        PUBLIC_SALE_PRICE = newPrice;
    }

    function setMaxPublicMintPerTx(uint256 newMaxPerTx) external onlyOwner {
        MAX_PUBLIC_MINT = newMaxPerTx;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Withdraw failed");
    }
}