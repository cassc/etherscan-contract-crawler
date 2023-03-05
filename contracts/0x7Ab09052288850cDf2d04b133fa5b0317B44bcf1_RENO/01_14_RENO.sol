// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RENO is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    bytes32 public merkleRootWhitelist;

    uint256 public constant maxSupply = 4115;
    uint256 public constant publicMintSupply = 4000;
    uint256 public constant freeMintSupply = 115;
    uint256 public freeMintedAlready;

    uint256 public whitelistPrice = 0.32 ether;
    uint256 public publicPrice = 0.385 ether;

    bool public publicOpen;
    bool public whitelistOpen;
    bool public freemintOpen;

    string private baseUri = "";
    string private baseExtension = ".json";

    mapping(address => uint256) public freeMintList;

    constructor() ERC721("Real Estate NFT Official", "RENO") {}

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Only EOA");
        _;
    }

    function mintSale(uint256 amount) external payable onlyEOA {
        require(publicOpen, "Sale not open");
        require(amount > 0, "Incorrect amount");
        require(
            totalSupply() + amount <= mintableSupply(),
            "Max Supply reached"
        );
        require(msg.value >= publicPrice * amount, "Incorrect Price sent");
        _mintToken(msg.sender, amount);
    }

    function mintWhitelist(bytes32[] calldata proof, uint256 amount)
        external
        payable
        onlyEOA
    {
        require(whitelistOpen, "whitelist mint not open");
        require(verifyWhitelist(proof, merkleRootWhitelist), "Not whitelisted");
        require(
            totalSupply() + amount <= mintableSupply(),
            "Max Supply reached"
        );
        require(msg.value >= whitelistPrice * amount, "Incorrect Price sent");
        _mintToken(msg.sender, amount);
    }

    function _mintToken(address to, uint256 amount) private {
        uint256 id;
        for (uint256 i = 0; i < amount; i++) {
            _tokenIds.increment();
            id = _tokenIds.current();
            _mint(to, id);
        }
    }

    function mintFree(uint256 amount) external onlyEOA {
        require(freemintOpen, "free mint not open");
        require(
            amount > 0 && freeMintList[msg.sender] >= amount,
            "no free mints"
        );
        require(freeMintedAlready + amount <= freeMintSupply, "max freemint");
        require(totalSupply() + amount <= maxSupply, "Max Supply reached");

        freeMintedAlready += amount;
        freeMintList[msg.sender] -= amount;
        _mintToken(msg.sender, amount);
    }

    function mintableSupply() public view returns (uint256) {
        return maxSupply - (freeMintSupply - freeMintedAlready);
    }

    function setBaseExtension(string memory newBaseExtension)
        external
        onlyOwner
    {
        baseExtension = newBaseExtension;
    }

    function setBaseUri(string memory newBaseUri) external onlyOwner {
        baseUri = newBaseUri;
    }

    function setFreeMintList(
        address[] memory addresses,
        uint256[] memory amounts
    ) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            freeMintList[addresses[i]] = amounts[i];
        }
    }

    function setWhitelistMerkleRoot(bytes32 newRoot) external onlyOwner {
        merkleRootWhitelist = newRoot;
    }

    function setPublicPrice(uint256 newPrice) external onlyOwner {
        publicPrice = newPrice;
    }

    function setWhitelistPrice(uint256 newPrice) external onlyOwner {
        whitelistPrice = newPrice;
    }

    function togglePublicSaleOpen() external onlyOwner {
        publicOpen = !publicOpen;
    }

    function toggleWhitelistSaleOpen() external onlyOwner {
        whitelistOpen = !whitelistOpen;
    }

    function toggleFreeMintOpen() external onlyOwner {
        freemintOpen = !freemintOpen;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory _tokenURI = "Token with that ID does not exist.";
        if (_exists(tokenId)) {
            _tokenURI = string(
                abi.encodePacked(baseUri, tokenId.toString(), baseExtension)
            );
        }
        return _tokenURI;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function verifyWhitelist(bytes32[] memory _proof, bytes32 _roothash)
        private
        view
        returns (bool)
    {
        bytes32 _leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_proof, _roothash, _leaf);
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;
        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
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
        (bool s, ) = payable(owner()).call{value: address(this).balance}("");
        require(s, "tx failed");
    }
}