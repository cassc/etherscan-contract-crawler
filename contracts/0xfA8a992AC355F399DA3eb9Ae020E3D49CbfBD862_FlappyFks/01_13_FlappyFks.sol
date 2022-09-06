// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract FlappyFks is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public constant MAX_TOKENS = 7777;

    bytes32 private _merkleRoot;

    uint256 public presaleDate = 7779661;
    uint256 public saleDate = 7779661;

    uint256 public TOKEN_PRICE = 8881000000000000;
    uint256 public PRESALE_PRICE = 8881000000000000;
    uint256 public constant MAX_MINTS = 18;
    uint256 public constant MAX_PRESALE_MINTS = 1;

    uint256 public constant MAX_RESERVED = 33;
    uint256 private reservedTokens;

    mapping(address => uint256) public mintedTokensByAddress;

    string private baseURI = "https://flappyfks.mypinata.cloud/ipfs/QmcecRpUB32W8cK7jD6TyYqyz6HNZfTY9BrEzjifvzcfez/";
    string private baseExtension = ".json";

    constructor() ERC721("Flappy Fks", "FKS") {}

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Only EOA");
        _;
    }

    // For marketing and stuff...
    function mintReserved(uint256 numberOfTokens) external onlyOwner {
        require(totalSupply() + 1 <= MAX_TOKENS, "Exceeds max supply");
        _mintToken(msg.sender, numberOfTokens);
    }

    function mintCollectible(uint256 numberOfTokens)
        public
        payable
        onlyEOA
    {
        require(isSaleOpen(), "Sale must be active to mint");
        require(numberOfTokens <= MAX_MINTS, "Can only mint 18 at a time");
        require(totalSupply() + 1 <= MAX_TOKENS, "Exceeds max supply");
        require(
            TOKEN_PRICE * numberOfTokens <= msg.value,
            "ETH value not correct"
        );
        _mintToken(msg.sender, numberOfTokens);
    }

    function mintWhitelist(bytes32[] calldata proof) external payable onlyEOA {
        require(isPresaleOpen(), "Presale must be active to mint");
        require(
            mintedTokensByAddress[msg.sender] + 1 <= MAX_PRESALE_MINTS,
            "Already reached minting limit"
        );
        require(totalSupply() + 1 <= MAX_TOKENS, "Exceeds max supply");
        require(verifyWhitelist(proof, _merkleRoot), "Not on the whitelist");
        require(msg.value == PRESALE_PRICE, "ETH value not correct");
        mintedTokensByAddress[msg.sender] += 1;
        _mintToken(msg.sender, 1);
    }

    function _mintToken(address to, uint256 amount) private {
        for (uint256 i = 0; i < amount; i++) {
            _tokenIds.increment();
            uint256 id = _tokenIds.current();
            _mint(to, id);
        }
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        _merkleRoot = root;
    }

    function verifyWhitelist(bytes32[] memory _proof, bytes32 _roothash)
        private
        view
        returns (bool)
    {
        bytes32 _leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_proof, _roothash, _leaf);
    }

    function setPresaleDate(uint256 newPresale) external onlyOwner {
        presaleDate = newPresale;
    }

    function setSaleDate(uint256 newSale) external onlyOwner {
        saleDate = newSale;
    }

    function isPresaleOpen() public view returns (bool) {
        if (block.timestamp >= presaleDate && block.timestamp <= saleDate) {
            return true;
        } else {
            return false;
        }
    }

    function isSaleOpen() public view returns (bool) {
        if (
            block.timestamp >= saleDate &&
            block.timestamp <= saleDate + 1 days
        ) {
            return true;
        } else {
            return false;
        }
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setBaseExtension(string calldata newBaseExtension)
        external
        onlyOwner
    {
        baseExtension = newBaseExtension;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory _tokenURI = "Token with that ID does not exist";
        if (_exists(tokenId)) {
            _tokenURI = string(
                abi.encodePacked(
                    baseURI,
                    Strings.toString(tokenId),
                    baseExtension
                )
            );
        }
        return _tokenURI;
    }

    // So we can keep USD equivalent price relatively consistent throughout the sale
    function setPrice(uint256 price) external onlyOwner {
        TOKEN_PRICE = price;
    }

    function setPresalePrice(uint256 price) external onlyOwner {
        PRESALE_PRICE = price;
    }

    function getOwnedTokens(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;
        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= MAX_TOKENS
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    function withdrawBalance() external onlyOwner {
        require(address(this).balance > 0, "Balance is 0");
        (bool s,) = payable(msg.sender).call{value: address(this).balance}("");
        require(s, "Failed to withdraw");
    }
}