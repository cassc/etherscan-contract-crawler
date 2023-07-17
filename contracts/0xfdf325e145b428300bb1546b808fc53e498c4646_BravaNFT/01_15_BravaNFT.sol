// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract BravaNFT is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    // reserved for giveaways
    uint256 public constant reserveMintSupply = 100;
    // eternal mintable supply
    uint256 public constant maxSupply = 2000;
    // currently mintable supply
    uint256 public currentMaxSupply = 300;

    // base URI for ERC721
    string public baseURI = "";
    // token reveal status
    bool public tokensRevealed;
    // current number of tokens
    uint256 public numTokens = 0;
    // remaining in the reserve
    uint256 public remainingReserve;

    /* Mint Settings */
    // price for a public minting
    uint256 public price = 0.07 ether;
    // is minting available
    bool public mintAvailable;
    // minted whitelist address
    mapping(address => bool) whitelistMinted;
    // merkle root for whitelist verify
    bytes32 public merkleRoot;

    // Opensea proxy address
    address public proxyRegistryAddress;

    // treasury address
    address public treasury = 0x812841063AD65fD02d0C5021741B3d6BD9501B33;

    constructor(string memory _URI, address _proxyRegistryAddress)
        ERC721("BravaNFT", "BRV")
    {
        mintAvailable = false;
        remainingReserve = reserveMintSupply;
        tokensRevealed = false;

        baseURI = _URI;
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    receive() external payable {}

    /* Modifiers */
    modifier mintIsAvailable() {
        require(mintAvailable == true, "Minting not started yet");
        _;
    }

    /* Whitelist functions */

    modifier onlyWhitelisted(address minter, bytes32[] calldata proof) {
        require(isWhitelisted(minter, proof), "Not whitelisted");
        _;
    }

    function isWhitelisted(address minter, bytes32[] memory proof)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encode(minter));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /* ERC721 functions */
    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
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

        if (bytes(baseURI).length == 0) {
            return "";
        }

        string memory part = tokensRevealed ? tokenId.toString() : "cover";
        return string(abi.encodePacked(baseURI, part, ".json"));
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /*  Minting functions */
    function preMint(bytes32[] calldata proof)
        external
        nonReentrant
        onlyWhitelisted(msg.sender, proof)
    {
        require(!whitelistMinted[msg.sender], "Whitelist already minted.");
        whitelistMinted[msg.sender] = true;
        _mint(1, msg.sender);
    }

    function mint(uint256 count) external payable nonReentrant mintIsAvailable {
        uint256 supply = uint256(totalSupply());
        require(
            supply + count <= currentMaxSupply - remainingReserve,
            "Not enough token."
        );
        require(count < 6, "You cannot mint more than 5 at once!");
        require(count * price == msg.value, "msg.value is wrong!");
        _mint(count, msg.sender);
    }

    function _mint(uint256 count, address recipient) internal {
        for (uint256 i; i < count; i++) {
            numTokens = numTokens + 1;
            uint256 tokenId = numTokens;
            _safeMint(recipient, tokenId);
        }
    }

    function setCurrentMaxSupply(uint256 _currentMaxSupply) external onlyOwner {
        require(
            _currentMaxSupply <= maxSupply,
            "CurrentMaxSupply cannot be greater than eternal maxSupply"
        );
        currentMaxSupply = _currentMaxSupply;
    }

    function toggleMinting() external onlyOwner {
        mintAvailable = !mintAvailable;
    }

    function ownerMint(uint256 count, address recipient) external onlyOwner {
        require(
            count <= remainingReserve,
            "Not enough token to owner mint in reserve"
        );
        require(count < 51, "Minting is limited to 50 at once");
        _mint(count, recipient);
        remainingReserve -= count;
    }

    function revealTokens() external onlyOwner {
        tokensRevealed = true;
    }

    /* Owner functions */
    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;
        require(payable(treasury).send(_balance));
    }

    /* Misc Functions */
    function getTokensOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
}