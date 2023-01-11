// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface Ethnics {
    function balanceOf(address owner) external view returns (uint256);
}

contract TheAnomy is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 500;
    uint256 public maxPublicMintPerTx = 2;
    uint256 public publicSalePrice = 0 ether;
    uint256 public whitelistSalePrice = 0 ether;
    address public mainCollectionAddress = 0x6c30e971c30e904bD994124e5427505be77DAe4c;

    string private baseURI = "ipfs://QmZVfmvz5x9jrig62AJj2fhcoKFey9VJkoKriVmhHiqDg1/";

    enum MintStage {
        PAUSED,
        WHITELIST,
        PUBLIC
    }

    MintStage public stage = MintStage.PAUSED;

    bytes32 private merkleRoot;

    mapping(address => uint256) public totalWhitelistMint;
    mapping(address => uint256) public totalPublicMint;

    constructor() ERC721A("The Anomy by Jada", "ANOMY") {}

    function mint(uint256 _amount) external payable {
        require(stage == MintStage.PUBLIC, "Public sale is not active");
        require(
            (totalSupply() + _amount) <= maxSupply,
            "Beyond max public supply"
        );
        require(
            (totalPublicMint[msg.sender] + _amount) <= maxPublicMintPerTx,
            "Beyond max per transaction"
        );
        require(msg.value >= (publicSalePrice * _amount), "Wrong mint price");

        totalPublicMint[msg.sender] += _amount;
        _safeMint(msg.sender, _amount);
    }

    function whitelistMint(bytes32[] memory _merkleProof, uint256 _amount)
        external
        payable
    {
        require(stage == MintStage.WHITELIST, "Whitelist sale is not active");
        require((totalSupply() + _amount) <= maxSupply, "Beyond max supply");
        require(
            (totalWhitelistMint[msg.sender] + _amount) <=
                getBalanceByAddress(msg.sender),
            "Beyond max per transaction"
        );
        require(
            msg.value >= (whitelistSalePrice * _amount),
            "Wrong mint price"
        );

        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, sender),
            "You are not whitelisted"
        );

        totalWhitelistMint[msg.sender] += _amount;
        _safeMint(msg.sender, _amount);
    }

    function reserveMint(address to, uint256 mintAmount)
        external
        onlyOwner
    {
        _safeMint(to, mintAmount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
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
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function setTokenUri(string memory uri) external onlyOwner {
        baseURI = uri;
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

    function setWhitelistSalePrice(uint256 newPrice) external onlyOwner {
        whitelistSalePrice = newPrice;
    }

    function setPublicSalePrice(uint256 newPrice) external onlyOwner {
        publicSalePrice = newPrice;
    }

    function setMaxPublicMintPerTx(uint256 amount) external onlyOwner {
        maxPublicMintPerTx = amount;
    }

    function setMainCollectionAddress(address _address) external onlyOwner {
        mainCollectionAddress = _address;
    }

    function getBalanceByAddress(address ownerAddress)
        public
        view
        returns (uint256)
    {
        Ethnics ethnics = Ethnics(mainCollectionAddress);
        return ethnics.balanceOf(ownerAddress);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Withdraw failed");
    }
}